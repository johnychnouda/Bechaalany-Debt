import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 4)
class ProductCategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  List<Subcategory> subcategories;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    List<Subcategory>? subcategories,
  }) : subcategories = subcategories ?? [];

  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Subcategory>? subcategories,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'subcategories': subcategories.map((s) => s.toJson()).toList(),
    };
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      subcategories: (json['subcategories'] as List?)
          ?.map((s) => Subcategory.fromJson(s))
          .toList() ?? [],
    );
  }
}

@HiveType(typeId: 5)
class Subcategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  double costPrice;

  @HiveField(4)
  double sellingPrice;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  List<PriceHistory> priceHistory;

  Subcategory({
    required this.id,
    required this.name,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.createdAt,
    List<PriceHistory>? priceHistory,
  }) : priceHistory = priceHistory ?? [];

  double get profit => sellingPrice - costPrice;
  double get profitPercentage => costPrice > 0 ? (profit / costPrice) * 100 : 0;

  void updatePrices({
    double? newCostPrice,
    double? newSellingPrice,
  }) {
    if (newCostPrice != null || newSellingPrice != null) {
      // Add current prices to history before updating
      priceHistory.add(PriceHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        changedAt: DateTime.now(),
      ));

      if (newCostPrice != null) costPrice = newCostPrice;
      if (newSellingPrice != null) sellingPrice = newSellingPrice;
    }
  }

  Subcategory copyWith({
    String? id,
    String? name,
    String? description,
    double? costPrice,
    double? sellingPrice,
    DateTime? createdAt,
    List<PriceHistory>? priceHistory,
  }) {
    return Subcategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      createdAt: createdAt ?? this.createdAt,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'createdAt': createdAt.toIso8601String(),
      'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
    };
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      costPrice: json['costPrice'].toDouble(),
      sellingPrice: json['sellingPrice'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      priceHistory: (json['priceHistory'] as List?)
          ?.map((p) => PriceHistory.fromJson(p))
          .toList() ?? [],
    );
  }
}

@HiveType(typeId: 6)
class PriceHistory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double costPrice;

  @HiveField(2)
  double sellingPrice;

  @HiveField(3)
  DateTime changedAt;

  PriceHistory({
    required this.id,
    required this.costPrice,
    required this.sellingPrice,
    required this.changedAt,
  });

  double get profit => sellingPrice - costPrice;

  PriceHistory copyWith({
    String? id,
    double? costPrice,
    double? sellingPrice,
    DateTime? changedAt,
  }) {
    return PriceHistory(
      id: id ?? this.id,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'changedAt': changedAt.toIso8601String(),
    };
  }

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['id'],
      costPrice: json['costPrice'].toDouble(),
      sellingPrice: json['sellingPrice'].toDouble(),
      changedAt: DateTime.parse(json['changedAt']),
    );
  }
} 