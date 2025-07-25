import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CurrencyFormatter {
  static String formatAmount(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      // Display in Base Currency (not Target Currency)
      final decimals = _getDecimalPlaces(settings.baseCurrency);
      return '${amount.toStringAsFixed(decimals)} ${settings.baseCurrency}';
    }
    
    // Fallback to base currency if no settings
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String formatAmountWithBase(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      final convertedAmount = settings.convertAmount(amount);
      final baseDecimals = _getDecimalPlaces(settings.baseCurrency);
      final targetDecimals = _getDecimalPlaces(settings.targetCurrency);
      return '${amount.toStringAsFixed(baseDecimals)} ${settings.baseCurrency} (${convertedAmount.toStringAsFixed(targetDecimals)} ${settings.targetCurrency})';
    }
    
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String formatAmountOnly(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      // Display in Base Currency (not Target Currency)
      final decimals = _getDecimalPlaces(settings.baseCurrency);
      return amount.toStringAsFixed(decimals);
    }
    
    return amount.toStringAsFixed(2);
  }

  // Helper method to determine decimal places based on currency
  static int _getDecimalPlaces(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
      case 'EUR':
      case 'GBP':
      case 'CAD':
      case 'AUD':
      case 'JPY':
        return 2;
      case 'LBP':
      case 'IQD':
      case 'IRR':
        return 0;
      default:
        return 2; // Default to 2 decimals for unknown currencies
    }
  }

  static String getCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return settings.baseCurrency;
    }
    
    return '\$';
  }

  static String getBaseCurrencySymbol(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      return settings.baseCurrency;
    }
    
    return '\$';
  }

  // Convert amount using current exchange rate
  static double convertAmount(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.convertAmount(amount);
  }

  // Convert amount back to base currency
  static double convertBack(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.convertBack(amount);
  }

  // Get formatted exchange rate for display
  static String getFormattedExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.formattedExchangeRate;
  }

  // Get reverse formatted exchange rate for display
  static String getReverseFormattedExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.reverseFormattedExchangeRate;
  }
} 