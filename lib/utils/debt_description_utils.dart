class DebtDescriptionUtils {
  /// Cleans debt descriptions by removing category information in parentheses
  /// and handling product combinations
  static String cleanDescription(String description) {
    if (description.isEmpty) return description;
    
    // Remove category information in parentheses anywhere in the description
    // This regex matches any text in parentheses
    String cleaned = description.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    
    // Handle "product + product" combinations
    // Split by " + " and take only the first product
    if (cleaned.contains(' + ')) {
      final parts = cleaned.split(' + ');
      if (parts.isNotEmpty) {
        cleaned = parts.first.trim();
      }
    }
    
    return cleaned;
  }
} 