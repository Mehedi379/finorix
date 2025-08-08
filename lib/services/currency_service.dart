import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CurrencyService extends ChangeNotifier {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  Map<String, double> _exchangeRates = {};
  String _baseCurrency = 'USD';
  String _selectedCurrency = 'INR';
  bool _isLoading = false;
  DateTime? _lastUpdate;

  Map<String, double> get exchangeRates => _exchangeRates;
  String get baseCurrency => _baseCurrency;
  String get selectedCurrency => _selectedCurrency;
  bool get isLoading => _isLoading;
  DateTime? get lastUpdate => _lastUpdate;

  // Supported currencies with their symbols
  static const Map<String, String> supportedCurrencies = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'Fr',
    'CNY': '¥',
    'SEK': 'kr',
    'NZD': 'NZ\$',
    'MXN': 'Mex\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NOK': 'kr',
  };

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('selected_currency') ?? 'INR';

    // Load cached exchange rates
    final ratesJson = prefs.getString('exchange_rates');
    if (ratesJson != null) {
      try {
        final Map<String, dynamic> rates = jsonDecode(ratesJson);
        _exchangeRates =
            rates.map((key, value) => MapEntry(key, value.toDouble()));

        final lastUpdateStr = prefs.getString('rates_last_update');
        if (lastUpdateStr != null) {
          _lastUpdate = DateTime.parse(lastUpdateStr);
        }
      } catch (e) {
        print('Error loading cached exchange rates: $e');
      }
    }

    // Update rates if they're more than 1 hour old or don't exist
    if (_lastUpdate == null ||
        DateTime.now().difference(_lastUpdate!).inHours > 1) {
      await updateExchangeRates();
    }

    notifyListeners();
  }

  Future<bool> updateExchangeRates() async {
    if (_isLoading) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Using a free API for exchange rates
      // Note: Replace with your preferred API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$_baseCurrency'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _exchangeRates = Map<String, double>.from(data['rates']);
        _lastUpdate = DateTime.now();

        // Cache the rates
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('exchange_rates', jsonEncode(_exchangeRates));
        await prefs.setString(
            'rates_last_update', _lastUpdate!.toIso8601String());

        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error updating exchange rates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return false;
  }

  Future<void> setSelectedCurrency(String currency) async {
    if (supportedCurrencies.containsKey(currency)) {
      _selectedCurrency = currency;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_currency', currency);

      notifyListeners();
    }
  }

  double convertAmount(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;

    if (_exchangeRates.isEmpty) return amount;

    // Convert to base currency first, then to target currency
    double amountInBase = amount;
    if (fromCurrency != _baseCurrency) {
      final fromRate = _exchangeRates[fromCurrency];
      if (fromRate == null) return amount;
      amountInBase = amount / fromRate;
    }

    if (toCurrency == _baseCurrency) return amountInBase;

    final toRate = _exchangeRates[toCurrency];
    if (toRate == null) return amount;

    return amountInBase * toRate;
  }

  String formatAmount(double amount, [String? currency]) {
    currency ??= _selectedCurrency;
    final symbol = supportedCurrencies[currency] ?? currency;

    // Format based on currency
    if (currency == 'JPY') {
      return '$symbol${amount.toStringAsFixed(0)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  String getCurrencySymbol(String currency) {
    return supportedCurrencies[currency] ?? currency;
  }

  List<String> get availableCurrencies => supportedCurrencies.keys.toList();
}
