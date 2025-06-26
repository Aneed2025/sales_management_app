import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../models/sales_invoice_model.dart';
import '../models/invoice_installment_model.dart';
import '../models/sales_invoice_item_model.dart';
import '../../../core/models/company_settings_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../customers/providers/customer_provider.dart';

class SalesProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  final List<SalesInvoice> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SalesInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SalesInvoice? _selectedDetailedInvoice;
  SalesInvoice? get selectedDetailedInvoice => _selectedDetailedInvoice;
  bool _isLoadingInvoiceDetails = false;
  bool get isLoadingInvoiceDetails => _isLoadingInvoiceDetails;

  final SettingsProvider _settingsProvider;
  final ProductProvider _productProvider;
  final CustomerProvider _customerProvider;

  SalesProvider({
    required SettingsProvider settingsProvider,
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
  })  : _settingsProvider = settingsProvider,
        _productProvider = productProvider,
        _customerProvider = customerProvider {
    fetchInvoices(); // Load invoices when provider is created
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> fetchInvoices() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllSalesInvoicesWithCustomerName();
      _invoices = maps.map((map) {
        // The SalesInvoice.fromMap should handle the CustomerName field if present from the JOIN
        return SalesInvoice.fromMap(map);
      }).toList();
    } catch (e) {
      debugPrint("Error fetching sales invoices: $e");
      _setError("Failed to load sales invoices.");
      _invoices = [];
    }
    _setLoading(false);
  }


  Future<String> _generateNextInvoiceNumber() async {
    CompanySettings? settings = _settingsProvider.currentSettings;
    if (settings == null) {
      await _settingsProvider.loadSettings();
      settings = _settingsProvider.currentSettings;
      if (settings == null) {
        _setError("Company settings not available. Cannot generate invoice number.");
        return "ERR-NO-SETTINGS-${DateTime.now().millisecondsSinceEpoch}";
      }
    }

    String prefix = settings.invoicePrefix?.trim() ?? "INV";
    if (prefix.isEmpty) {
      prefix = "INV";
      debugPrint("Invoice prefix is empty in settings, using default 'INV'.");
    }

    int nextSequence = (settings.lastInvoiceSequence ?? 0) + 1;
    String sequencePart = nextSequence.toString().padLeft(5, '0');

    return '${prefix.toUpperCase()}-$sequencePart';
  }

  Future<void> _updateNextInvoiceSequence(String prefix, int newSequence, DatabaseExecutor txn) async {
     await txn.update(
      'Company_Settings',
      {'LastInvoiceSequence': newSequence},
      where: 'SettingID = ?',
      whereArgs: [1],
    );
    _settingsProvider.updateLocalLastInvoiceSequence(newSequence, prefix);
  }

  Future<SalesInvoice?> createInvoice({
    required int customerId,
    required DateTime invoiceDate,
    required List<SalesInvoiceItem> items,
    String? notes,
    bool isInstallment = false,
    int? numberOfInstallments,
    DateTime? firstInstallmentDueDate,
    List<double>? customInstallmentAmounts,
  }) async {
    _setLoading(true);

    if (items.isEmpty) {
      _setError("Cannot create an invoice with no items.");
      _setLoading(false);
      return null;
    }

    if (isInstallment && (numberOfInstallments == null || numberOfInstallments <= 0 || firstInstallmentDueDate == null)) {
      _setError("Number of installments and first due date are required for installment invoices.");
      _setLoading(false);
      return null;
    }

    if (isInstallment && customInstallmentAmounts != null && customInstallmentAmounts.length != numberOfInstallments) {
        _setError("Custom installment amounts count does not match number of installments.");
        _setLoading(false);
        return null;
    }

    double totalAmount = items.fold(0.0, (sum, item) => sum + item.lineTotal);

    if (isInstallment && customInstallmentAmounts != null) {
        double sumOfCustomInstallments = customInstallmentAmounts.fold(0.0, (sum, amount) => sum + amount);
        if (sumOfCustomInstallments.toStringAsFixed(2) != totalAmount.toStringAsFixed(2)) {
            _setError("Sum of custom installment amounts (${sumOfCustomInstallments.toStringAsFixed(2)}) must equal total invoice amount (${totalAmount.toStringAsFixed(2)}).");
            _setLoading(false);
            return null;
        }
    }

    final String invoiceNumberString = await _generateNextInvoiceNumber();
    if (invoiceNumberString.startsWith("ERR-NO-SETTINGS")) {
      _setLoading(false);
      return null;
    }

    // Fetch customer name for the new invoice object (not stored in DB table directly)
    // This assumes CustomerProvider is up-to-date or can fetch quickly.
    // Alternatively, pass customerName to createInvoice if readily available in UI.
    String customerName = '';
    final customer = _customerProvider.getCustomerById(customerId);
    if (customer != null) {
      customerName = customer.customerName;
    } else {
      // Fallback: try to fetch from DB if not in provider's cache (should ideally be pre-loaded)
      final custMap = await _dbService.getCustomerById(customerId);
      if (custMap != null) customerName = custMap['CustomerName'] as String? ?? 'Unknown';
    }


    SalesInvoice newInvoice = SalesInvoice(
      invoiceNumber: invoiceNumberString,
      invoiceDate: invoiceDate,
      customerID: customerId,
      // customerName: customerName, // Add customerName to the model for display
      totalAmount: totalAmount,
      amountPaid: 0.0,
      paymentStatus: 'Unpaid',
      notes: notes,
      isInstallment: isInstallment,
      numberOfInstallments: isInstallment ? numberOfInstallments : null,
      defaultInstallmentAmount: isInstallment ? (totalAmount / numberOfInstallments!) : null,
      installments: [],
    );

    final db = await _dbService.database;
    try {
      SalesInvoice? finalInvoice;
      await db.transaction((txn) async {
        final invoiceId = await txn.insert('Sales_Invoices', newInvoice.toMap());

        // Create a new SalesInvoice instance that includes the customerName for the provider's list
        // The customerName is not part of the toMap() for DB persistence in Sales_Invoices table.
        finalInvoice = newInvoice.copyWith(
          invoiceID: invoiceId,
          // customerName: customerName // Ensure customerName is part of the object added to _invoices list
        );


        final parts = invoiceNumberString.split('-');
        if (parts.length >= 2) {
            final currentSequence = int.tryParse(parts.last);
            final currentPrefix = parts.sublist(0, parts.length -1).join('-');
            if (currentSequence != null) {
                 await _updateNextInvoiceSequence(currentPrefix, currentSequence, txn);
            } else {
                debugPrint("Error: Could not parse sequence from invoice number for settings update.");
            }
        }

        for (var item in items) {
          if (item.productID == null) {
            throw Exception("Product ID is null for item: ${item.productName}. Cannot process sale.");
          }
          await txn.insert('Sales_Invoice_Items', item.toMap(invoiceId));

          bool stockUpdated = await _productProvider.sellProduct(
            item.productID!,
            item.quantity,
            invoiceId,
            "SalesInvoice",
            txn: txn
          );
          if (!stockUpdated) {
            throw Exception("Failed to update stock for product: ${item.productName}. ${_productProvider.errorMessage ?? ''}");
          }
        }

        bool balanceUpdated = await _customerProvider.updateCustomerBalance(
          customerId,
          totalAmount,
          txn: txn
        );
        if (!balanceUpdated) {
          throw Exception("Failed to update customer balance. ${_customerProvider.errorMessage ?? ''}");
        }

        if (newInvoice.isInstallment) {
          List<InvoiceInstallment> generatedInstallments = [];
          double remainingAmount = newInvoice.totalAmount;

          for (int i = 0; i < newInvoice.numberOfInstallments!; i++) {
            DateTime dueDate;
            if (i == 0) {
              dueDate = firstInstallmentDueDate!;
            } else {
              DateTime prevDueDate = generatedInstallments.last.dueDate;
              dueDate = DateTime(prevDueDate.year, prevDueDate.month + 1, prevDueDate.day);
              if (dueDate.month != (prevDueDate.month + 1) % 12 && (prevDueDate.month + 1) != 12) {
                  dueDate = DateTime(prevDueDate.year, prevDueDate.month + 2, 0);
              }
            }

            double installmentAmount;
            if (customInstallmentAmounts != null && i < customInstallmentAmounts.length) {
                installmentAmount = customInstallmentAmounts[i];
            } else {
                installmentAmount = (i == newInvoice.numberOfInstallments! - 1)
                                  ? remainingAmount
                                  : (newInvoice.defaultInstallmentAmount ?? (newInvoice.totalAmount / newInvoice.numberOfInstallments!));
                installmentAmount = double.parse(installmentAmount.toStringAsFixed(2));
            }
            remainingAmount -= installmentAmount;
            remainingAmount = double.parse(remainingAmount.toStringAsFixed(2));

            InvoiceInstallment installment = InvoiceInstallment(
              invoiceID: invoiceId,
              installmentNumber: i + 1,
              dueDate: dueDate,
              amountDue: installmentAmount,
            );
            final installmentId = await txn.insert('Invoice_Installments', installment.toMap());
            generatedInstallments.add(installment.copyWith(installmentID: installmentId));
          }
          // Update finalInvoice with the generated installments.
          // The SalesInvoice model has 'installments' list, but it's not persisted in Sales_Invoices table.
          // It's for the provider's local cache or for fetching details later.
          finalInvoice = finalInvoice!.copyWith(installments: generatedInstallments);
        }
      });

      if (finalInvoice != null) {
        // The finalInvoice object should now have customerName if it was fetched and set before saving newInvoice.
        // However, newInvoice (and thus finalInvoice before copyWith) doesn't have customerName set during its initial construction
        // because customerName is not a DB field for Sales_Invoices table.
        // The customerName is primarily for display when fetching joined data.
        // For the object added to the local _invoices list immediately after creation,
        // we need to ensure it has the customerName.
        SalesInvoice invoiceToList = finalInvoice!.copyWith(customerName: customerName);

        _invoices.add(invoiceToList);
        _invoices.sort((a,b) => b.invoiceDate.compareTo(a.invoiceDate)); // Sort after adding
        notifyListeners();
      }
      _setLoading(false);
      return finalInvoice; // This will not have customerName unless SalesInvoice.copyWith inside transaction also adds it.
                           // For consistency, the object returned should be the same as what's added to list.
                           // So, perhaps return 'invoiceToList' or ensure 'finalInvoice' gets it.
                           // Let's make finalInvoice get it right after its ID is set.

    } catch (e) {
      debugPrint("Error creating invoice in SalesProvider: $e");
      _setError("Failed to create invoice. ${e.toString()}");
      _setLoading(false);
      return null;
    }
  }

  Future<SalesInvoice?> fetchInvoiceDetails(int invoiceId) async {
    _isLoadingInvoiceDetails = true;
    _selectedDetailedInvoice = null; // Clear previous
    notifyListeners(); // Notify UI that loading has started

    try {
      final Map<String, dynamic>? invoiceData = await _dbService.getSalesInvoiceByIdWithDetails(invoiceId);

      if (invoiceData != null) {
        // Base invoice object from the main part of invoiceData
        SalesInvoice invoice = SalesInvoice.fromMap(invoiceData);

        // Populate items
        if (invoiceData['items'] != null && invoiceData['items'] is List) {
          invoice.items = (invoiceData['items'] as List)
              .map((itemMap) => SalesInvoiceItem.fromMap(itemMap as Map<String, dynamic>))
              .toList();
        }

        // Populate installments
        if (invoiceData['installments'] != null && invoiceData['installments'] is List) {
          invoice.installments = (invoiceData['installments'] as List)
              .map((instMap) => InvoiceInstallment.fromMap(instMap as Map<String, dynamic>))
              .toList();
        }

        // Populate payments
        if (invoiceData['payments'] != null && invoiceData['payments'] is List) {
          invoice.payments = (invoiceData['payments'] as List)
              .map((payMap) => SalesPayment.fromMap(payMap as Map<String, dynamic>))
              .toList();
        }

        _selectedDetailedInvoice = invoice;
        _isLoadingInvoiceDetails = false;
        notifyListeners();
        return _selectedDetailedInvoice;
      } else {
        _setError("Invoice details not found for ID: $invoiceId");
        _isLoadingInvoiceDetails = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching invoice details for $invoiceId: $e");
      _setError("Failed to load details for invoice ID: $invoiceId. ${e.toString()}");
      _isLoadingInvoiceDetails = false;
      notifyListeners();
      return null;
    }
  }
}
