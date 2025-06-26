// Placeholder for SalesInvoiceItem model, will be defined properly later or in its own file
// For now, we might handle items as List<Map<String, dynamic>> or similar in the provider
// import 'sales_invoice_item_model.dart';
import 'invoice_installment_model.dart';

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
  double? defaultInstallmentAmount; // Initial calculated amount per installment
  List<InvoiceInstallment> installments; // List of actual installment objects

  // Collection Agency Fields
  bool isInCollection;
  DateTime? dateSentToCollection;
  int? collectionAgencyID; // FK to CollectionAgencies table
  // final String? collectionAgencyName; // For display

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
    // Note: 'installments' list is not directly stored in Sales_Invoices table,
    // but in the separate Invoice_Installments table.
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> map) {
    double total = (map['TotalAmount'] as num?)?.toDouble() ?? 0.0;
    double paid = (map['AmountPaid'] as num?)?.toDouble() ?? 0.0;
    return SalesInvoice(
      invoiceID: map['InvoiceID'],
      invoiceNumber: map['InvoiceNumber'],
      invoiceDate: DateTime.parse(map['InvoiceDate']),
      customerID: map['CustomerID'],
      customerName: map['CustomerName'], // Now part of the model from JOIN
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
      // collectionAgencyName: map['AgencyName'], // If joined from Collection_Agencies
      installments: [], // Installments should be fetched separately
    );
  }

  SalesInvoice copyWith({
    int? invoiceID,
    String? invoiceNumber,
    DateTime? invoiceDate,
    int? customerID,
    // String? customerName,
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
    String? customerName, // Added customerName to copyWith
  }) {
    final newTotalAmount = totalAmount ?? this.totalAmount;
    final newAmountPaid = amountPaid ?? this.amountPaid;
    return SalesInvoice(
      invoiceID: invoiceID ?? this.invoiceID,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      customerID: customerID ?? this.customerID,
      // customerName: customerName ?? this.customerName,
      totalAmount: newTotalAmount,
      amountPaid: newAmountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdByUserID: createdByUserID ?? this.createdByUserID,
      notes: notes ?? this.notes,
      isInstallment: isInstallment ?? this.isInstallment,
      numberOfInstallments: numberOfInstallments ?? this.numberOfInstallments,
      defaultInstallmentAmount: defaultInstallmentAmount ?? this.defaultInstallmentAmount,
      installments: installments ?? List<InvoiceInstallment>.from(this.installments), // Create a new list
      isInCollection: isInCollection ?? this.isInCollection,
      dateSentToCollection: dateSentToCollection ?? this.dateSentToCollection,
      collectionAgencyID: collectionAgencyID ?? this.collectionAgencyID,
      customerName: customerName ?? this.customerName,
    );
  }
}
