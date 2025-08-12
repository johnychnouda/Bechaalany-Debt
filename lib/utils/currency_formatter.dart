import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_settings.dart';

class CurrencyFormatter {
  static String? formattedExchangeRate(CurrencySettings settings) {
    if (settings.exchangeRate == null) return null;
    return settings.exchangeRate!.toStringAsFixed(2);
  }
  static String? reverseFormattedExchangeRate(CurrencySettings settings) {
    if (settings.exchangeRate == null) return null;
    return (1 / settings.exchangeRate!).toStringAsFixed(2);
  }

  static String formatAmount(BuildContext context, double amount, {String? storedCurrency}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && storedCurrency != null && settings.exchangeRate != null) {
      // If stored currency is LBP, convert to USD using exchange rate
      if (storedCurrency.toUpperCase() == 'LBP') {
        // Convert LBP to USD by dividing by exchange rate
        final convertedAmount = amount / settings.exchangeRate!;
        return '${convertedAmount.toStringAsFixed(2)}\$';
      } else {
        // Already in USD, format as is
        return '${amount.toStringAsFixed(2)}\$';
      }
    }
    
    // Fallback to USD with dollar sign on the right side
    return '${amount.toStringAsFixed(2)}\$';
  }

  static String formatAmountWithCurrency(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && settings.exchangeRate != null) {
      final convertedAmount = settings.convertAmount(amount);
      if (convertedAmount != null) {
        return '${_formatNumberWithCommas(convertedAmount, settings.targetCurrency)} ${settings.targetCurrency}';
      }
    }
    
    // Fallback to USD
    return '${amount.toStringAsFixed(2)}\$ (USD)';
  }

  static String formatAmountOnly(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && settings.exchangeRate != null) {
      final convertedAmount = settings.convertAmount(amount);
      if (convertedAmount != null) {
        return _formatNumberWithCommas(convertedAmount, settings.targetCurrency);
      }
    }
    
    // Fallback to USD
    return amount.toStringAsFixed(2);
  }

  static String getCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return _getCurrencySymbol(settings.targetCurrency);
    }
    
    // Fallback to USD symbol
    return '\$';
  }

  static String getBaseCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return _getCurrencySymbol(settings.baseCurrency);
    }
    
    // Fallback to USD symbol
    return '\$';
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'LBP':
        return 'L.L.';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currency;
    }
  }

  static String _formatNumberWithCommas(double amount, String currency) {
    final decimalPlaces = _getDecimalPlaces(currency);
    final formattedNumber = amount.toStringAsFixed(decimalPlaces);
    
    if (currency.toUpperCase() == 'LBP') {
      // For LBP, add thousands separators
      final parts = formattedNumber.split('.');
      final integerPart = parts[0];
      final decimalPart = parts.length > 1 ? parts[1] : '';
      
      // Add commas for thousands
      final formattedInteger = _addThousandsSeparators(integerPart);
      
      if (decimalPart.isNotEmpty) {
        return '$formattedInteger.$decimalPart';
      } else {
        return formattedInteger;
      }
    } else {
      // For other currencies, use standard formatting
      return formattedNumber;
    }
  }

  static String _addThousandsSeparators(String number) {
    final buffer = StringBuffer();
    final length = number.length;
    
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(number[i]);
    }
    
    return buffer.toString();
  }

  static int _getDecimalPlaces(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'EUR':
      case 'GBP':
      case 'CAD':
      case 'AUD':
        return 2;
      case 'LBP':
      case 'IQD':
      case 'IRR':
        return 0;
      default:
        return 2;
    }
  }

  // Convert amount using current exchange rate
  static double? convertAmount(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.convertAmount(amount);
  }

  // Convert amount back to base currency
  static double? convertBack(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.convertBack(amount);
  }

  // Get formatted exchange rate for display
  static String? getFormattedExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    if (settings != null) {
      return settings.formattedRate;
    }
    return null;
  }

  // Get reverse formatted exchange rate for display
  static String? getReverseFormattedExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    if (settings != null) {
      return settings.reverseFormattedRate;
    }
    return null;
  }




} 