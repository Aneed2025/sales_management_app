import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../../../core/database/database_service.dart';
// Import CategoryProvider to access categories for new product form, etc.
// import '../../categories/providers/category_provider.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  // final CategoryProvider _categoryProvider; // Optional: Inject if needed for direct access

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ProductProvider({required CategoryProvider categoryProvider}) : _categoryProvider = categoryProvider {
  ProductProvider() {
    fetchProducts();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if(value) _errorMessage = null; // Clear error when loading
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllProductsWithCategoryName();
      _products = maps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching products: $e");
      _setError("Failed to load products. Please try again.");
      _products = [];
    }
    _setLoading(false);
  }

  Future<Product?> getProductById(int productId) async {
    // First check if product is already in the list
    try {
      return _products.firstWhere((p) => p.productID == productId);
    } catch (e) {
      // Not in list, try fetching from DB
      _setLoading(true);
      try {
        final map = await _dbService.getProductByIdWithCategoryName(productId);
        _setLoading(false);
        if (map != null) {
          return Product.fromMap(map);
        }
        return null;
      } catch (dbError) {
        debugPrint("Error fetching product by ID $productId: $dbError");
        _setError("Failed to load product details.");
        _setLoading(false);
        return null;
      }
    }
  }


  Future<bool> addProduct(Product product) async {
    _setLoading(true);
    try {
      // Basic validation: Check if product with the same name or SKU/Barcode already exists (optional)
      // bool nameExists = _products.any((p) => p.productName.toLowerCase() == product.productName.trim().toLowerCase());
      // if (nameExists) {
      //   _setError("Product with name '${product.productName.trim()}' already exists.");
      //   _setLoading(false);
      //   return false;
      // }
      // Add similar checks for SKU/Barcode if they must be unique and are provided

      final id = await _dbService.insertProduct(product.toMap());
      if (id > 0) {
        // Refetch the product with category name or construct it carefully
        final newProductMap = await _dbService.getProductByIdWithCategoryName(id);
        if (newProductMap != null) {
            final newProductWithCategory = Product.fromMap(newProductMap);
            _products.add(newProductWithCategory);
            _products.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
            notifyListeners();
        } else {
            // Fallback if fetching with category name fails, add with data we have
            _products.add(product.copyWith(productID: id));
             _products.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
            notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error adding product: $e");
      _setError("Failed to add product. Ensure SKU/Barcode are unique if provided.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateProduct(Product product) async {
    _setLoading(true);
    try {
      final rowsAffected = await _dbService.updateProduct(product.toMap());
      if (rowsAffected > 0) {
        final index = _products.indexWhere((p) => p.productID == product.productID);
        if (index != -1) {
           // Refetch the product with category name to ensure consistency
          final updatedProductMap = await _dbService.getProductByIdWithCategoryName(product.productID!);
          if (updatedProductMap != null) {
            _products[index] = Product.fromMap(updatedProductMap);
          } else {
            // Fallback: update with the data we have
            _products[index] = product;
          }
          _products.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating product: $e");
      _setError("Failed to update product. Ensure SKU/Barcode are unique if provided.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteProduct(int productID) async {
    _setLoading(true);
    // IMPORTANT: Add logic here to check if the product is used in any transactions.
    // For now, direct deletion.
    try {
      final rowsAffected = await _dbService.deleteProduct(productID);
      if (rowsAffected > 0) {
        _products.removeWhere((p) => p.productID == productID);
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting product: $e");
      _setError("Failed to delete product. It might be in use.");
    }
    _setLoading(false);
    return false;
  }

  // This method will be more relevant when inventory movements are implemented.
  // For now, it's a placeholder or direct update.
  Future<bool> updateProductStock(int productId, double newStock) async {
    _setLoading(true);
    try {
      final rowsAffected = await _dbService.updateProductStock(productId, newStock);
      if (rowsAffected > 0) {
        final index = _products.indexWhere((p) => p.productID == productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(currentStock: newStock);
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating product stock: $e");
       _setError("Failed to update stock for product ID $productId.");
    }
    _setLoading(false);
    return false;
  }
}
