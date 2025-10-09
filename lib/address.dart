class Address {
  final String id;
  final String title;
  final String fullName;
  final String phoneNumber;
  final String addressLine;
  final String city;
  final String pincode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.title,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? title,
    String? fullName,
    String? phoneNumber,
    String? addressLine,
    String? city,
    String? pincode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get displayAddress {
    return '$addressLine, $city, $pincode';
  }

  String get fullDisplayAddress {
    return '$title: $addressLine, $city, $pincode';
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Address',
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine: map['addressLine'] ?? '',
      city: map['city'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'city': city,
      'pincode': pincode,
      'isDefault': isDefault,
    };
  }
}
