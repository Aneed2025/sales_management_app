class Product {
  final int? productID;
  final String productName;
  final String? sku;
  final String? barcode;
  final String? description;
  final int? categoryID; // Foreign Key to Categories table
  final double purchasePrice;
  final double salePrice;
  final double currentStock; // Will be managed by inventory movements later
  final double minStockLevel;
  final String? productImageURL; // Local path or URL
  final bool isActive;

  // To hold category name when joining data, not part of Products table
  final String? categoryName;

  Product({
    this.productID,
    required this.productName,
    this.sku,
    this.barcode,
    this.description,
    this.categoryID,
    this.purchasePrice = 0.0,
    this.salePrice = 0.0,
    this.currentStock = 0.0, // Initial stock is 0 until a purchase or adjustment
    this.minStockLevel = 0.0,
    this.productImageURL,
    this.isActive = true,
    this.categoryName, // For display purposes
  });

  Map<String, dynamic> toMap() {
    return {
      'ProductID': productID,
      'ProductName': productName,
      'SKU': sku,
      'Barcode': barcode,
      'Description': description,
      'CategoryID': categoryID,
      'PurchasePrice': purchasePrice,
      'SalePrice': salePrice,
      'CurrentStock': currentStock,
      'MinStockLevel': minStockLevel,
      'ProductImageURL': productImageURL,
      'IsActive': isActive ? 1 : 0,
    };
    // Note: categoryName is not part of the Products table, so not in toMap()
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productID: map['ProductID'],
      productName: map['ProductName'],
      sku: map['SKU'],
      barcode: map['Barcode'],
      description: map['Description'],
      categoryID: map['CategoryID'],
      purchasePrice: (map['PurchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['SalePrice'] as num?)?.toDouble() ?? 0.0,
      currentStock: (map['CurrentStock'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (map['MinStockLevel'] as num?)?.toDouble() ?? 0.0,
      productImageURL: map['ProductImageURL'],
      isActive: map['IsActive'] == 1,
      categoryName: map['CategoryName'], // If joined query provides it
    );
  }

  Product copyWith({
    int? productID,
    String? productName,
    String? sku,
    String? barcode,
    String? description,
    int? categoryID,
    double? purchasePrice,
    double? salePrice,
    double? currentStock,
    double? minStockLevel,
    String? productImageURL,
    bool? isActive,
    String? categoryName, // Allow copying this as well
  }) {
    return Product(
      productID: productID ?? this.productID,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      categoryID: categoryID ?? this.categoryID,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      productImageURL: productImageURL ?? this.productImageURL,
      isActive: isActive ?? this.isActive,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  String toString() {
    return 'Product{productID: $productID, productName: $productName, sku: $sku, categoryID: $categoryID, salePrice: $salePrice, currentStock: $currentStock, isActive: $isActive, categoryName: $categoryName}';
  }
}
