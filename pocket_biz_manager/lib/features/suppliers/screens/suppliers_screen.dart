import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';
import './add_edit_supplier_screen.dart';
import '../widgets/supplier_list_item.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  static const routeName = '/suppliers';

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplierProvider>(context, listen: false).fetchSuppliers();
    });
  }

  void _navigateToAddEditScreen(BuildContext context, {Supplier? supplier}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditSupplierScreen(supplier: supplier),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SupplierProvider provider, Supplier supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete supplier "${supplier.supplierName}"?\nThis action cannot be undone.'),
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
      final success = await provider.deleteSupplier(supplier.supplierID!);
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      final message = success
          ? 'Supplier "${supplier.supplierName}" deleted.'
          : provider.errorMessage ?? 'Failed to delete supplier. They might have existing bills or an error occurred.';
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
        title: const Text('Manage Suppliers'),
      ),
      body: Consumer<SupplierProvider>(
        builder: (ctx, supplierProvider, child) {
          if (supplierProvider.isLoading && supplierProvider.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (supplierProvider.errorMessage != null && supplierProvider.suppliers.isEmpty) {
            return Center(child: Text(supplierProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
          }
          if (supplierProvider.suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No suppliers found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Supplier'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => supplierProvider.fetchSuppliers(),
            child: ListView.builder(
              itemCount: supplierProvider.suppliers.length,
              itemBuilder: (lCtx, index) {
                final supplier = supplierProvider.suppliers[index];
                return SupplierListItem(
                  supplier: supplier,
                  onTap: () => _navigateToAddEditScreen(context, supplier: supplier),
                  onDelete: () => _confirmDelete(context, supplierProvider, supplier),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Supplier',
        child: const Icon(Icons.group_add_outlined),
      ),
    );
  }
}
