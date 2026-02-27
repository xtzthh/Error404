import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/constants.dart';

class StorageItem {
  final String id;
  final String name;
  final String variety;
  final double qty;
  final String unit;
  final String location;
  final DateTime storedAt;
  final int shelfMonths;
  bool isSold;
  DateTime? soldAt;

  StorageItem({
    required this.id,
    required this.name,
    required this.variety,
    required this.qty,
    required this.unit,
    required this.location,
    required this.storedAt,
    required this.shelfMonths,
    this.isSold = false,
    this.soldAt,
  });

  DateTime get expiryDate {
    return DateTime(storedAt.year, storedAt.month + shelfMonths, storedAt.day);
  }

  String get status {
    if (isSold) return 'sold';
    final days = expiryDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'expired';
    if (days <= 30) return 'near';
    return 'ok';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'variety': variety,
    'qty': qty,
    'unit': unit,
    'location': location,
    'stored_at': storedAt.toIso8601String().split('T')[0],
    'shelf_months': shelfMonths,
    'sold': isSold,
    'sold_at': soldAt?.toIso8601String().split('T')[0],
  };

  factory StorageItem.fromJson(Map<String, dynamic> json) => StorageItem(
    id: json['id'],
    name: json['name'],
    variety: json['variety'],
    qty: (json['qty'] as num).toDouble(),
    unit: json['unit'],
    location: json['location'],
    storedAt: DateTime.parse(json['stored_at']),
    shelfMonths: json['shelf_months'],
    isSold: json['sold'] ?? false,
    soldAt: json['sold_at'] != null ? DateTime.parse(json['sold_at']) : null,
  );
}

class StorageProvider extends ChangeNotifier {
  List<StorageItem> _inventory = [];
  String? _selectedBlock;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _syncTimer;
  bool _isWriteSyncInProgress = false;
  bool _hasPendingWrite = false;

  List<StorageItem> get inventory => _inventory;
  String? get selectedBlock => _selectedBlock;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StorageProvider() {
    fetchInventory();
    // Auto-sync every 20 seconds for near-real-time updates
    _syncTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => fetchInventory());
  }

  Future<void> fetchInventory({bool forceDuringWrite = false}) async {
    if (!forceDuringWrite && (_isWriteSyncInProgress || _hasPendingWrite)) {
      return;
    }
    _errorMessage = null;
    // Only show loading for the very first fetch to avoid UI flicker
    if (_inventory.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final response = await http.get(Uri.parse(ApiConstants.storageEndpoint))
          .timeout(const Duration(seconds: 5));
          
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _inventory = data.map((item) => StorageItem.fromJson(item)).toList();
        notifyListeners();
      } else {
        _errorMessage = "SERVER_ERROR: ${response.statusCode}";
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "SYNC_FAILED: CHECK_NETWORK_OR_IP";
      debugPrint('STORAGE_SYNC_ERROR: $e');
      notifyListeners();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refresh() async {
    await fetchInventory();
  }

  Future<bool> _syncWithServer() async {
    _isWriteSyncInProgress = true;
    try {
      final body = json.encode(_inventory.map((i) => i.toJson()).toList());
      final response = await http.post(
        Uri.parse(ApiConstants.storageEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      _errorMessage = "SERVER_WRITE_FAILED: ${response.statusCode}";
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "SYNC_FAILED: CHECK_NETWORK_OR_IP";
      debugPrint('STORAGE_SAVE_ERROR: $e');
      notifyListeners();
      return false;
    } finally {
      _isWriteSyncInProgress = false;
    }
  }

  Future<void> _commitAndRefresh() async {
    final ok = await _syncWithServer();
    _hasPendingWrite = false;
    if (ok) {
      await fetchInventory(forceDuringWrite: true);
    }
  }
 
  Future<void> addItem(StorageItem item) async {
    await fetchInventory(forceDuringWrite: true);
    _hasPendingWrite = true;
    final existingIndex = _inventory.indexWhere(
      (it) => it.location == item.location && it.name == item.name && !it.isSold
    );

    if (existingIndex != -1) {
      final existing = _inventory[existingIndex];
      _inventory[existingIndex] = StorageItem(
        id: existing.id,
        name: existing.name,
        variety: existing.variety,
        qty: existing.qty + item.qty,
        unit: existing.unit,
        location: existing.location,
        storedAt: item.storedAt,
        shelfMonths: existing.shelfMonths,
      );
    } else {
      _inventory.add(item);
    }
    _selectedBlock = null;
    notifyListeners();
    await _commitAndRefresh();
  }

  void selectBlock(String block) {
    _selectedBlock = block;
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    await fetchInventory(forceDuringWrite: true);
    _hasPendingWrite = true;
    _inventory.removeWhere((item) => item.id == id);
    notifyListeners();
    await _commitAndRefresh();
  }

  Future<void> markAsSold(String id) async {
    await fetchInventory(forceDuringWrite: true);
    final index = _inventory.indexWhere((item) => item.id == id);
    if (index != -1) {
      _hasPendingWrite = true;
      _inventory[index].isSold = true;
      _inventory[index].soldAt = DateTime.now();
      notifyListeners();
      await _commitAndRefresh();
    }
  }

  List<StorageItem> getItemsInBlock(String block) {
    return _inventory.where((it) => it.location == block && !it.isSold).toList();
  }

  bool isBlockOccupied(String block) {
    return _inventory.any((it) => it.location == block && !it.isSold);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
