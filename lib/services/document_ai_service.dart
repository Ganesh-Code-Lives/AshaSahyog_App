import 'package:supabase_flutter/supabase_flutter.dart';

enum DocumentAiAction { simplify, translate, question }

class DocumentAiException implements Exception {
  const DocumentAiException(this.message);
  final String message;
}

class DocumentAiService {
  // Matches the server bound. Large documents still work with OCR and TTS.
  static const maxTextLength = 30000;

  Future<String> run({
    required DocumentAiAction action,
    required String document,
    required String language,
    String? question,
  }) async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      throw const DocumentAiException('Sign in to use document AI.');
    }
    try {
      final response = await client.functions
          .invoke(
            'document-reader',
            body: {
              'action': action.name,
              'document': document,
              'language': language,
              'question': ?question,
            },
          )
          .timeout(const Duration(seconds: 60));
      final data = response.data;
      if (data is Map && data['notFound'] == true) {
        return 'I couldn’t find an answer in this document.';
      }
      final text = data is Map ? data['text'] : null;
      if (text is String && text.trim().isNotEmpty) return text;
      throw const DocumentAiException('The AI returned an empty response.');
    } on FunctionException catch (error) {
      final message = switch (error.status) {
        401 || 403 => 'Sign in again to use document AI.',
        404 || 503 => 'Document AI is unavailable. Check the backend setup.',
        413 => 'This document contains too much text for an AI request.',
        422 => 'The AI response was incomplete. Try a shorter document.',
        429 => 'Document AI is busy. Please try again later.',
        _ => 'Document AI could not complete the request. Please try again.',
      };
      throw DocumentAiException(message);
    }
  }
}
