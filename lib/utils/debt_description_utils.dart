class DebtDescriptionUtils {
  /// Cleans debt descriptions by removing category information in parentheses
  /// This removes any text in parentheses anywhere in the description
  static String cleanDescription(String description) {
    if (description.isEmpty) return description;
    
    // Remove category information in parentheses anywhere in the description
    // This regex matches any text in parentheses
    return description.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }
} 