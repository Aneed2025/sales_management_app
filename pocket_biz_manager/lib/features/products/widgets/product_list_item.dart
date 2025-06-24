import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import '../models/product_model.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  // final VoidCallback onAdjustStock; // For later use

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onDelete,
    // required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_NA', symbol: 'N\$ '); // NAD currency

    return Card(
      child: ListTile(
        // leading: CircleAvatar( // Placeholder for product image later
        //   backgroundColor: product.isActive
        //                    ? theme.primaryColor.withAlpha(30)
        //                    : Colors.grey.withAlpha(30),
        //   child: Icon(
        //     Icons.inventory_2_outlined, // Generic product icon
        //     color: product.isActive ? theme.primaryColor : Colors.grey,
        //   ),
        // ),
        title: Text(
          product.productName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: product.isActive ? theme.textTheme.bodyLarge?.color : Colors.grey,
            decoration: product.isActive ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.sku != null && product.sku!.isNotEmpty)
              Text('SKU: ${product.sku}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              'Category: ${product.categoryName ?? 'N/A'}',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sell: ${currencyFormatter.format(product.salePrice)}',
                  style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.w500),
                ),
                Text(
                  'Stock: ${NumberFormat.decimalPattern().format(product.currentStock)} units',
                  style: TextStyle(
                    fontSize: 13,
                    color: product.currentStock <= product.minStockLevel && product.minStockLevel > 0
                           ? Colors.redAccent
                           : Colors.blueGrey[700],
                    fontWeight: product.currentStock <= product.minStockLevel && product.minStockLevel > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true, // To accommodate more subtitle content
        onTap: onTap,
        trailing: IconButton(
          icon: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error, size: 26),
          onPressed: onDelete,
          tooltip: 'Delete Product',
        ),
      ),
    );
  }
}
