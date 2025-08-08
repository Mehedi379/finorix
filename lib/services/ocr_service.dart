import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class OCRService extends ChangeNotifier {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  String _extractedText = '';

  bool get isProcessing => _isProcessing;
  String get extractedText => _extractedText;

  @override
  Future<void> dispose() async {
    await _textRecognizer.close();
    super.dispose();
  }

  Future<BillData?> scanBillFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Error scanning from camera: $e');
      return null;
    }
  }

  Future<BillData?> scanBillFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Error scanning from gallery: $e');
      return null;
    }
  }

  Future<BillData?> _processImage(File imageFile) async {
    _isProcessing = true;
    _extractedText = '';
    notifyListeners();

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      _extractedText = recognizedText.text;
      notifyListeners();

      return _parseBillData(_extractedText);
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  BillData? _parseBillData(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return null;

    // Extract total amount
    double? totalAmount = _extractTotalAmount(lines);

    // Extract merchant name (usually first line or line with common merchant indicators)
    String merchantName = _extractMerchantName(lines);

    // Extract date
    DateTime? date = _extractDate(lines);

    // Extract individual items
    List<BillItem> items = _extractItems(lines);

    if (totalAmount == null || totalAmount <= 0) return null;

    return BillData(
      merchantName: merchantName,
      totalAmount: totalAmount,
      date: date ?? DateTime.now(),
      items: items,
      rawText: text,
    );
  }

  double? _extractTotalAmount(List<String> lines) {
    // Common patterns for total amount
    final totalPatterns = [
      RegExp(r'total[:\s]*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'amount[:\s]*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'₹\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'rs\.?\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d{2})?)\s*₹', caseSensitive: false),
    ];

    // Look for total amount in reverse order (totals usually at bottom)
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].toLowerCase();

      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amount = double.tryParse(match.group(1) ?? '');
          if (amount != null && amount > 0) return amount;
        }
      }
    }

    // If no explicit total found, try to find the largest amount
    double? maxAmount;
    final amountPattern = RegExp(r'(\d+(?:\.\d{2})?)');

    for (final line in lines) {
      final matches = amountPattern.allMatches(line);
      for (final match in matches) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount != null && (maxAmount == null || amount > maxAmount)) {
          maxAmount = amount;
        }
      }
    }

    return maxAmount;
  }

  String _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return 'Unknown Merchant';

    // Usually the first line or a line with certain patterns
    for (final line in lines.take(3)) {
      if (line.length > 3 &&
          line.length < 50 &&
          !RegExp(r'^\d+').hasMatch(line)) {
        return line;
      }
    }

    return lines.first;
  }

  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})'),
      RegExp(r'(\d{2,4})[\/\-](\d{1,2})[\/\-](\d{1,2})'),
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            int day = int.parse(match.group(1)!);
            int month = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);

            // Handle 2-digit years
            if (year < 100) year += 2000;

            // Try different date formats
            try {
              return DateTime(year, month, day);
            } catch (e) {
              // Try swapping day and month
              try {
                return DateTime(year, day, month);
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    }

    return null;
  }

  List<BillItem> _extractItems(List<String> lines) {
    final items = <BillItem>[];

    for (final line in lines) {
      // Skip lines that look like headers or totals
      if (line.toLowerCase().contains('total') ||
          line.toLowerCase().contains('subtotal') ||
          line.toLowerCase().contains('tax') ||
          line.length < 3) continue;

      // Look for lines with item name and price
      final itemMatch =
          RegExp(r'(.+?)\s+(\d+(?:\.\d{2})?)\s*₹?$').firstMatch(line);
      if (itemMatch != null) {
        final itemName = itemMatch.group(1)?.trim();
        final price = double.tryParse(itemMatch.group(2) ?? '');

        if (itemName != null &&
            itemName.isNotEmpty &&
            price != null &&
            price > 0) {
          items.add(BillItem(name: itemName, price: price));
        }
      }
    }

    return items;
  }
}

class BillData {
  final String merchantName;
  final double totalAmount;
  final DateTime date;
  final List<BillItem> items;
  final String rawText;

  BillData({
    required this.merchantName,
    required this.totalAmount,
    required this.date,
    required this.items,
    required this.rawText,
  });

  String get suggestedTitle {
    if (merchantName.isNotEmpty && merchantName != 'Unknown Merchant') {
      return merchantName;
    }
    if (items.isNotEmpty) {
      return items.first.name;
    }
    return 'Bill Expense';
  }

  String get suggestedCategory {
    final title = suggestedTitle.toLowerCase();

    if (title.contains('restaurant') ||
        title.contains('food') ||
        title.contains('cafe') ||
        title.contains('pizza') ||
        title.contains('burger') ||
        title.contains('hotel')) {
      return 'Food';
    }
    if (title.contains('fuel') ||
        title.contains('petrol') ||
        title.contains('gas') ||
        title.contains('taxi') ||
        title.contains('uber') ||
        title.contains('ola')) {
      return 'Transport';
    }
    if (title.contains('mall') ||
        title.contains('store') ||
        title.contains('shop') ||
        title.contains('market')) {
      return 'Shopping';
    }
    if (title.contains('electric') ||
        title.contains('water') ||
        title.contains('internet') ||
        title.contains('phone')) {
      return 'Bills';
    }

    return 'General';
  }
}

class BillItem {
  final String name;
  final double price;
  final int quantity;

  BillItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}
