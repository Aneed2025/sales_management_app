// Placeholder for SalesInvoiceItem model, will be defined properly later or in its own file
// For now, we might handle items as List<Map<String, dynamic>> or similar in the provider
import 'sales_invoice_item_model.dart';
import 'invoice_installment_model.dart';
import 'sales_payment_model.dart'; // Import SalesPayment model

class SalesInvoice {
  final int? invoiceID;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final int customerID;
  final String? customerName; // For display, fetched via join or from Customer object

  double totalAmount;
  double amountPaid;
  double balanceDue;
  String paymentStatus; // "Unpaid", "Partially Paid", "Paid", "In Collection"

  final int? createdByUserID;
  final String? notes;

  // Installment Fields
  bool isInstallment;
  int? numberOfInstallments;
  double? defaultInstallmentAmount;
  List<InvoiceInstallment> installments;

  // Collection Agency Fields
  bool isInCollection;
  DateTime? dateSentToCollection;
  int? collectionAgencyID;
  final String? collectionAgencyName; // For display from JOIN
  final String? collectionAgencyContact; // For display from JOIN


  // Items and Payments - not directly stored in Sales_Invoices table but populated by provider
  List<SalesInvoiceItem> items;
  List<SalesPayment> payments;

  SalesInvoice({
    this.invoiceID,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.customerID,
    // required this.customerName,
    required this.totalAmount,
    this.amountPaid = 0.0,
    this.paymentStatus = 'Unpaid',
    this.createdByUserID,
    this.notes,
    this.isInstallment = false,
    this.numberOfInstallments,
    this.defaultInstallmentAmount,
    this.installments = const [], // Default to empty list
    this.isInCollection = false,
    this.dateSentToCollection,
    this.collectionAgencyID,
    this.customerName,
    this.collectionAgencyName,
    this.collectionAgencyContact,
    this.items = const [],
    this.payments = const [],
  }) : balanceDue = totalAmount - amountPaid;


  Map<String, dynamic> toMap() {
    return {
      'InvoiceID': invoiceID,
      'InvoiceNumber': invoiceNumber,
      'InvoiceDate': invoiceDate.toIso8601String(),
      'CustomerID': customerID,
      'TotalAmount': totalAmount,
      'AmountPaid': amountPaid,
      'BalanceDue': balanceDue,
      'PaymentStatus': paymentStatus,
      'CreatedByUserID': createdByUserID,
      'Notes': notes,
      'IsInstallment': isInstallment ? 1 : 0,
      'NumberOfInstallments': numberOfInstallments,
      'DefaultInstallmentAmount': defaultInstallmentAmount,
      'IsInCollection': isInCollection ? 1 : 0,
      'DateSentToCollection': dateSentToCollection?.toIso8601String(),
      'CollectionAgencyID': collectionAgencyID,
    };
    // Note: 'installments', 'items', 'payments' lists are not directly stored in Sales_Invoices table,
    // but in their respective tables or populated by provider.
    // customerName, collectionAgencyName, collectionAgencyContact are also not in Sales_Invoices table.
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> map) {
    double total = (map['TotalAmount'] as num?)?.toDouble() ?? 0.0;
    double paid = (map['AmountPaid'] as num?)?.toDouble() ?? 0.0;
    return SalesInvoice(
      invoiceID: map['InvoiceID'],
      invoiceNumber: map['InvoiceNumber'],
      invoiceDate: DateTime.parse(map['InvoiceDate']),
      customerID: map['CustomerID'],
      customerName: map['CustomerName'],
      totalAmount: total,
      amountPaid: paid,
      paymentStatus: map['PaymentStatus'] ?? 'Unpaid',
      createdByUserID: map['CreatedByUserID'],
      notes: map['Notes'],
      isInstallment: map['IsInstallment'] == 1,
      numberOfInstallments: map['NumberOfInstallments'],
      defaultInstallmentAmount: (map['DefaultInstallmentAmount'] as num?)?.toDouble(),
      isInCollection: map['IsInCollection'] == 1,
      dateSentToCollection: map['DateSentToCollection'] != null
          ? DateTime.parse(map['DateSentToCollection'])
          : null,
      collectionAgencyID: map['CollectionAgencyID'],
      collectionAgencyName: map['CollectionAgencyName'], // From JOIN
      collectionAgencyContact: map['CollectionAgencyContact'], // From JOIN
      // items, installments, payments will be populated by the provider after fetching
      items: [],
      installments: [],
      payments: [],
    );
  }

  SalesInvoice copyWith({
    int? invoiceID,
    String? invoiceNumber,
    DateTime? invoiceDate,
    int? customerID,
    String? customerName,
    double? totalAmount,
    double? amountPaid,
    String? paymentStatus,
    int? createdByUserID,
    String? notes,
    bool? isInstallment,
    int? numberOfInstallments,
    double? defaultInstallmentAmount,
    List<InvoiceInstallment>? installments,
    bool? isInCollection,
    DateTime? dateSentToCollection,
    int? collectionAgencyID,
    String? collectionAgencyName, // Added
    String? collectionAgencyContact, // Added
    List<SalesInvoiceItem>? items, // Added
    List<SalesPayment>? payments, // Added
  }) {
    final newTotalAmount = totalAmount ?? this.totalAmount;
    final newAmountPaid = amountPaid ?? this.amountPaid;
    return SalesInvoice(
      invoiceID: invoiceID ?? this.invoiceID,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerID: customerID ?? this.customerID,
      customerName: customerName ?? this.customerName,
      totalAmount: newTotalAmount,
      amountPaid: newAmountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdByUserID: createdByUserID ?? this.createdByUserID,
      notes: notes ?? this.notes,
      isInstallment: isInstallment ?? this.isInstallment,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      defaultInstallmentAmount: defaultInstallmentAmount ?? this.defaultInstallmentAmount,
      installments: installments ?? List<InvoiceInstallment>.from(this.installments),
      isInCollection: isInCollection ?? this.isInCollection,
      dateSentToCollection: dateSentToCollection ?? this.dateSentToCollection,
      collectionAgencyID: collectionAgencyID ?? this.collectionAgencyID,
      collectionAgencyName: collectionAgencyName ?? this.collectionAgencyName,
      collectionAgencyContact: collectionAgencyContact ?? this.collectionAgencyContact,
      items: items ?? List<SalesInvoiceItem>.from(this.items),
      payments: payments ?? List<SalesPayment>.from(this.payments),
    );
  }
}
