import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;

/// ─────────────────────────────────────────────────────────────────────────────
/// Gemini Service  –  Drop-in replacement for the old openai_service.dart
///
/// SETUP:
///   Run / build with:
///     flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
///
///   Or in launch.json / VS Code:
///     "toolArgs": ["--dart-define=GEMINI_API_KEY=YOUR_KEY_HERE"]
/// ─────────────────────────────────────────────────────────────────────────────

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  /// Pass your key via --dart-define=GEMINI_API_KEY=...
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get isAvailable => apiKey.isNotEmpty;

  factory GeminiService() => _instance;

  GeminiService._internal() {
    if (apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY not provided — AI features will be disabled.');
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// GeminiClient  –  Wraps the google_generative_ai SDK
/// ─────────────────────────────────────────────────────────────────────────────
class GeminiClient {
  final String _apiKey;

  GeminiClient() : _apiKey = GeminiService.apiKey;

  /// Build a GenerativeModel instance with the given options.
  genai.GenerativeModel _buildModel({
    String model = 'gemini-2.5-flash',
    String? systemInstruction,
    int? maxOutputTokens,
    double? temperature,
  }) {
    return genai.GenerativeModel(
      model: model,
      apiKey: _apiKey,
      systemInstruction: systemInstruction != null
          ? genai.Content.system(systemInstruction)
          : null,
      generationConfig: genai.GenerationConfig(
        maxOutputTokens: maxOutputTokens ?? 1024,
        temperature: temperature,
      ),
      safetySettings: [
        genai.SafetySetting(
          genai.HarmCategory.harassment,
          genai.HarmBlockThreshold.none,
        ),
        genai.SafetySetting(
          genai.HarmCategory.hateSpeech,
          genai.HarmBlockThreshold.none,
        ),
        genai.SafetySetting(
          genai.HarmCategory.sexuallyExplicit,
          genai.HarmBlockThreshold.none,
        ),
        genai.SafetySetting(
          genai.HarmCategory.dangerousContent,
          genai.HarmBlockThreshold.none,
        ),
      ],
    );
  }

  /// Standard (non-streaming) chat completion.
  ///
  /// [messages]   – Ordered list of role/content pairs.
  /// [model]      – Gemini model string, default `gemini-2.5-flash`.
  /// [options]    – Optional map; supports `max_output_tokens`, `temperature`.
  Future<Completion> createChatCompletion({
    required List<Message> messages,
    String model = 'gemini-2.5-flash',
    Map<String, dynamic>? options,
    // Kept for API-compat but ignored by Gemini:
    String? reasoningEffort,
    String? verbosity,
  }) async {
    try {
      // Separate system instruction from conversation messages
      String? systemInstruction;
      final conversationMessages = <Message>[];

      for (final msg in messages) {
        if (msg.role == 'system') {
          systemInstruction = (systemInstruction ?? '') + msg.content.toString();
        } else {
          conversationMessages.add(msg);
        }
      }

      final int maxTokens =
          (options?['max_output_tokens'] ?? options?['max_completion_tokens'] ?? 1024) as int;

      final generativeModel = _buildModel(
        model: model,
        systemInstruction: systemInstruction,
        maxOutputTokens: maxTokens,
        temperature: options?['temperature'] as double?,
      );

      // Convert messages → Gemini Content objects
      final contents = conversationMessages.map((m) {
        final role = m.role == 'assistant' ? 'model' : 'user';
        return genai.Content(role, [genai.TextPart(m.content.toString())]);
      }).toList();

      final response = await generativeModel.generateContent(contents);

      final text = response.text ?? '';
      return Completion(text: text);
    } catch (e) {
      debugPrint('Gemini completion error: $e');
      throw GeminiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }

  /// Streaming chat completion – yields text chunks as they arrive.
  Stream<String> streamContentOnly({
    required List<Message> messages,
    String model = 'gemini-2.5-flash',
    Map<String, dynamic>? options,
    String? reasoningEffort,
    String? verbosity,
  }) async* {
    try {
      // Separate system instruction from conversation messages
      String? systemInstruction;
      final conversationMessages = <Message>[];

      for (final msg in messages) {
        if (msg.role == 'system') {
          systemInstruction = (systemInstruction ?? '') + msg.content.toString();
        } else {
          conversationMessages.add(msg);
        }
      }

      final int maxTokens =
          (options?['max_output_tokens'] ?? options?['max_completion_tokens'] ?? 1024) as int;

      final generativeModel = _buildModel(
        model: model,
        systemInstruction: systemInstruction,
        maxOutputTokens: maxTokens,
        temperature: options?['temperature'] as double?,
      );

      // Convert messages → Gemini Content objects
      final contents = conversationMessages.map((m) {
        final role = m.role == 'assistant' ? 'model' : 'user';
        return genai.Content(role, [genai.TextPart(m.content.toString())]);
      }).toList();

      final stream = generativeModel.generateContentStream(contents);

      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } catch (e) {
      debugPrint('Gemini stream error: $e');
      throw GeminiException(
        statusCode: 500,
        message: e.toString(),
      );
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shared data classes  –  Same interface as the old openai_service.dart
/// ─────────────────────────────────────────────────────────────────────────────

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

class GeminiException implements Exception {
  final int statusCode;
  final String message;

  GeminiException({required this.statusCode, required this.message});

  @override
  String toString() => 'GeminiException: $statusCode - $message';
}