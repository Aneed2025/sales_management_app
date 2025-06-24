class Customer {
  final int? customerID;
  final String customerName;
  final String? idNumber; // National ID, Passport No., etc.
  final String? phone;
  final String? email;
  final String? workPlace;
  final String? address;
  double balance; // Outstanding balance. Positive if customer owes.

  Customer({
    this.customerID,
    required this.customerName,
    this.idNumber,
    this.phone,
    this.email,
    this.workPlace,
    this.address,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'CustomerID': customerID,
      'CustomerName': customerName,
      'IDNumber': idNumber,
      'Phone': phone,
      'Email': email,
      'WorkPlace': workPlace,
      'Address': address,
      'Balance': balance,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerID: map['CustomerID'],
      customerName: map['CustomerName'],
      idNumber: map['IDNumber'],
      phone: map['Phone'],
      email: map['Email'],
      workPlace: map['WorkPlace'],
      address: map['Address'],
      balance: (map['Balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Customer copyWith({
    int? customerID,
    String? customerName,
    String? idNumber,
    String? phone,
    String? email,
    String? workPlace,
    String? address,
    double? balance,
  }) {
    return Customer(
      customerID: customerID ?? this.customerID,
      customerName: customerName ?? this.customerName,
      idNumber: idNumber ?? this.idNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      workPlace: workPlace ?? this.workPlace,
      address: address ?? this.address,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'Customer{customerID: $customerID, customerName: $customerName, phone: $phone, balance: $balance}';
  }
}
