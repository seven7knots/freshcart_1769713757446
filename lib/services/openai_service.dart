import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY');

  factory OpenAIService() {
    return _instance;
  }

  OpenAIService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY must be provided via --dart-define',
      );
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  Dio get dio => _dio;
}

class OpenAIClient {
  final Dio dio;

  OpenAIClient(this.dio);

  /// Standard chat completion with GPT-5 mini for fast responses
  Future<Completion> createChatCompletion({
    required List<Message> messages,
    String model = 'gpt-5-mini',
    Map<String, dynamic>? options,
    String? reasoningEffort,
    String? verbosity,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

      if (options != null) {
        final filteredOptions = Map<String, dynamic>.from(options);

        if (model.startsWith('gpt-5') ||
            model.startsWith('o3') ||
            model.startsWith('o4')) {
          filteredOptions.removeWhere((key, value) => [
                'temperature',
                'top_p',
                'presence_penalty',
                'frequency_penalty',
                'logit_bias'
              ].contains(key));

          if (filteredOptions.containsKey('max_tokens')) {
            filteredOptions['max_completion_tokens'] =
                filteredOptions.remove('max_tokens');
          }
        }

        requestData.addAll(filteredOptions);
      }

      if (model.startsWith('gpt-5') ||
          model.startsWith('o3') ||
          model.startsWith('o4')) {
        if (reasoningEffort != null) {
          requestData['reasoning_effort'] = reasoningEffort;
        }
        if (verbosity != null) requestData['verbosity'] = verbosity;
      }

      final response = await dio.post('/chat/completions', data: requestData);

      final text = response.data['choices'][0]['message']['content'];
      return Completion(text: text);
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }

  /// Stream chat completion for real-time responses
  Stream<String> streamContentOnly({
    required List<Message> messages,
    String model = 'gpt-5-mini',
    Map<String, dynamic>? options,
    String? reasoningEffort,
    String? verbosity,
  }) async* {
    try {
      final requestData = <String, dynamic>{
        'model': model,
        'messages': messages.map((m) => m.toJson()).toList(),
        'stream': true,
      };

      if (options != null) requestData.addAll(options);

      if (model.startsWith('gpt-5') ||
          model.startsWith('o3') ||
          model.startsWith('o4')) {
        if (reasoningEffort != null) {
          requestData['reasoning_effort'] = reasoningEffort;
        }
        if (verbosity != null) requestData['verbosity'] = verbosity;
      }

      final response = await dio.post(
        '/chat/completions',
        data: requestData,
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      await for (var line
          in LineSplitter().bind(utf8.decoder.bind(stream.stream))) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = json['choices'][0]['delta'] as Map<String, dynamic>;
            final content = delta['content'] ?? '';
            final finishReason = json['choices'][0]['finish_reason'];

            if (content.isNotEmpty) {
              yield content;
            }

            if (finishReason != null) break;
          } catch (e) {
            debugPrint('Error parsing stream chunk: $e');
          }
        }
      }
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data['error']['message'] ??
            e.message ??
            'Unknown error',
      );
    }
  }
}

class Message {
  final String role;
  final dynamic content;

  Message({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class Completion {
  final String text;

  Completion({required this.text});
}

class OpenAIException implements Exception {
  final int statusCode;
  final String message;

  OpenAIException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIException: $statusCode - $message';
}
