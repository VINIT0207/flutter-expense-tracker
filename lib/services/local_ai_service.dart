import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';
import 'package:onenm_local_llm/onenm_local_llm_platform_interface.dart';

class LocalAiService {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the GGUF model using llama.cpp via onenm_local_llm
  Future<bool> initialize(String absoluteModelPath) async {
    try {
      debugPrint("Initializing llama.cpp backend...");
      await OnenmLocalLlmPlatform.instance.initBackend();

      debugPrint("Loading fine-tuned GGUF model from: $absoluteModelPath");
      final loaded =
          await OnenmLocalLlmPlatform.instance.loadModel(absoluteModelPath);
      _isInitialized = loaded ?? false;

      if (_isInitialized) {
        debugPrint("✅ Fine-tuned SLM loaded successfully via llama.cpp");
      } else {
        debugPrint("❌ Failed to load SLM model at $absoluteModelPath");
      }
      return _isInitialized;
    } catch (e) {
      debugPrint("Failed to initialize local AI: $e");
      _isInitialized = false;
      return false;
    }
  }

  /// Generative Chat - Optimized for 512-token n_ctx hard limit of onenm_local_llm
  ///
  /// CRITICAL: The native libllama.so has n_ctx=512 hardcoded.
  /// Total prompt + output MUST fit in 512 tokens.
  /// System prompt (~25 tokens) + context (~45 tokens) + user (~15 tokens) + ChatML (~15 tokens) = ~100 tokens
  /// Leaves ~412 tokens for generation output.
  Future<String?> generateChat(String userPrompt, {String? liveContext}) async {
    if (!_isInitialized) {
      throw Exception("AI Model not initialized");
    }
    try {
      // Ultra-compact system prompt (~25 tokens)
      const systemPrompt =
          "You are Ark, a finance advisor. Use the data below to give direct advice. Complete all sentences.";

      final userTurn = liveContext != null && liveContext.isNotEmpty
          ? "$userPrompt\n$liveContext"
          : userPrompt;

      final prompt = '<|im_start|>system\n'
          '$systemPrompt<|im_end|>\n'
          '<|im_start|>user\n'
          '$userTurn<|im_end|>\n'
          '<|im_start|>assistant\n';

      // Log actual prompt length for debugging
      debugPrint("📏 Prompt character length: ${prompt.length}");

      const settings = GenerationSettings(
        temperature: 0.4,
        topK: 40,
        topP: 0.9,
        maxTokens: 384, // Optimized token length to prevent memory spikes
        repeatPenalty: 1.15,
      );

      final response = await OnenmLocalLlmPlatform.instance.generate(
        prompt,
        settings.toMap(),
      );

      if (response == null || response.trim().isEmpty) {
        return null;
      }

      debugPrint("🧠 SLM Raw Output: $response");
      return response.trim();
    } catch (e) {
      debugPrint("Generation error: $e");
      return null;
    }
  }

  /// Clean up native resources
  Future<void> dispose() async {
    try {
      await OnenmLocalLlmPlatform.instance.releaseModel();
    } catch (e) {
      debugPrint("Error releasing model: $e");
    }
    _isInitialized = false;
  }
}
