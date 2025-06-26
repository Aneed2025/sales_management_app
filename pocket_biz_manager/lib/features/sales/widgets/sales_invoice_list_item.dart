import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_invoice_model.dart';

class SalesInvoiceListItem extends StatelessWidget {
  final SalesInvoice invoice;
  final VoidCallback onTap;
  // final VoidCallback onDelete; // Add later if needed directly on list item

  const SalesInvoiceListItem({
    super.key,
    required this.invoice,
    required this.onTap,
    // required this.onDelete,
  });

  String _getPaymentStatusText(String status) {
    // Can be expanded with more statuses later
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'partially paid':
        return 'Partially Paid';
      case 'unpaid':
        return 'Unpaid';
      case 'in collection':
        return 'In Collection';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green.shade700;
      case 'partially paid':
        return Colors.orange.shade700;
      case 'unpaid':
        return theme.colorScheme.error;
      case 'in collection':
        return Colors.purple.shade700;
      default:
        return theme.textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_NA', symbol: 'N\$ ');
    final dateFormatter = DateFormat.yMMMd(); // Example: Jan 1, 2023

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap, // onTap is passed from SalesInvoicesListScreen which will handle navigation
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                  ),
                  Text(
                    _getPaymentStatusText(invoice.paymentStatus),
                    style: TextStyle(
                      color: _getPaymentStatusColor(invoice.paymentStatus, context),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customer: ${invoice.customerName ?? 'N/A'}', // Display customer name
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${dateFormatter.format(invoice.invoiceDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Text(
                    'Total: ${currencyFormatter.format(invoice.totalAmount)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (invoice.isInstallment && invoice.numberOfInstallments != null && invoice.numberOfInstallments! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Installments: ${invoice.numberOfInstallments} (${invoice.balanceDue > 0 ? currencyFormatter.format(invoice.balanceDue) + " due" : "Cleared"})',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[700], fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
