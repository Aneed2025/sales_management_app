import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../models/sales_invoice_model.dart';
import '../models/invoice_installment_model.dart';
import '../models/sales_invoice_item_model.dart'; // Import the new model
import '../../../core/models/company_settings_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../../products/providers/product_provider.dart';
import '../../customers/providers/customer_provider.dart';

// SalesInvoiceItem class is now defined in sales_invoice_item_model.dart

class SalesProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  final List<SalesInvoice> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SalesInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final SettingsProvider _settingsProvider;
  final ProductProvider _productProvider;
  final CustomerProvider _customerProvider;

  SalesProvider({
    required SettingsProvider settingsProvider,
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
  })  : _settingsProvider = settingsProvider,
        _productProvider = productProvider,
        _customerProvider = customerProvider;

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
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
    required List<SalesInvoiceItem> items, // Now uses the imported SalesInvoiceItem
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

    SalesInvoice newInvoice = SalesInvoice(
      invoiceNumber: invoiceNumberString,
      invoiceDate: invoiceDate,
      customerID: customerId,
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
        newInvoice = newInvoice.copyWith(invoiceID: invoiceId);
        finalInvoice = newInvoice;

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
          finalInvoice = finalInvoice!.copyWith(installments: generatedInstallments);
        }
      });

      if (finalInvoice != null) {
        _invoices.add(finalInvoice!);
        notifyListeners();
      }
      _setLoading(false);
      return finalInvoice;

    } catch (e) {
      debugPrint("Error creating invoice in SalesProvider: $e");
      _setError("Failed to create invoice. ${e.toString()}");
      _setLoading(false);
      return null;
    }
  }
}
