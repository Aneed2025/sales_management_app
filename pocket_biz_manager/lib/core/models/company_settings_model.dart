class CompanySettings {
  final int? settingID; // Usually only one row in the table, so ID might be fixed (e.g., 1)
  final String? companyName;
  final String? address;
  final String? phone;
  final String? email;
  final String? currencySymbol; // Default 'NAD'
  final String? logoURL;
  final String? invoicePrefix;
  final int? lastInvoiceSequence;

  CompanySettings({
    this.settingID = 1, // Default to 1 as it's usually a single-row table
    this.companyName,
    this.address,
    this.phone,
    this.email,
    this.currencySymbol = 'NAD',
    this.logoURL,
    this.invoicePrefix,
    this.lastInvoiceSequence = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'SettingID': settingID,
      'CompanyName': companyName,
      'Address': address,
      'Phone': phone,
      'Email': email,
      'CurrencySymbol': currencySymbol,
      'LogoURL': logoURL,
      'InvoicePrefix': invoicePrefix,
      'LastInvoiceSequence': lastInvoiceSequence,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      settingID: map['SettingID'],
      companyName: map['CompanyName'],
      address: map['Address'],
      phone: map['Phone'],
      email: map['Email'],
      currencySymbol: map['CurrencySymbol'] ?? 'NAD',
      logoURL: map['LogoURL'],
      invoicePrefix: map['InvoicePrefix'],
      lastInvoiceSequence: map['LastInvoiceSequence'] as int?, // Ensure type safety
    );
  }

  CompanySettings copyWith({
    int? settingID,
    String? companyName,
    String? address,
    String? phone,
    String? email,
    String? currencySymbol,
    String? logoURL,
    String? invoicePrefix,
    int? lastInvoiceSequence,
  }) {
    return CompanySettings(
      settingID: settingID ?? this.settingID,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logoURL: logoURL ?? this.logoURL,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      lastInvoiceSequence: lastInvoiceSequence ?? this.lastInvoiceSequence,
    );
  }
}
