class Supplier {
  final int? supplierID;
  final String supplierName;
  final String? phone;
  final String? email;
  final String? address;
  double balance; // Amount owed TO the supplier. Positive if company owes supplier.

  Supplier({
    this.supplierID,
    required this.supplierName,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'SupplierID': supplierID,
      'SupplierName': supplierName,
      'Phone': phone,
      'Email': email,
      'Address': address,
      'Balance': balance,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      supplierID: map['SupplierID'],
      supplierName: map['SupplierName'],
      phone: map['Phone'],
      email: map['Email'],
      address: map['Address'],
      balance: (map['Balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Supplier copyWith({
    int? supplierID,
    String? supplierName,
    String? phone,
    String? email,
    String? address,
    double? balance,
  }) {
    return Supplier(
      supplierID: supplierID ?? this.supplierID,
      supplierName: supplierName ?? this.supplierName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
    );
  }

  @override
  String toString() {
    return 'Supplier{supplierID: $supplierID, supplierName: $supplierName, phone: $phone, balance: $balance}';
  }
}
