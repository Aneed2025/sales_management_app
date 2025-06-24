import 'package:flutter/foundation.dart';
import '../models/category_model.dart' as model; // Use prefix 'model'
import '../../../core/database/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<model.Category> _categories = []; // Use model.Category
  bool _isLoading = false;

  List<model.Category> get categories => _categories; // Use model.Category
  bool get isLoading => _isLoading;

  CategoryProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllCategories();
      _categories = maps.map((map) => model.Category.fromMap(map)).toList(); // Use model.Category
    } catch (e) {
      // Handle error, maybe log it or show a message to the user
      debugPrint("Error fetching categories: $e");
      _categories = []; // Reset to empty list on error
    }
    _setLoading(false);
  }

  Future<bool> addCategory(String categoryName) async {
    _setLoading(true);
    try {
      model.Category newCategory = model.Category(categoryName: categoryName.trim()); // Use model.Category
      // Check if category with the same name already exists (case-insensitive)
      bool exists = _categories.any((cat) => cat.categoryName.toLowerCase() == newCategory.categoryName.toLowerCase());
      if (exists) {
        debugPrint("Category with name '${newCategory.categoryName}' already exists.");
        _setLoading(false);
        return false; // Indicate failure due to duplication
      }

      final id = await _dbService.insertCategory(newCategory.toMap());
      if (id > 0) {
        newCategory = newCategory.copyWith(categoryID: id);
        _categories.add(newCategory);
        _categories.sort((a, b) => a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase()));
        notifyListeners();
        _setLoading(false);
        return true; // Indicate success
      }
    } catch (e) {
      debugPrint("Error adding category: $e");
    }
    _setLoading(false);
    return false; // Indicate failure
  }

  Future<bool> updateCategory(model.Category category) async { // Use model.Category
    _setLoading(true);
    try {
      // Check if another category with the same name already exists (case-insensitive)
      bool exists = _categories.any((cat) =>
          cat.categoryName.toLowerCase() == category.categoryName.trim().toLowerCase() &&
          cat.categoryID != category.categoryID);
      if (exists) {
        debugPrint("Another category with name '${category.categoryName.trim()}' already exists.");
        _setLoading(false);
        return false; // Indicate failure due to duplication
      }

      final rowsAffected = await _dbService.updateCategory(category.toMap());
      if (rowsAffected > 0) {
        final index = _categories.indexWhere((c) => c.categoryID == category.categoryID);
        if (index != -1) {
          _categories[index] = category;
          _categories.sort((a, b) => a.categoryName.toLowerCase().compareTo(b.categoryName.toLowerCase()));
          notifyListeners();
          _setLoading(false);
          return true; // Indicate success
        }
      }
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
    _setLoading(false);
    return false; // Indicate failure
  }

  Future<bool> deleteCategory(int categoryID) async {
    _setLoading(true);
    // IMPORTANT: Add logic here to check if the category is used by any products.
    // For now, we proceed with direct deletion for simplicity in this step.
    // Example check (pseudo-code, ProductProvider would be needed):
    // bool isUsed = await ProductProvider.isCategoryUsed(categoryID);
    // if (isUsed) {
    //   _setLoading(false);
    //   // Show a message to the user that category is in use
    //   return false;
    // }

    try {
      final rowsAffected = await _dbService.deleteCategory(categoryID);
      if (rowsAffected > 0) {
        _categories.removeWhere((c) => c.categoryID == categoryID);
        notifyListeners();
        _setLoading(false);
        return true; // Indicate success
      }
    } catch (e) {
      debugPrint("Error deleting category: $e");
      // Potentially, the error could be due to foreign key constraint if not handled
    }
    _setLoading(false);
    return false; // Indicate failure
  }

  model.Category? getCategoryById(int id) { // Use model.Category
    try {
      return _categories.firstWhere((cat) => cat.categoryID == id);
    } catch (e) {
      return null; // Not found
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
