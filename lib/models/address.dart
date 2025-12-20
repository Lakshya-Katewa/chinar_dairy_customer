import 'package:cloud_firestore/cloud_firestore.dart';

class DetailedAddress {
  final String houseNumber;
  final String street;
  final String city;
  final String pinCode;
  final String? landmark;
  final String? instructions;
  final double latitude;
  final double longitude;
  final String fullAddress;

  DetailedAddress({
    required this.houseNumber,
    required this.street,
    required this.city,
    required this.pinCode,
    this.landmark,
    this.instructions,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });

  factory DetailedAddress.fromMap(Map<String, dynamic> data) {
    return DetailedAddress(
      houseNumber: data['houseNumber'] ?? '',
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      pinCode: data['pinCode'] ?? '',
      landmark: data['landmark'],
      instructions: data['instructions'],
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      fullAddress: data['fullAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'street': street,
      'city': city,
      'pinCode': pinCode,
      'landmark': landmark,
      'instructions': instructions,
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
    };
  }

  String get formattedAddress {
    final parts = <String>[];
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (pinCode.isNotEmpty) parts.add(pinCode);
    return parts.join(', ');
  }
}
