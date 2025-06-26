import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../models/sales_invoice_model.dart';
import './add_edit_sales_invoice_screen.dart';
import '../widgets/sales_invoice_list_item.dart';
// import './sales_invoice_detail_screen.dart'; // For navigation to detail screen later

class SalesInvoicesListScreen extends StatefulWidget {
  const SalesInvoicesListScreen({super.key});

  static const routeName = '/sales-invoices';

  @override
  State<SalesInvoicesListScreen> createState() => _SalesInvoicesListScreenState();
}

class _SalesInvoicesListScreenState extends State<SalesInvoicesListScreen> {
  @override
  void initState() {
    super.initState();
    // Data is fetched when SalesProvider is initialized.
    // We can add a pull-to-refresh or a button if explicit refresh is needed beyond that.
    // Or, if navigating back to this screen, we might want to re-fetch.
    // For now, relying on initial fetch and RefreshIndicator.
  }

  void _navigateToAddInvoiceScreen(BuildContext context) {
    Navigator.of(context).pushNamed(AddEditSalesInvoiceScreen.routeName);
  }

  void _navigateToDetailScreen(BuildContext context, SalesInvoice invoice) {
    Navigator.of(context).pushNamed(SalesInvoiceDetailScreen.routeName, arguments: invoice.invoiceID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices'),
        // TODO: Add search/filter actions later
      ),
      body: Consumer<SalesProvider>(
        builder: (ctx, salesProvider, child) {
          if (salesProvider.isLoading && salesProvider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (salesProvider.errorMessage != null && salesProvider.invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(salesProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16)),
                  const SizedBox(height:10),
                  ElevatedButton(onPressed: () => salesProvider.fetchInvoices(), child: const Text("Retry Fetch")),
                ],
              )
            );
          }
          if (salesProvider.invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No sales invoices found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create First Invoice'),
                    onPressed: () => _navigateToAddInvoiceScreen(context),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => salesProvider.fetchInvoices(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: salesProvider.invoices.length,
              itemBuilder: (lCtx, index) {
                final invoice = salesProvider.invoices[index];
                return SalesInvoiceListItem(
                  invoice: invoice,
                  onTap: () => _navigateToDetailScreen(context, invoice),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddInvoiceScreen(context),
        tooltip: 'New Sales Invoice',
        child: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }
}
