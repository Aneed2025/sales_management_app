import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../models/sales_invoice_model.dart';
import '../models/sales_invoice_item_model.dart';
import '../models/invoice_installment_model.dart';
import '../models/sales_payment_model.dart';
// import './record_sales_payment_screen.dart'; // For navigation later
// import './add_edit_sales_invoice_screen.dart'; // For navigation to edit later

class SalesInvoiceDetailScreen extends StatefulWidget {
  const SalesInvoiceDetailScreen({super.key});

  static const routeName = '/sales-invoice-detail';

  @override
  State<SalesInvoiceDetailScreen> createState() => _SalesInvoiceDetailScreenState();
}

class _SalesInvoiceDetailScreenState extends State<SalesInvoiceDetailScreen> {
  late int _invoiceId;
  bool _isDataFetched = false;

  final _currencyFormatter = NumberFormat.currency(locale: 'en_NA', symbol: 'N\$ ');
  final _dateFormatter = DateFormat.yMMMd();
  final _dateTimeFormatter = DateFormat.yMMMd().add_jm();


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataFetched) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is int) {
        _invoiceId = arguments;
        // Use addPostFrameCallback to ensure provider is available after build phase
        // and to avoid calling setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Check if the widget is still in the tree
            Provider.of<SalesProvider>(context, listen: false).fetchInvoiceDetails(_invoiceId);
          }
        });
      } else {
        // Handle error or unexpected argument type if necessary
        debugPrint("SalesInvoiceDetailScreen: Received unexpected arguments type or null.");
        // Optionally, navigate back or show an error message.
      }
      _isDataFetched = true;
    }
  }

  Color _getPaymentStatusColor(String? status, BuildContext context) {
    final theme = Theme.of(context);
    if (status == null) return Colors.grey;
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

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isEmphasized = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 15, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final SalesInvoice? invoice = salesProvider.selectedDetailedInvoice;
    final bool isLoading = salesProvider.isLoadingInvoiceDetails;

    if (isLoading && invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Invoice...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(salesProvider.errorMessage ?? 'Invoice not found or failed to load.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice: ${invoice.invoiceNumber}'),
        actions: [
          // TODO: Add Edit/Delete/Print actions based on invoice status
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // Navigator.of(context).pushNamed(AddEditSalesInvoiceScreen.routeName, arguments: invoice);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit action tapped (not implemented yet).')));
              } else if (value == 'send_to_collection') {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Send to Collection action tapped (not implemented yet).')));
              } else if (value == 'pdf') {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generate PDF action tapped (not implemented yet).')));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit Invoice'))),
              if(!invoice.isInCollection)
                 const PopupMenuItem<String>(value: 'send_to_collection', child: ListTile(leading: Icon(Icons.assignment_ind_outlined), title: Text('Send to Collection'))),
              const PopupMenuItem<String>(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf_outlined), title: Text('Generate PDF'))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => salesProvider.fetchInvoiceDetails(_invoiceId),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Invoice Header ---
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Invoice Summary', context),
                      _buildDetailRow('Customer', invoice.customerName ?? 'N/A'),
                      _buildDetailRow('Date', _dateFormatter.format(invoice.invoiceDate)),
                      _buildDetailRow('Status', invoice.paymentStatus, isEmphasized: true, valueColor: _getPaymentStatusColor(invoice.paymentStatus, context)),
                      const Divider(),
                      _buildDetailRow('Total Amount', _currencyFormatter.format(invoice.totalAmount), isEmphasized: true),
                      _buildDetailRow('Amount Paid', _currencyFormatter.format(invoice.amountPaid), valueColor: Colors.green.shade700),
                      _buildDetailRow('Balance Due', _currencyFormatter.format(invoice.balanceDue), isEmphasized: true, valueColor: invoice.balanceDue > 0 ? Theme.of(context).colorScheme.error : Colors.black),
                      if(invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                        const Divider(),
                        _buildDetailRow('Notes', invoice.notes!),
                      ],
                       if(invoice.isInCollection) ...[
                        const Divider(),
                        Text('In Collection', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold)),
                        if(invoice.collectionAgencyName != null)
                           _buildDetailRow('Agency', invoice.collectionAgencyName!),
                        if(invoice.collectionAgencyContact != null)
                           _buildDetailRow('Agency Contact', invoice.collectionAgencyContact!),
                        if(invoice.dateSentToCollection != null)
                           _buildDetailRow('Sent on', _dateFormatter.format(invoice.dateSentToCollection!)),
                      ]
                    ],
                  ),
                ),
              ),

              // --- Items ---
              _buildSectionTitle('Items (${invoice.items.length})', context),
              Card(
                elevation: 2,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invoice.items.length,
                  itemBuilder: (ctx, index) {
                    final item = invoice.items[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(child: Text((index + 1).toString())),
                      title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${_numberFormatter.format(item.quantity)} x ${_currencyFormatter.format(item.unitPrice)}'),
                      trailing: Text(_currencyFormatter.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                  separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                ),
              ),

              // --- Installments (if any) ---
              if (invoice.isInstallment && invoice.installments.isNotEmpty) ...[
                _buildSectionTitle('Installment Plan (${invoice.installments.length})', context),
                Card(
                  elevation: 2,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.installments.length,
                    itemBuilder: (ctx, index) {
                      final inst = invoice.installments[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: inst.status == 'Paid' ? Colors.green[100] : (inst.status == 'Partially Paid' ? Colors.orange[100] : Colors.grey[200]),
                          child: Text(inst.installmentNumber.toString(), style: TextStyle(color: inst.status == 'Paid' ? Colors.green[800] : Colors.black54, fontSize: 12)),
                        ),
                        title: Text('Due: ${_dateFormatter.format(inst.dueDate)} - Amount: ${_currencyFormatter.format(inst.amountDue)}'),
                        subtitle: Text('Paid: ${_currencyFormatter.format(inst.amountPaid)} - Status: ${inst.status}'),
                        trailing: inst.status != 'Paid' ? const Icon(Icons.hourglass_empty_outlined, color: Colors.orangeAccent) : const Icon(Icons.check_circle_outline, color: Colors.green),
                      );
                    },
                    separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                ),
              ],

              // --- Payments (if any) ---
              if (invoice.payments.isNotEmpty) ...[
                _buildSectionTitle('Payments Received (${invoice.payments.length})', context),
                Card(
                  elevation: 2,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoice.payments.length,
                    itemBuilder: (ctx, index) {
                      final payment = invoice.payments[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(payment.collectedByAgency ? Icons.support_agent_outlined : Icons.payment_outlined, color: Theme.of(context).primaryColor),
                        title: Text('${_currencyFormatter.format(payment.amount)} via ${payment.paymentMethodName ?? 'N/A'}'),
                        subtitle: Text('On: ${_dateTimeFormatter.format(payment.paymentDate)}${payment.collectedByAgency ? " (By Agency)" : ""}'),
                        // trailing: Text(payment.notes ?? ''), // Optional notes
                      );
                    },
                    separatorBuilder: (ctx, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                ),
              ],
              const SizedBox(height: 70), // Space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.payment_outlined),
        label: const Text('Record Payment'),
        onPressed: () {
          // Navigator.of(context).pushNamed(RecordSalesPaymentScreen.routeName, arguments: invoice.invoiceID);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record Payment action tapped (not implemented yet).')));
        },
      ),
       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
