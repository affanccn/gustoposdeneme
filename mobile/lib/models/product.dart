class Modifier {
  final String id;
  final String name;
  final double price;
  final bool isActive;

  Modifier({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == null ? true : (json['isActive'] as bool),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isActive': isActive,
    };
  }
}

class Category {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] == null ? true : (json['isActive'] as bool),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

class Product {
  final String id;
  final String categoryId;
  final String name;
  final double price;
  final String? image;
  final bool isStockControlled;
  final double stockLevel;
  final bool isActive;
  final bool isFavorite;
  final int sortOrder;
  final List<Modifier> modifiers;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.image,
    this.isStockControlled = false,
    this.stockLevel = 0.0,
    this.isActive = true,
    this.isFavorite = false,
    this.sortOrder = 0,
    this.modifiers = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Modifier> mods = [];
    if (json['modifiers'] != null && json['modifiers'] is List) {
      mods = (json['modifiers'] as List)
          .map((m) => Modifier.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image']?.toString(),
      isStockControlled: json['isStockControlled'] == true,
      stockLevel: (json['stockLevel'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] == null ? true : (json['isActive'] as bool),
      isFavorite: json['isFavorite'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      modifiers: mods,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'price': price,
      'image': image,
      'isStockControlled': isStockControlled,
      'stockLevel': stockLevel,
      'isActive': isActive,
      'isFavorite': isFavorite,
      'sortOrder': sortOrder,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
    };
  }
}
