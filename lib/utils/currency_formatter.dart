import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/currency_settings.dart';

class CurrencyFormatter {
  static String formattedExchangeRate(CurrencySettings settings) {
    return settings != null ? settings.exchangeRate.toStringAsFixed(2) : '1.00';
  }
  static String reverseFormattedExchangeRate(CurrencySettings settings) {
    return settings != null ? (1 / settings.exchangeRate).toStringAsFixed(2) : '1.00';
  }

  static String formatAmount(BuildContext context, double amount) {
    // Always display in USD with 2 decimal places
    return '${amount.toStringAsFixed(2)}\$';
  }

  static String formatAmountWithCurrency(BuildContext context, double amount) {
    // Always display in USD with 2 decimal places
    return '${amount.toStringAsFixed(2)}\$ (USD)';
  }

  static String formatAmountOnly(BuildContext context, double amount) {
    // Always display in USD with 2 decimal places
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
    // Always return USD symbol
    return '\$';
  }

  static String getBaseCurrencySymbol(BuildContext context) {
    // Always return USD symbol
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



  // Helper method to get currency symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'LBP':
        return 'L.L.';
      case 'IQD':
        return 'ع.د';
      case 'IRR':
        return 'ریال';
      default:
        return currency; // Return currency code if no symbol is defined
    }
  }
} 