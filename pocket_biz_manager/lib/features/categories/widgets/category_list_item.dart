import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
          child: Text(
            category.categoryName.isNotEmpty ? category.categoryName[0].toUpperCase() : '?',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        title: Text(category.categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
        onTap: onTap,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
          onPressed: onDelete,
          tooltip: 'Delete Category',
        ),
      ),
    );
  }
}
