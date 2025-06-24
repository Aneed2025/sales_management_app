import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import '../models/customer_model.dart';

class CustomerListItem extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  // final VoidCallback onViewStatement; // For future navigation to account statement

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
    // required this.onViewStatement,
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
            customer.customerName.isNotEmpty ? customer.customerName[0].toUpperCase() : 'C',
            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(customer.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Text(customer.phone!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            Text(
              'Balance: ${currencyFormatter.format(customer.balance)}',
              style: TextStyle(
                color: customer.balance > 0 ? theme.colorScheme.error : (customer.balance < 0 ? Colors.green[700] : Colors.grey[800]),
                fontWeight: customer.balance != 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        onTap: onTap, // For editing
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              onTap();
            } else if (value == 'delete') {
              onDelete();
            }
            // else if (value == 'statement') {
            //   onViewStatement();
            // }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Customer')),
            ),
            // const PopupMenuItem<String>(
            //   value: 'statement',
            //   child: ListTile(leading: Icon(Icons.receipt_long_outlined), title: Text('View Statement')),
            // ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(leading: Icon(Icons.delete_outline, color: theme.colorScheme.error), title: Text('Delete Customer', style: TextStyle(color: theme.colorScheme.error))),
            ),
          ],
        ),
      ),
    );
  }
}
