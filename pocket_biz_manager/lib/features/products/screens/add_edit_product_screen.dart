import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../categories/models/category_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // Null if adding, populated if editing

  const AddEditProductScreen({super.key, this.product});

  static const routeName = '/add-edit-product';

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _minStockLevelController;

  int? _selectedCategoryId;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.product != null;

    _nameController = TextEditingController(text: _isEditing ? widget.product!.productName : '');
    _skuController = TextEditingController(text: _isEditing ? widget.product!.sku : '');
    _barcodeController = TextEditingController(text: _isEditing ? widget.product!.barcode : '');
    _descriptionController = TextEditingController(text: _isEditing ? widget.product!.description : '');
    _purchasePriceController = TextEditingController(text: _isEditing ? widget.product!.purchasePrice.toStringAsFixed(2) : '0.00');
    _salePriceController = TextEditingController(text: _isEditing ? widget.product!.salePrice.toStringAsFixed(2) : '0.00');
    _minStockLevelController = TextEditingController(text: _isEditing ? widget.product!.minStockLevel.toStringAsFixed(0) : '0');

    _selectedCategoryId = _isEditing ? widget.product!.categoryID : null;
    _isActive = _isEditing ? widget.product!.isActive : true;

    // Fetch categories if not already loaded by CategoryProvider constructor or if list is empty
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    if (categoryProvider.categories.isEmpty && !categoryProvider.isLoading) {
      Future.microtask(() => categoryProvider.fetchCategories());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _minStockLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool success = false;
    String successMessage = '';
    String errorMessage = '';

    final newProduct = Product(
      productID: _isEditing ? widget.product!.productID : null,
      productName: _nameController.text.trim(),
      sku: _skuController.text.trim().isEmpty ? null : _skuController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      categoryID: _selectedCategoryId,
      purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
      salePrice: double.tryParse(_salePriceController.text) ?? 0.0,
      minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
      isActive: _isActive,
      currentStock: _isEditing ? widget.product!.currentStock : 0.0, // Stock not editable here
      productImageURL: _isEditing ? widget.product!.productImageURL : null, // Image not handled yet
    );

    try {
      if (_isEditing) {
        success = await productProvider.updateProduct(newProduct);
        successMessage = 'Product updated successfully!';
        errorMessage = productProvider.errorMessage ?? 'Failed to update product. SKU/Barcode might already exist or another error occurred.';
      } else {
        success = await productProvider.addProduct(newProduct);
        successMessage = 'Product added successfully!';
        errorMessage = productProvider.errorMessage ?? 'Failed to add product. SKU/Barcode might already exist or another error occurred.';
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to CategoryProvider for the dropdown
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(controller: _nameController, label: 'Product Name*', icon: Icons.label_important_outline, validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null),
              _buildTextFormField(controller: _skuController, label: 'SKU (Optional)', icon: Icons.qr_code_2),
              _buildTextFormField(controller: _barcodeController, label: 'Barcode (Optional)', icon: Icons.qr_code_scanner_outlined),
              _buildTextFormField(controller: _descriptionController, label: 'Description (Optional)', icon: Icons.notes, maxLines: 3),

              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category (Optional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined, color: Theme.of(context).inputDecorationTheme.labelStyle?.color),
                ),
                items: categoryProvider.categories.map<DropdownMenuItem<int>>((model.Category category) { // Explicitly use model.Category
                  return DropdownMenuItem<int>(
                    value: category.categoryID,
                    child: Text(category.categoryName),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
                hint: categoryProvider.isLoading ? const Text("Loading categories...") : const Text('Select a category'),
                isExpanded: true,
                 validator: (value) { // Example: make category mandatory
                    // if (value == null) return 'Please select a category.';
                    return null;
                  },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextFormField(controller: _purchasePriceController, label: 'Purchase Price (NAD)*', icon: Icons.monetization_on_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (val) => (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) < 0) ? 'Invalid' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextFormField(controller: _salePriceController, label: 'Sale Price (NAD)*', icon: Icons.price_check_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))], validator: (val) => (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) < 0) ? 'Invalid' : null)),
                ],
              ),
              const SizedBox(height: 16),
               _buildTextFormField(controller: _minStockLevelController, label: 'Min. Stock Level (Units)*', icon: Icons.warning_amber_rounded, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) < 0) ? 'Invalid' : null),

              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Product is Active'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_shopping_cart_outlined),
                      label: Text(_isEditing ? 'Save Product Changes' : 'Add Product to Inventory'),
                      onPressed: _saveForm,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0), // Reduced bottom padding
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).inputDecorationTheme.labelStyle?.color) : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0), // Adjust padding
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }
}
