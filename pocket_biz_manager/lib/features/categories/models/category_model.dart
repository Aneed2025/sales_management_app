class Category {
  final int? categoryID;
  final String categoryName;

  Category({
    this.categoryID,
    required this.categoryName,
  });

  // Convert a Category object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'CategoryID': categoryID,
      'CategoryName': categoryName,
    };
  }

  // Extract a Category object from a Map object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      categoryID: map['CategoryID'],
      categoryName: map['CategoryName'],
    );
  }

  Category copyWith({
    int? categoryID,
    String? categoryName,
  }) {
    return Category(
      categoryID: categoryID ?? this.categoryID,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  String toString() {
    return 'Category{categoryID: $categoryID, categoryName: $categoryName}';
  }
}
