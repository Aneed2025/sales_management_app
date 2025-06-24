import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category_model.dart' as model; // Ensure prefix is used for model
import 'add_edit_category_screen.dart';
import '../widgets/category_list_item.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch categories when the screen is initialized if not already loaded
    // Provider might fetch in its constructor, so this could be redundant
    // but good for a pull-to-refresh scenario later.
    // Or if coming back to the screen and wanting fresh data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  void _navigateToAddEditScreen(BuildContext context, {model.Category? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditCategoryScreen(category: category),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryProvider provider, model.Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete category "${category.categoryName}"?\nThis action cannot be undone.'),
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
      final success = await provider.deleteCategory(category.categoryID!);
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);

      if (!success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete "${category.categoryName}". It might be in use or an error occurred.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Category "${category.categoryName}" deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (ctx, categoryProvider, child) {
          if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categoryProvider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No categories found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Category'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => categoryProvider.fetchCategories(),
            child: ListView.builder(
              itemCount: categoryProvider.categories.length,
              itemBuilder: (lCtx, index) {
                final category = categoryProvider.categories[index];
                return CategoryListItem(
                  category: category, // This now expects model.Category
                  onTap: () => _navigateToAddEditScreen(context, category: category),
                  onDelete: () => _confirmDelete(context, categoryProvider, category),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }
}
// Ensuring no trailing characters or lines after this closing brace.
