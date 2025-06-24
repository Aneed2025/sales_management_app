import 'package:flutter/foundation.dart';
import '../../../core/database/database_service.dart';
import '../models/sales_invoice_model.dart';
import '../models/invoice_installment_model.dart';
// import '../../products/models/product_model.dart'; // product_model.dart is not used directly in this file now
import '../../../core/models/company_settings_model.dart'; // For CompanySettings
import '../../settings/providers/settings_provider.dart'; // To access settings

// Placeholder for SalesInvoiceItem, to be properly defined
class SalesInvoiceItem {
  final int? productID;
  final String productName; // Or fetch from Product model
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  SalesInvoiceItem({
    this.productID,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  }) : lineTotal = quantity * unitPrice;

  Map<String, dynamic> toMap(int invoiceID) {
    return {
      'InvoiceID': invoiceID,
      'ProductID': productID,
      // 'ProductName': productName, // Not stored in DB table directly, ProductID is FK
      'Quantity': quantity,
      'UnitPrice': unitPrice,
      'LineTotal': lineTotal,
    };
  }
}

class SalesProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<SalesInvoice> _invoices = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SalesInvoice> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final SettingsProvider _settingsProvider;

  SalesProvider(this._settingsProvider) {
    // Initial fetch of invoices can be done here if needed
    // fetchInvoices();
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

  Future<String> _generateNextInvoiceNumber() async {
    // This is a simplified version. In a real app, you might query the DB
    // for the last invoice number and increment it, or use a more robust system.
    // For example: SELECT MAX(InvoiceNumber) FROM Sales_Invoices and parse it.
    // Or have a separate table/setting for last used invoice number.
    CompanySettings? settings = _settingsProvider.currentSettings;
    if (settings == null) {
      // Attempt to load settings if not already loaded. This is a fallback.
      // Ideally, SettingsProvider should be loaded when the app starts.
      await _settingsProvider.loadSettings();
      settings = _settingsProvider.currentSettings;
      if (settings == null) {
        _setError("Company settings not available. Cannot generate invoice number.");
        // Return a temporary or error-indicating number, or throw an exception
        return "ERR-NO-SETTINGS-${DateTime.now().millisecondsSinceEpoch}";
      }
    }

    String prefix = settings.invoicePrefix?.trim() ?? "INV";
    if (prefix.isEmpty) {
      prefix = "INV";
      debugPrint("Invoice prefix is empty in settings, using default 'INV'.");
    }

    int nextSequence = (settings.lastInvoiceSequence ?? 0) + 1;
    String sequencePart = nextSequence.toString().padLeft(5, '0'); // 5 digits sequence XXXXX

    return '${prefix.toUpperCase()}-$sequencePart';
  }

  // To be called within the DB transaction after successfully inserting an invoice
  Future<void> _updateNextInvoiceSequence(String prefix, int newSequence, DatabaseExecutor txn) async {
    // Note: Using txn (Transaction) if available, otherwise use _dbService.database directly
    // This specific method might be better in DatabaseService or SettingsProvider
    // if SettingsProvider also takes DatabaseExecutor for transactions.
    // For now, direct update via _dbService, assuming it handles its own DB instance.
    // This is NOT ideal for atomicity with invoice creation if not part of the same transaction.
    // The best approach is to update settings within the same transaction as invoice creation.

    // This logic should be part of the same transaction as saving the invoice.
    // We will update Company_Settings table directly using the transaction object 'txn'.
     await txn.update(
      'Company_Settings',
      {'LastInvoiceSequence': newSequence},
      where: 'SettingID = ?', // Assuming SettingID is 1
      whereArgs: [1],
    );
    // Also update in the provider's cache
    _settingsProvider.currentSettings = _settingsProvider.currentSettings?.copyWith(lastInvoiceSequence: newSequence);
    // No notifyListeners() for settingsProvider here, as this is an internal update.
  }


  Future<SalesInvoice?> createInvoice({
    required int customerId,
    // required String customerName, // For display if needed
    required DateTime invoiceDate,
    required List<SalesInvoiceItem> items,
    String? notes,
    bool isInstallment = false,
    int? numberOfInstallments,
    DateTime? firstInstallmentDueDate, // Required if isInstallment is true
    List<double>? customInstallmentAmounts, // Optional, for user-edited installment values
    // Collection agency fields will be handled during update/later stage
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
        if (sumOfCustomInstallments.toStringAsFixed(2) != totalAmount.toStringAsFixed(2)) { // Compare with precision
            _setError("Sum of custom installment amounts (${sumOfCustomInstallments.toStringAsFixed(2)}) must equal total invoice amount (${totalAmount.toStringAsFixed(2)}).");
            _setLoading(false);
            return null;
        }
    }

    final String invoiceNumberString = await _generateNextInvoiceNumber();
    if (invoiceNumberString.startsWith("ERR-NO-SETTINGS")) {
      // Error already set by _generateNextInvoiceNumber
      _setLoading(false);
      return null;
    }

    SalesInvoice newInvoice = SalesInvoice(
      invoiceNumber: invoiceNumberString,
      invoiceDate: invoiceDate,
      customerID: customerId,
      // customerName: customerName,
      totalAmount: totalAmount,
      amountPaid: 0.0, // Initially unpaid
      paymentStatus: 'Unpaid',
      notes: notes,
      isInstallment: isInstallment,
      numberOfInstallments: isInstallment ? numberOfInstallments : null,
      defaultInstallmentAmount: isInstallment ? (totalAmount / numberOfInstallments!) : null,
      installments: [], // Will be populated below
    );

    final db = await _dbService.database;
    try {
      await db.transaction((txn) async {
        // 1. Insert Sales_Invoice
        final invoiceId = await txn.insert('Sales_Invoices', newInvoice.toMap());
        newInvoice = newInvoice.copyWith(invoiceID: invoiceId);

        // 1.5 Update LastInvoiceSequence in CompanySettings
        // Extract prefix and sequence from the generated invoiceNumberString
        // This is a bit coupled; _generateNextInvoiceNumber could return both parts.
        // For now, we parse. Example: "INV-00001"
        final parts = invoiceNumberString.split('-');
        if (parts.length >= 2) {
            final currentSequence = int.tryParse(parts.last);
            final currentPrefix = parts.sublist(0, parts.length -1).join('-');
            if (currentSequence != null) {
                 await _updateNextInvoiceSequence(currentPrefix, currentSequence, txn);
            } else {
                // This should not happen if _generateNextInvoiceNumber is correct
                debugPrint("Error: Could not parse sequence from invoice number for settings update.");
            }
        }


        // 2. Insert Sales_Invoice_Items
        for (var item in items) {
          await txn.insert('Sales_Invoice_Items', item.toMap(invoiceId));
          // TODO: Decrement product stock (ProductProvider.updateStock(item.productID, newStock))
        }

        // 3. Insert Invoice_Installments if applicable
        if (newInvoice.isInstallment) {
          List<InvoiceInstallment> generatedInstallments = [];
          double remainingAmount = newInvoice.totalAmount;

          for (int i = 0; i < newInvoice.numberOfInstallments!; i++) {
            DateTime dueDate;
            if (i == 0) {
              dueDate = firstInstallmentDueDate!;
            } else {
              // Add one month to the previous due date
              DateTime prevDueDate = generatedInstallments.last.dueDate;
              dueDate = DateTime(prevDueDate.year, prevDueDate.month + 1, prevDueDate.day);
              // Handle cases where day might not exist in next month (e.g. Jan 31 -> Feb 28/29)
              if (dueDate.month != (prevDueDate.month + 1) % 12 && (prevDueDate.month + 1) != 12) { // check if month wrapped around incorrectly
                  dueDate = DateTime(prevDueDate.year, prevDueDate.month + 2, 0); // last day of correct month
              }
            }

            double installmentAmount;
            if (customInstallmentAmounts != null && i < customInstallmentAmounts.length) {
                installmentAmount = customInstallmentAmounts[i];
            } else {
                // Distribute remaining amount for last installment to avoid precision issues
                installmentAmount = (i == newInvoice.numberOfInstallments! - 1)
                                  ? remainingAmount
                                  : (newInvoice.defaultInstallmentAmount ?? (newInvoice.totalAmount / newInvoice.numberOfInstallments!));
                installmentAmount = double.parse(installmentAmount.toStringAsFixed(2)); // round to 2 decimal places
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
          newInvoice = newInvoice.copyWith(installments: generatedInstallments);
        }
        // TODO: Update Customer Balance
      });

      _invoices.add(newInvoice); // Add to local list (consider sorting or refetching for consistency)
      notifyListeners();
      _setLoading(false);
      return newInvoice;

    } catch (e) {
      debugPrint("Error creating invoice in SalesProvider: $e");
      _setError("Failed to create invoice. $e");
      _setLoading(false);
      return null;
    }
  }
  // Other methods (fetchInvoices, updateInvoice, deleteInvoice, recordPayment) will be added later.
}
