import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import '../models/supplier_model.dart';

class SupplierListItem extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SupplierListItem({
    super.key,
    required this.supplier,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'en_NA', symbol: 'N\$ ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withAlpha(50),
          child: Text(
            supplier.supplierName.isNotEmpty ? supplier.supplierName[0].toUpperCase() : 'S',
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(supplier.supplierName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supplier.phone != null && supplier.phone!.isNotEmpty)
              Text(supplier.phone!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            Text(
              'Owed: ${currencyFormatter.format(supplier.balance)}', // "Owed" to supplier
              style: TextStyle(
                color: supplier.balance > 0 ? Colors.orange[700] : Colors.grey[800], // Orange if we owe them
                fontWeight: supplier.balance != 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              onTap();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Supplier')),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete_outline, color: theme.colorScheme.error), title: Text('Delete Supplier', style: TextStyle(color: theme.colorScheme.error))),
            ),
          ],
        ),
      ),
    );
  }
}
