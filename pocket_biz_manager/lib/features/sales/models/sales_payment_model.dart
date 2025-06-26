// Represents a sales payment record, potentially including joined data like PaymentMethodName

class SalesPayment {
  final int? paymentID;
  final int invoiceID; // FK to Sales_Invoices
  final int customerID; // FK to Customers
  final DateTime paymentDate;
  final double amount;
  final int paymentMethodID; // FK to Payment_Methods
  final String? paymentMethodName; // Joined from Payment_Methods table
  final bool collectedByAgency;
  final int? appliedToInstallmentID; // FK to Invoice_Installments
  final String? notes;

  SalesPayment({
    this.paymentID,
    required this.invoiceID,
    required this.customerID,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethodID,
    this.paymentMethodName, // For display
    this.collectedByAgency = false,
    this.appliedToInstallmentID,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'PaymentID': paymentID,
      'InvoiceID': invoiceID,
      'CustomerID': customerID,
      'PaymentDate': paymentDate.toIso8601String(),
      'Amount': amount,
      'PaymentMethodID': paymentMethodID,
      'CollectedByAgency': collectedByAgency ? 1 : 0,
      'AppliedToInstallmentID': appliedToInstallmentID,
      'Notes': notes,
      // paymentMethodName is not part of the Sales_Payments table schema
    };
  }

  factory SalesPayment.fromMap(Map<String, dynamic> map) {
    return SalesPayment(
      paymentID: map['PaymentID'],
      invoiceID: map['InvoiceID'],
      customerID: map['CustomerID'],
      paymentDate: DateTime.parse(map['PaymentDate']),
      amount: (map['Amount'] as num).toDouble(),
      paymentMethodID: map['PaymentMethodID'],
      paymentMethodName: map['PaymentMethodName'], // From JOIN
      collectedByAgency: map['CollectedByAgency'] == 1,
      appliedToInstallmentID: map['AppliedToInstallmentID'],
      notes: map['Notes'],
    );
  }

  SalesPayment copyWith({
    int? paymentID,
    int? invoiceID,
    int? customerID,
    DateTime? paymentDate,
    double? amount,
    int? paymentMethodID,
    String? paymentMethodName,
    bool? collectedByAgency,
    int? appliedToInstallmentID,
    String? notes,
  }) {
    return SalesPayment(
      paymentID: paymentID ?? this.paymentID,
      invoiceID: invoiceID ?? this.invoiceID,
      customerID: customerID ?? this.customerID,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      paymentMethodID: paymentMethodID ?? this.paymentMethodID,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      collectedByAgency: collectedByAgency ?? this.collectedByAgency,
      appliedToInstallmentID: appliedToInstallmentID ?? this.appliedToInstallmentID,
      notes: notes ?? this.notes,
    );
  }
}
