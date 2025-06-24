class PaymentMethod {
  final int? paymentMethodID;
  final String methodName;
  final String? description;
  final bool isActive;

  PaymentMethod({
    this.paymentMethodID,
    required this.methodName,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'PaymentMethodID': paymentMethodID,
      'MethodName': methodName,
      'Description': description,
      'IsActive': isActive ? 1 : 0, // Convert bool to int for SQLite
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      paymentMethodID: map['PaymentMethodID'],
      methodName: map['MethodName'],
      description: map['Description'],
      isActive: map['IsActive'] == 1, // Convert int from SQLite to bool
    );
  }

  PaymentMethod copyWith({
    int? paymentMethodID,
    String? methodName,
    String? description,
    bool? isActive,
  }) {
    return PaymentMethod(
      paymentMethodID: paymentMethodID ?? this.paymentMethodID,
      methodName: methodName ?? this.methodName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PaymentMethod{paymentMethodID: $paymentMethodID, methodName: $methodName, description: $description, isActive: $isActive}';
  }
}
