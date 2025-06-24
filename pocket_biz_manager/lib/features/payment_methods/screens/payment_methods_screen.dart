import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_method_provider.dart';
import '../models/payment_method_model.dart';
import 'add_edit_payment_method_screen.dart';
import '../widgets/payment_method_list_item.dart'; // Will create this widget

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  static const routeName = '/payment-methods'; // For navigation

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {

  void _navigateToAddEditScreen(BuildContext context, {PaymentMethod? method}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditPaymentMethodScreen(paymentMethod: method),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PaymentMethodProvider provider, PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete payment method "${method.methodName}"?\nThis action cannot be undone and might affect historical records if already used.'),
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
      final success = await provider.deletePaymentMethod(method.paymentMethodID!);
      if (mounted) {
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete "${method.methodName}". It might be in use or an error occurred.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment method "${method.methodName}" deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payment Methods'),
      ),
      body: Consumer<PaymentMethodProvider>(
        builder: (ctx, provider, child) {
          if (provider.isLoading && provider.paymentMethods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No payment methods found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Payment Method'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchPaymentMethods(),
            child: ListView.builder(
              itemCount: provider.paymentMethods.length,
              itemBuilder: (lCtx, index) {
                final method = provider.paymentMethods[index];
                return PaymentMethodListItem(
                  paymentMethod: method,
                  onTap: () => _navigateToAddEditScreen(context, method: method),
                  onDelete: () => _confirmDelete(context, provider, method),
                  onToggleActive: (value) async {
                    await provider.togglePaymentMethodStatus(method);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Payment Method',
        child: const Icon(Icons.add),
      ),
    );
  }
}
