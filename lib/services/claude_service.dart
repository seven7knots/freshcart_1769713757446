import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Claude Service — proxied through Supabase Edge Function (ai-proxy).
///
/// The Anthropic API key lives server-side in the Edge Function.
/// The client authenticates with its Supabase session JWT.

class ClaudeService {
  static final ClaudeService _instance = ClaudeService._internal();

  static bool get isAvailable =>
      Supabase.instance.client.auth.currentSession != null;

  factory ClaudeService() => _instance;

  ClaudeService._internal();
}

/// ClaudeClient — calls the ai-proxy Supabase Edge Function
class ClaudeClient {
  static const String _endpoint =
      'https://uwjmeitzpxvohmqxfaxy.supabase.co/functions/v1/ai-proxy';
  static const String _defaultModel = 'claude-haiku-4-5-20251001';
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const Duration _apiTimeout = Duration(seconds: 30);

  String get _accessToken {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw ClaudeException(
        statusCode: 401,
        message: 'You must be logged in to use AI features. '
            'Please sign in and try again.',
      );
    }
    return token;
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'apikey': _anonKey,
        'content-type': 'application/json',
      };

  /// Standard (non-streaming) chat completion.
  Future<Completion> createChatCompletion({
    required List<Message> messages,
    String model = _defaultModel,
    Map<String, dynamic>? options,
    String? reasoningEffort,
    String? verbosity,
  }) async {
    try {
      // Separate system messages from conversation messages
      final separated = _separateMessages(messages);

      final int maxTokens =
          (options?['max_output_tokens'] ?? options?['max_completion_tokens'] ?? 4096) as int;

      final body = <String, dynamic>{
        'model': model,
        'max_tokens': maxTokens,
        'messages': separated.conversationMessages
            .map((m) => {'role': m.role, 'content': m.content.toString()})
            .toList(),
      };

      if (separated.systemInstruction != null) {
        body['system'] = separated.systemInstruction;
      }

      if (options?['temperature'] != null) {
        body['temperature'] = options!['temperature'];
      }

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_apiTimeout, onTimeout: () {
        throw ClaudeException(
          statusCode: 408,
          message: 'AI request timed out after ${_apiTimeout.inSeconds}s. '
              'Please try again.',
        );
      });

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? errorBody['error'] ?? response.body;
        debugPrint('[Claude] API error ${response.statusCode}: $errorMsg');
        throw ClaudeException(
          statusCode: response.statusCode,
          message: errorMsg.toString(),
        );
      }

      final data = jsonDecode(response.body);
      final contentBlocks = data['content'] as List? ?? [];
      final text = contentBlocks
          .where((b) => b['type'] == 'text')
          .map((b) => b['text'] as String)
          .join();

      if (text.isEmpty) {
        debugPrint('[Claude] Warning: response text is empty');
      }

      return Completion(text: text);
    } catch (e) {
      if (e is ClaudeException) rethrow;
      if (e is TimeoutException) {
        throw ClaudeException(
          statusCode: 408,
          message: 'AI request timed out. Please try again.',
        );
      }
      debugPrint('Claude completion error: $e');
      throw ClaudeException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  /// Streaming chat completion — yields text chunks via SSE.
  Stream<String> streamContentOnly({
    required List<Message> messages,
    String model = _defaultModel,
    Map<String, dynamic>? options,
    String? reasoningEffort,
    String? verbosity,
  }) async* {
    try {
      final separated = _separateMessages(messages);

      final int maxTokens =
          (options?['max_output_tokens'] ?? options?['max_completion_tokens'] ?? 4096) as int;

      final body = <String, dynamic>{
        'model': model,
        'max_tokens': maxTokens,
        'stream': true,
        'messages': separated.conversationMessages
            .map((m) => {'role': m.role, 'content': m.content.toString()})
            .toList(),
      };

      if (separated.systemInstruction != null) {
        body['system'] = separated.systemInstruction;
      }

      if (options?['temperature'] != null) {
        body['temperature'] = options!['temperature'];
      }

      final request = http.Request('POST', Uri.parse(_endpoint));
      request.headers.addAll(_headers);
      request.body = jsonEncode(body);

      final streamedResponse = await http.Client()
          .send(request)
          .timeout(_apiTimeout, onTimeout: () {
        throw ClaudeException(
          statusCode: 408,
          message: 'AI stream timed out after ${_apiTimeout.inSeconds}s.',
        );
      });

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        debugPrint('[Claude] Stream error ${streamedResponse.statusCode}: $errorBody');
        throw ClaudeException(
          statusCode: streamedResponse.statusCode,
          message: 'Stream request failed: ${streamedResponse.statusCode}',
        );
      }

      bool hasYieldedContent = false;
      String buffer = '';

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .timeout(_apiTimeout, onTimeout: (sink) {
        debugPrint('[Claude] Stream timed out after ${_apiTimeout.inSeconds}s');
        sink.close();
      })) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.last; // keep incomplete line in buffer

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (!line.startsWith('data: ')) continue;

          final jsonStr = line.substring(6);
          if (jsonStr == '[DONE]') continue;

          try {
            final event = jsonDecode(jsonStr);
            final eventType = event['type'] as String?;

            if (eventType == 'content_block_delta') {
              final delta = event['delta'];
              if (delta != null && delta['type'] == 'text_delta') {
                final text = delta['text'] as String? ?? '';
                if (text.isNotEmpty) {
                  hasYieldedContent = true;
                  yield text;
                }
              }
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }

      if (!hasYieldedContent) {
        debugPrint('[Claude] Stream completed with no content');
        yield 'I wasn\'t able to generate a response. Please try again.';
      }
    } catch (e) {
      if (e is ClaudeException) rethrow;
      if (e is TimeoutException) {
        yield 'The AI took too long to respond. Please try again.';
        return;
      }
      debugPrint('Claude stream error: $e');
      throw ClaudeException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  ({String? systemInstruction, List<Message> conversationMessages})
      _separateMessages(List<Message> messages) {
    String? systemInstruction;
    final conversationMessages = <Message>[];

    for (final msg in messages) {
      if (msg.role == 'system') {
        systemInstruction =
            (systemInstruction ?? '') + msg.content.toString();
      } else {
        conversationMessages.add(msg);
      }
    }

    return (
      systemInstruction: systemInstruction,
      conversationMessages: conversationMessages,
    );
  }
}

/// Shared data classes — same interface as previous service
class Message {
  final String role; // 'system' | 'user' | 'assistant'
  final dynamic content;

  Message({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class Completion {
  final String text;
  Completion({required this.text});
}

class ClaudeException implements Exception {
  final int statusCode;
  final String message;

  ClaudeException({required this.statusCode, required this.message});

  @override
  String toString() => 'ClaudeException: $statusCode - $message';
}
