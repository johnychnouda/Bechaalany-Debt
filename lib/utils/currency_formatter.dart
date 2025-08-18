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

  /// Formats product price for display in the Products screen
  /// LBP products: Convert to USD for display
  /// USD products: Show as-is
  static String formatProductPrice(BuildContext context, double amount, {String? storedCurrency}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && storedCurrency != null && settings.exchangeRate != null) {
      if (storedCurrency.toUpperCase() == 'LBP') {
        // Convert LBP to USD for display
        final convertedAmount = amount / settings.exchangeRate!;
        return '${convertedAmount.toStringAsFixed(2)}\$';
      } else if (storedCurrency.toUpperCase() == 'USD') {
        // Already in USD, show as-is
        return '${amount.toStringAsFixed(2)}\$';
      }
    }
    
    // Fallback to USD with dollar sign on the right side
    return '${amount.toStringAsFixed(2)}\$';
  }

  /// Formats amount for display based on stored currency
  /// LBP products: Always convert to current USD rate for display
  /// USD products: Always show same USD amount regardless of exchange rate
  static String formatAmount(BuildContext context, double amount, {String? storedCurrency}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && storedCurrency != null && settings.exchangeRate != null) {
      // If stored currency is LBP, the amount should already be in USD (converted during debt creation)
      // So we just display the amount as-is, since it's already the correct USD value
      if (storedCurrency.toUpperCase() == 'LBP') {
        // Amount is already in USD (converted during debt creation), just display it
        return '${amount.toStringAsFixed(2)}\$';
      } else if (storedCurrency.toUpperCase() == 'USD') {
        // Already in USD, always show the same amount regardless of exchange rate changes
        return '${amount.toStringAsFixed(2)}\$';
      }
    }
    
    // Fallback to USD with dollar sign on the right side
    return '${amount.toStringAsFixed(2)}\$';
  }

  /// Gets the current USD equivalent for LBP products, or original amount for USD products
  /// This is used for calculations and business logic
  static double getCurrentUSDEquivalent(BuildContext context, double amount, {String? storedCurrency}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && storedCurrency != null && settings.exchangeRate != null) {
      // If stored currency is LBP, convert to current USD rate
      if (storedCurrency.toUpperCase() == 'LBP') {
        return amount / settings.exchangeRate!;
      } else if (storedCurrency.toUpperCase() == 'USD') {
        // Already in USD, return as-is
        return amount;
      }
    }
    
    // Fallback to original amount
    return amount;
  }

  /// Gets the original amount in its stored currency
  /// This preserves the original pricing context
  static double getOriginalAmount(double amount, {String? storedCurrency}) {
    // Always return the original amount as stored
    return amount;
  }

  /// Formats amount with currency symbol for display
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

  /// Formats amount only (without currency symbol)
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

  /// Gets currency symbol for display
  static String getCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return _getCurrencySymbol(settings.targetCurrency);
    }
    
    // Fallback to USD symbol
    return '\$';
  }

  /// Gets base currency symbol (USD)
  static String getBaseCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return _getCurrencySymbol(settings.baseCurrency);
    }
    
    // Fallback to USD symbol
    return '\$';
  }

  /// Gets the appropriate currency symbol for a given currency
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

  /// Formats number with appropriate decimal places and thousands separators
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

  /// Adds thousands separators to a number string
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

  /// Gets the appropriate decimal places for a currency
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

  /// Convert amount using current exchange rate (for general conversions)
  static double? convertAmount(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.convertAmount(amount);
  }

  /// Convert amount back to base currency (for reverse conversions)
  static double? convertBack(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && settings.exchangeRate != null) {
      return settings.convertBack(amount);
    }
    
    return null;
  }

  /// Gets the current exchange rate for display purposes
  static String? getCurrentExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null && settings.exchangeRate != null) {
      return '1 ${settings.baseCurrency} = ${_addThousandsSeparators(settings.exchangeRate!.toInt().toString())} ${settings.targetCurrency}';
    }
    
    return null;
  }
} 