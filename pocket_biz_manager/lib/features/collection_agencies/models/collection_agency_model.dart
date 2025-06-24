class CollectionAgency {
  final int? agencyID;
  final String agencyName;
  final String? contactPerson;
  final String? phoneNumber;
  final String? email;
  final String? address;
  final String? fileNumber; // Customer's file number with this agency
  final bool isActive;

  CollectionAgency({
    this.agencyID,
    required this.agencyName,
    this.contactPerson,
    this.phoneNumber,
    this.email,
    this.address,
    this.fileNumber,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'AgencyID': agencyID,
      'AgencyName': agencyName,
      'ContactPerson': contactPerson,
      'PhoneNumber': phoneNumber,
      'Email': email,
      'Address': address,
      'FileNumber': fileNumber,
      'IsActive': isActive ? 1 : 0,
    };
  }

  factory CollectionAgency.fromMap(Map<String, dynamic> map) {
    return CollectionAgency(
      agencyID: map['AgencyID'],
      agencyName: map['AgencyName'],
      contactPerson: map['ContactPerson'],
      phoneNumber: map['PhoneNumber'],
      email: map['Email'],
      address: map['Address'],
      fileNumber: map['FileNumber'],
      isActive: map['IsActive'] == 1,
    );
  }

  CollectionAgency copyWith({
    int? agencyID,
    String? agencyName,
    String? contactPerson,
    String? phoneNumber,
    String? email,
    String? address,
    String? fileNumber,
    bool? isActive,
  }) {
    return CollectionAgency(
      agencyID: agencyID ?? this.agencyID,
      agencyName: agencyName ?? this.agencyName,
      contactPerson: contactPerson ?? this.contactPerson,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      fileNumber: fileNumber ?? this.fileNumber,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'CollectionAgency{agencyID: $agencyID, agencyName: $agencyName, isActive: $isActive}';
  }
}
