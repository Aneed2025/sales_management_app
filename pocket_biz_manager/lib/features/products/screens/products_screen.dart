import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'add_edit_product_screen.dart';
import '../widgets/product_list_item.dart'; // Will create this widget
// import '../../categories/providers/category_provider.dart'; // Needed for AddEditProductScreen

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  static const routeName = '/products';

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {

  @override
  void initState() {
    super.initState();
    // Initial fetch, provider constructor also calls this.
    // Good for pull-to-refresh.
    // Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  void _navigateToAddEditScreen(BuildContext context, {Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditProductScreen(product: product),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProductProvider provider, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete product "${product.productName}"?\nThis action cannot be undone and might affect historical records if already used.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteProduct(product.productID!);
      if (mounted) {
        final message = success
            ? 'Product "${product.productName}" deleted.'
            : provider.errorMessage ?? 'Failed to delete "${product.productName}". It might be in use or an error occurred.';
        final bgColor = success ? Colors.green : Theme.of(context).colorScheme.error;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: bgColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure CategoryProvider is available if AddEditProductScreen needs it directly
    // final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
      ),
      body: Consumer<ProductProvider>(
        builder: (ctx, productProvider, child) {
          if (productProvider.isLoading && productProvider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (productProvider.errorMessage != null && productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(productProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16)),
                  const SizedBox(height:10),
                  ElevatedButton(onPressed: () => productProvider.fetchProducts(), child: const Text("Retry")),
                ],
              )
            );
          }
          if (productProvider.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No products found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Product'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => productProvider.fetchProducts(),
            child: ListView.builder(
              itemCount: productProvider.products.length,
              itemBuilder: (lCtx, index) {
                final product = productProvider.products[index];
                return ProductListItem(
                  product: product,
                  onTap: () => _navigateToAddEditScreen(context, product: product),
                  onDelete: () => _confirmDelete(context, productProvider, product),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Product',
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
