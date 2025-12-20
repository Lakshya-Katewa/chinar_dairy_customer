import '../models/address.dart';

class SavedAddress {
  final String id;
  final String customerId;
  final String label;
  final DetailedAddress address;
  final bool isDefault;
  final DateTime createdAt;

  SavedAddress({
    required this.id,
    required this.customerId,
    required this.label,
    required this.address,
    required this.isDefault,
    required this.createdAt,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> map) {
    return SavedAddress(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      label: map['label'] ?? '',
      address: DetailedAddress.fromMap(map['address'] ?? {}),
      isDefault: map['isDefault'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'label': label,
      'address': address.toMap(),
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  SavedAddress copyWith({
    String? id,
    String? customerId,
    String? label,
    DetailedAddress? address,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      label: label ?? this.label,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
