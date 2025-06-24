class InvoiceInstallment {
  final int? installmentID;
  final int invoiceID; // FK to SalesInvoice
  final int installmentNumber;
  final DateTime dueDate; // Store as DateTime, convert to/from TEXT (ISO8601) for DB
  final double amountDue;
  double amountPaid;
  String status; // "Pending", "Partially Paid", "Paid"

  InvoiceInstallment({
    this.installmentID,
    required this.invoiceID,
    required this.installmentNumber,
    required this.dueDate,
    required this.amountDue,
    this.amountPaid = 0.0,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'InstallmentID': installmentID,
      'InvoiceID': invoiceID,
      'InstallmentNumber': installmentNumber,
      'DueDate': dueDate.toIso8601String(), // Store as ISO8601 string
      'AmountDue': amountDue,
      'AmountPaid': amountPaid,
      'Status': status,
    };
  }

  factory InvoiceInstallment.fromMap(Map<String, dynamic> map) {
    return InvoiceInstallment(
      installmentID: map['InstallmentID'],
      invoiceID: map['InvoiceID'],
      installmentNumber: map['InstallmentNumber'],
      dueDate: DateTime.parse(map['DueDate']), // Parse from ISO8601 string
      amountDue: (map['AmountDue'] as num).toDouble(),
      amountPaid: (map['AmountPaid'] as num).toDouble(),
      status: map['Status'],
    );
  }

  InvoiceInstallment copyWith({
    int? installmentID,
    int? invoiceID,
    int? installmentNumber,
    DateTime? dueDate,
    double? amountDue,
    double? amountPaid,
    String? status,
  }) {
    return InvoiceInstallment(
      installmentID: installmentID ?? this.installmentID,
      invoiceID: invoiceID ?? this.invoiceID,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
    );
  }
}
