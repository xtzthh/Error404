import 'package:flutter/material.dart';

class Field {
  final String id;
  final String name;
  final String owner;
  final String phone;
  final String area;
  final String crop; // Added this
  final double lat;
  final double lng;

  Field({
    required this.id,
    required this.name,
    required this.owner,
    required this.phone,
    required this.area,
    required this.crop, // Added this
    required this.lat,
    required this.lng,
  });
}

class FieldProvider extends ChangeNotifier {
  final List<Field> _fields = [
    Field(
      id: 'site1',
      name: 'Nelamangala Farm',
      owner: 'Shlok Kumar',
      phone: '+91 9876543210',
      area: '12.4 acres',
      crop: 'Sugarcane',
      lat: 13.1008,
      lng: 77.3916,
    ),
    Field(
      id: 'site2',
      name: 'Hoskote Agri Plot',
      owner: 'Ananya Rao',
      phone: '+91 9123456780',
      area: '7.9 acres',
      crop: 'Cotton',
      lat: 13.0704,
      lng: 77.8005,
    ),
    Field(
      id: 'site3',
      name: 'Kanakapura Orchard',
      owner: 'Pranav Desai',
      phone: '+91 9890012345',
      area: '18.2 acres',
      crop: 'Wheat',
      lat: 12.5469,
      lng: 77.4180,
    ),
  ];

  List<Field> get fields => _fields;

  void addField(Field field) {
    _fields.add(field);
    notifyListeners();
  }

  void removeField(String id) {
    _fields.removeWhere((field) => field.id == id);
    notifyListeners();
  }
}
