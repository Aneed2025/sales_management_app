import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer_model.dart';
import './add_edit_customer_screen.dart';
import '../widgets/customer_list_item.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  static const routeName = '/customers';

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).fetchCustomers();
    });
  }

  void _navigateToAddEditScreen(BuildContext context, {Customer? customer}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditCustomerScreen(customer: customer),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CustomerProvider provider, Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete customer "${customer.customerName}"?\nThis action cannot be undone.'),
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
      final success = await provider.deleteCustomer(customer.customerID!);
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      final message = success
          ? 'Customer "${customer.customerName}" deleted.'
          : provider.errorMessage ?? 'Failed to delete customer. They might have existing invoices or an error occurred.';
      final bgColor = success ? Colors.green : theme.colorScheme.error;

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bgColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Customers'),
        // TODO: Add search functionality later
      ),
      body: Consumer<CustomerProvider>(
        builder: (ctx, customerProvider, child) {
          if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (customerProvider.errorMessage != null && customerProvider.customers.isEmpty) {
            return Center(child: Text(customerProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
          }
          if (customerProvider.customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No customers found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Customer'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => customerProvider.fetchCustomers(),
            child: ListView.builder(
              itemCount: customerProvider.customers.length,
              itemBuilder: (lCtx, index) {
                final customer = customerProvider.customers[index];
                return CustomerListItem(
                  customer: customer,
                  onTap: () => _navigateToAddEditScreen(context, customer: customer),
                  onDelete: () => _confirmDelete(context, customerProvider, customer),
                  // TODO: Add navigation to customer account statement screen
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Customer',
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}
