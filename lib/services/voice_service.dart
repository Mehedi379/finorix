import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _text = '';
  double _confidence = 0.0;

  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    return await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.notListeningStatus) {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (error) {
        _isListening = false;
        notifyListeners();
        print('Speech recognition error: $error');
      },
    );
  }

  Future<void> startListening() async {
    if (!_speech.isAvailable) return;

    _text = '';
    _confidence = 0.0;
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _text = result.recognizedWords;
        _confidence = result.confidence;
        notifyListeners();
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  // Parse voice input for expense data
  ExpenseVoiceData? parseExpenseFromVoice(String voiceText) {
    final text = voiceText.toLowerCase();

    // Extract amount using regex
    final amountRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    final amountMatch = amountRegex.firstMatch(text);
    double? amount;

    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1) ?? '');
    }

    // Extract category based on keywords
    String category = 'General';
    if (text.contains('food') ||
        text.contains('restaurant') ||
        text.contains('lunch') ||
        text.contains('dinner')) {
      category = 'Food';
    } else if (text.contains('transport') ||
        text.contains('taxi') ||
        text.contains('bus') ||
        text.contains('fuel')) {
      category = 'Transport';
    } else if (text.contains('bill') ||
        text.contains('electricity') ||
        text.contains('water') ||
        text.contains('rent')) {
      category = 'Bills';
    } else if (text.contains('shopping') ||
        text.contains('clothes') ||
        text.contains('buy') ||
        text.contains('purchase')) {
      category = 'Shopping';
    }

    // Extract title (remove amount and common words)
    String title = text
        .replaceAll(amountMatch?.group(0) ?? '', '')
        .replaceAll(
            RegExp(r'\b(rupees?|dollars?|for|spent|on|bought|paid)\b'), '')
        .trim();

    if (title.isEmpty) {
      title = '$category expense';
    } else {
      // Capitalize first letter
      title = title[0].toUpperCase() + title.substring(1);
    }

    if (amount == null || amount <= 0) return null;

    return ExpenseVoiceData(
      title: title,
      amount: amount,
      category: category,
    );
  }
}

class ExpenseVoiceData {
  final String title;
  final double amount;
  final String category;

  ExpenseVoiceData({
    required this.title,
    required this.amount,
    required this.category,
  });
}
