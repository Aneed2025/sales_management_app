import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../models/sales_invoice_model.dart';
import '../models/invoice_installment_model.dart';
import '../models/sales_invoice_item_model.dart'; // Import the new model
import '../../products/providers/product_provider.dart';
import '../../products/models/product_model.dart';
import '../../customers/providers/customer_provider.dart'; // Assuming this will exist
import '../../customers/models/customer_model.dart';   // Assuming this will exist

class AddEditSalesInvoiceScreen extends StatefulWidget {
  final SalesInvoice? invoice; // For editing later

  const AddEditSalesInvoiceScreen({super.key, this.invoice});

  static const routeName = '/add-edit-sales-invoice';

  @override
  State<AddEditSalesInvoiceScreen> createState() => _AddEditSalesInvoiceScreenState();
}

class _AddEditSalesInvoiceScreenState extends State<AddEditSalesInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemsFormKey = GlobalKey<FormState>(); // For validating items before adding

  // Invoice Header Controllers
  DateTime _invoiceDate = DateTime.now();
  Customer? _selectedCustomer;
  final TextEditingController _customerSearchController = TextEditingController();
  List<Customer> _customerSearchResults = [];
  bool _showCustomerSearchResults = false;
  final FocusNode _customerSearchFocusNode = FocusNode();

  final TextEditingController _notesController = TextEditingController();

  // Items
  List<SalesInvoiceItem> _invoiceItems = [];
  Product? _selectedProductToAdd;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _unitPriceController = TextEditingController();

  // Installment Controllers & State
  bool _isInstallmentInvoice = false;
  final TextEditingController _numberOfInstallmentsController = TextEditingController();
  DateTime? _firstInstallmentDueDate;
  List<TextEditingController> _customInstallmentAmountControllers = [];
  List<InvoiceInstallment> _previewInstallments = [];

  bool _isLoading = false;

  // Currency Formatter
  final _currencyFormatter = NumberFormat.currency(locale: 'en_NA', symbol: 'N\$ ');
  final _numberFormatter = NumberFormat.decimalPattern();


  @override
  void initState() {
    super.initState();
    // TODO: Initialize form for editing if widget.invoice is not null
    // For now, focusing on adding a new invoice.

    // Fetch necessary data - ensure providers are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider.of<CustomerProvider>(context, listen: false).fetchCustomers(); // Example
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _numberOfInstallmentsController.dispose();
    for (var controller in _customInstallmentAmountControllers) {
      controller.dispose();
    }
    _customerSearchController.dispose();
    _customerSearchFocusNode.dispose();
    super.dispose();
  }

  double get _currentInvoiceTotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  void _addProductItem() {
    if (_selectedProductToAdd == null || !(_itemsFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? _selectedProductToAdd!.salePrice;

    setState(() {
      _invoiceItems.add(SalesInvoiceItem(
        productID: _selectedProductToAdd!.productID,
        productName: _selectedProductToAdd!.productName, // Store name for display ease
        quantity: quantity,
        unitPrice: unitPrice,
      ));
      _selectedProductToAdd = null;
      _quantityController.text = '1';
      _unitPriceController.clear();
      if (_isInstallmentInvoice) _generatePreviewInstallments(); // Re-calculate if total changed
    });
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  void _removeItem(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
       if (_isInstallmentInvoice) _generatePreviewInstallments(); // Re-calculate if total changed
    });
  }

  void _pickInvoiceDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _invoiceDate) {
      setState(() {
        _invoiceDate = pickedDate;
      });
    }
  }

  void _pickFirstInstallmentDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _firstInstallmentDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _invoiceDate, // Cannot be before invoice date
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _firstInstallmentDueDate = pickedDate;
        _generatePreviewInstallments();
      });
    }
  }

  void _generatePreviewInstallments() {
    if (!_isInstallmentInvoice || _numberOfInstallmentsController.text.isEmpty || _firstInstallmentDueDate == null) {
      setState(() => _previewInstallments = []);
      return;
    }
    final int numInstallments = int.tryParse(_numberOfInstallmentsController.text) ?? 0;
    if (numInstallments <= 0) {
      setState(() => _previewInstallments = []);
      return;
    }

    final double totalAmount = _currentInvoiceTotal;
    final double defaultInstallmentAmount = double.parse((totalAmount / numInstallments).toStringAsFixed(2));

    // Dispose old controllers
    for (var controller in _customInstallmentAmountControllers) {
      controller.dispose();
    }
    _customInstallmentAmountControllers = List.generate(numInstallments, (_) => TextEditingController());

    List<InvoiceInstallment> newPreview = [];
    double remainingAmount = totalAmount;

    for (int i = 0; i < numInstallments; i++) {
      DateTime dueDate;
      if (i == 0) {
        dueDate = _firstInstallmentDueDate!;
      } else {
        DateTime prevDueDate = newPreview.last.dueDate;
        dueDate = DateTime(prevDueDate.year, prevDueDate.month + 1, prevDueDate.day);
        if (dueDate.month != (prevDueDate.month + 1) % 12 && (prevDueDate.month + 1) != 12) {
            dueDate = DateTime(prevDueDate.year, prevDueDate.month + 2, 0);
        }
      }

      double currentInstallmentAmount;
      // Use custom amount if available and valid, otherwise default/remaining
      // For now, just use default or remaining for preview simplicity. Custom edit will be separate.
      if (i == numInstallments - 1) { // Last installment takes remainder
        currentInstallmentAmount = remainingAmount;
      } else {
        currentInstallmentAmount = defaultInstallmentAmount;
      }
      currentInstallmentAmount = double.parse(currentInstallmentAmount.toStringAsFixed(2));

      _customInstallmentAmountControllers[i].text = currentInstallmentAmount.toStringAsFixed(2);
      remainingAmount -= currentInstallmentAmount;
      remainingAmount = double.parse(remainingAmount.toStringAsFixed(2));


      newPreview.add(InvoiceInstallment(
        invoiceID: 0, // Placeholder
        installmentNumber: i + 1,
        dueDate: dueDate,
        amountDue: currentInstallmentAmount,
      ));
    }
    setState(() => _previewInstallments = newPreview);
  }

  void _updateInstallmentAmount(int index, String value) {
    // This is where validation for sum of custom amounts would go
    // For simplicity, just updating the preview for now
    final double? newAmount = double.tryParse(value);
    if (newAmount != null && index < _previewInstallments.length) {
      setState(() {
        _previewInstallments[index] = _previewInstallments[index].copyWith(amountDue: newAmount);
        // Potentially re-distribute remaining amounts or show validation error if sum doesn't match
      });
    }
  }


  Future<void> _saveInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the invoice.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }
    // TODO: Proper customer selection
    if (_selectedCustomer == null) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a customer.'), backgroundColor: Colors.orangeAccent),
        );
        return;
    }

    if (_isInstallmentInvoice) {
        if (_numberOfInstallmentsController.text.isEmpty || (int.tryParse(_numberOfInstallmentsController.text) ?? 0) <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Number of installments is required.'), backgroundColor: Colors.orangeAccent));
            return;
        }
        if (_firstInstallmentDueDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First installment due date is required.'), backgroundColor: Colors.orangeAccent));
            return;
        }
        // Validate sum of custom installment amounts
        final double totalFromCustomInstallments = _customInstallmentAmountControllers.fold(0.0, (sum, ctrl) => sum + (double.tryParse(ctrl.text) ?? 0.0) );
        if (totalFromCustomInstallments.toStringAsFixed(2) != _currentInvoiceTotal.toStringAsFixed(2)) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sum of installment amounts (${_currencyFormatter.format(totalFromCustomInstallments)}) must match invoice total (${_currencyFormatter.format(_currentInvoiceTotal)}).'), backgroundColor: Colors.orangeAccent),
            );
            return;
        }
    }


    setState(() => _isLoading = true);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    List<double>? customAmounts = _isInstallmentInvoice
        ? _customInstallmentAmountControllers.map((ctrl) => double.tryParse(ctrl.text) ?? 0.0).toList()
        : null;

    final newInvoice = await salesProvider.createInvoice(
      customerId: _selectedCustomer!.customerID!, // Ensure customer is selected
      invoiceDate: _invoiceDate,
      items: _invoiceItems,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isInstallment: _isInstallmentInvoice,
      numberOfInstallments: _isInstallmentInvoice ? int.parse(_numberOfInstallmentsController.text) : null,
      firstInstallmentDueDate: _isInstallmentInvoice ? _firstInstallmentDueDate : null,
      customInstallmentAmounts: customAmounts,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (newInvoice != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice ${newInvoice.invoiceNumber} created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(salesProvider.errorMessage ?? 'Failed to create invoice.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false); // No need to listen for product list changes here usually
    final customerProvider = Provider.of<CustomerProvider>(context); // Listen for customer list

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Create New Sales Invoice' : 'Edit Sales Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _isLoading ? null : _saveInvoice,
            tooltip: 'Save Invoice',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer and Date Section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Invoice Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            // Customer Search and Selection
                            _buildCustomerSearchField(customerProvider),
                            if (_selectedCustomer != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                child: Chip(
                                  label: Text(_selectedCustomer!.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  avatar: CircleAvatar(child: Text(_selectedCustomer!.customerName[0])),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedCustomer = null;
                                      _customerSearchController.clear();
                                      _customerSearchResults = [];
                                      _showCustomerSearchResults = false;
                                    });
                                  },
                                ),
                              ),
                            if (_selectedCustomer == null && _customerSearchController.text.isNotEmpty && !_showCustomerSearchResults && !_isLoading)
                                Padding(
                                  padding: const EdgeInsets.only(top:8.0),
                                  child: Text('No customer selected. Search or add new.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                ),
                            const SizedBox(height: 12),
                            ListTile(
                              title: Text('Invoice Date: ${DateFormat.yMMMd().format(_invoiceDate)}'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _pickInvoiceDate,
                            ),
                             TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note_alt_outlined)),
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Item Section
                    _buildAddItemSection(productProvider),
                    const SizedBox(height: 8),

                    // Items List
                    _buildInvoiceItemsList(),
                    const SizedBox(height: 16),

                    // Installment Section
                    _buildInstallmentSection(),
                    const SizedBox(height: 16),

                    // Total Amount Display
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Total Amount: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          Text(_currencyFormatter.format(_currentInvoiceTotal), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60), // For FAB
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveInvoice,
        icon: const Icon(Icons.save),
        label: const Text('Save Invoice'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAddItemSection(ProductProvider productProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _itemsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Product Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<Product>(
                value: _selectedProductToAdd,
                decoration: const InputDecoration(labelText: 'Product*', border: OutlineInputBorder()),
                items: productProvider.products.where((p) => p.isActive).map((Product product) {
                  return DropdownMenuItem<Product>(
                    value: product,
                    child: Text("${product.productName} (${_currencyFormatter.format(product.salePrice)})"),
                  );
                }).toList(),
                onChanged: (Product? newValue) {
                  setState(() {
                    _selectedProductToAdd = newValue;
                    _unitPriceController.text = newValue?.salePrice.toStringAsFixed(2) ?? '';
                  });
                },
                validator: (value) => value == null ? 'Select a product' : null,
                isExpanded: true,
                hint: productProvider.isLoading ? const Text("Loading...") : const Text("Select Product"),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity*', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Req.';
                        if ((double.tryParse(value) ?? 0) <= 0) return '>0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _unitPriceController,
                      decoration: const InputDecoration(labelText: 'Unit Price (NAD)*', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                       validator: (value) {
                        if (value == null || value.isEmpty) return 'Req.';
                        if ((double.tryParse(value) ?? -1) < 0) return '>=0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('Add Item'),
                  onPressed: _addProductItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceItemsList() {
    if (_invoiceItems.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No items added yet.', style: TextStyle(fontStyle: FontStyle.italic)),
      ));
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Invoice Items (${_invoiceItems.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoiceItems.length,
              itemBuilder: (ctx, index) {
                final item = _invoiceItems[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(child: Text((index + 1).toString())),
                  title: Text(item.productName),
                  subtitle: Text('${_numberFormatter.format(item.quantity)} x ${_currencyFormatter.format(item.unitPrice)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_currencyFormatter.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                        onPressed: () => _removeItem(index),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (ctx, index) => const Divider(height: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Create Installment Plan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              value: _isInstallmentInvoice,
              onChanged: (bool value) {
                setState(() {
                  _isInstallmentInvoice = value;
                  if (!_isInstallmentInvoice) {
                    _previewInstallments = [];
                    for (var ctrl in _customInstallmentAmountControllers) {ctrl.dispose();}
                    _customInstallmentAmountControllers = [];
                    _numberOfInstallmentsController.clear();
                    _firstInstallmentDueDate = null;
                  } else {
                     _generatePreviewInstallments(); // Attempt to generate if details are present
                  }
                });
              },
              activeColor: Theme.of(context).primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            if (_isInstallmentInvoice) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _numberOfInstallmentsController,
                decoration: const InputDecoration(labelText: 'Number of Installments*', border: OutlineInputBorder(), prefixIcon: Icon(Icons.format_list_numbered)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_isInstallmentInvoice && (value == null || value.isEmpty || (int.tryParse(value) ?? 0) <= 0)) {
                    return 'Enter a valid number (>0)';
                  }
                  return null;
                },
                onChanged: (value) => _generatePreviewInstallments(),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('First Due Date*: ${ _firstInstallmentDueDate == null ? 'Not Set' : DateFormat.yMMMd().format(_firstInstallmentDueDate!)}'),
                trailing: const Icon(Icons.calendar_month_outlined),
                onTap: _pickFirstInstallmentDueDate,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Theme.of(context).inputDecorationTheme.border?.borderSide.color ?? Colors.grey)),
              ),
              const SizedBox(height: 12),
              if (_previewInstallments.isNotEmpty) ...[
                const Text('Installment Schedule Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _previewInstallments.length,
                  itemBuilder: (ctx, index) {
                    final inst = _previewInstallments[index];
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 15, child: Text(inst.installmentNumber.toString())),
                        title: Text('Due: ${DateFormat.yMMMd().format(inst.dueDate)}'),
                        trailing: SizedBox(
                          width: 120, // Adjust width as needed
                          child: TextFormField(
                            controller: _customInstallmentAmountControllers[index],
                            textAlign: TextAlign.end,
                            decoration: InputDecoration(
                              prefixText: 'N\$ ',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                            onChanged: (value) => _updateInstallmentAmount(index, value),
                             validator: (value) {
                                if (value == null || value.isEmpty || (double.tryParse(value) ?? -1) < 0) return 'Invalid';
                                return null;
                              },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Total of Previewed Installments: ${_currencyFormatter.format(_customInstallmentAmountControllers.fold(0.0, (sum, ctrl) => sum + (double.tryParse(ctrl.text) ?? 0.0)))}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                )
              ]
            ]
          ],
        ),
      ),
    );
  }
}
