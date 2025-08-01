import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_settings.dart';

class CurrencyFormatter {
  static String formattedExchangeRate(CurrencySettings settings) {
    return settings.exchangeRate.toStringAsFixed(2);
  }
  static String reverseFormattedExchangeRate(CurrencySettings settings) {
    return (1 / settings.exchangeRate).toStringAsFixed(2);
  }

  static String formatAmount(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      // Convert amount using current exchange rate
      final convertedAmount = settings.convertAmount(amount);
      return '${convertedAmount.toStringAsFixed(_getDecimalPlaces(settings.targetCurrency))} ${settings.targetCurrency}';
    }
    
    // Fallback to USD
    return '${amount.toStringAsFixed(2)}\$';
  }

  static String formatAmountWithCurrency(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      final convertedAmount = settings.convertAmount(amount);
      return '${convertedAmount.toStringAsFixed(_getDecimalPlaces(settings.targetCurrency))} ${settings.targetCurrency}';
    }
    
    // Fallback to USD
    return '${amount.toStringAsFixed(2)}\$ (USD)';
  }

  static String formatAmountOnly(BuildContext context, double amount) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    
    if (settings != null) {
      final convertedAmount = settings.convertAmount(amount);
      return convertedAmount.toStringAsFixed(_getDecimalPlaces(settings.targetCurrency));
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
    final settings = appState.currencySettings;
    if (settings != null) {
      return settings.formattedRate;
    }
    return '1 USD = 1.00 USD';
  }

  // Get reverse formatted exchange rate for display
  static String getReverseFormattedExchangeRate(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final settings = appState.currencySettings;
    if (settings != null) {
      return settings.reverseFormattedRate;
    }
    return '1 USD = 1.00 USD';
  }




} 