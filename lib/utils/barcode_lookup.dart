import '../models/category.dart';

/// Result of matching a scanned or typed barcode to a catalog product.
class BarcodeLookupResult {
  final ProductCategory category;
  final Subcategory subcategory;

  const BarcodeLookupResult({
    required this.category,
    required this.subcategory,
  });
}

/// Normalizes barcode input (trim; scanners may append newline).
String normalizeBarcode(String raw) => raw.trim();

/// Finds a product by barcode across all categories.
///
/// Pass [excludeSubcategoryId] when editing an existing product so its own
/// barcode does not count as a duplicate.
BarcodeLookupResult? findProductByBarcode(
  List<ProductCategory> categories,
  String rawBarcode, {
  String? excludeSubcategoryId,
}) {
  final code = normalizeBarcode(rawBarcode);
  if (code.isEmpty) return null;

  for (final category in categories) {
    for (final subcategory in category.subcategories) {
      if (excludeSubcategoryId != null &&
          subcategory.id == excludeSubcategoryId) {
        continue;
      }
      if (!subcategory.useBarcode) continue;
      final stored = subcategory.barcode;
      if (stored == null || stored.trim().isEmpty) continue;
      if (normalizeBarcode(stored) == code) {
        return BarcodeLookupResult(
          category: category,
          subcategory: subcategory,
        );
      }
    }
  }
  return null;
}
