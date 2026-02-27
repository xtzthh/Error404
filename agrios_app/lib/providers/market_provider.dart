import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';
import 'storage_provider.dart';
import '../theme/constants.dart';

class MarketProvider with ChangeNotifier {
  List<CropPrice> _prices = [
    CropPrice(crop: 'WHEAT', currentPrice: 2450.0, change: 15.5, unit: 'QUINTAL', trend: 'BULLISH'),
    CropPrice(crop: 'RICE', currentPrice: 3200.0, change: -5.2, unit: 'QUINTAL', trend: 'BEARISH'),
    CropPrice(crop: 'CORN', currentPrice: 1850.0, change: 8.0, unit: 'QUINTAL', trend: 'STABLE'),
    CropPrice(crop: 'SOYBEAN', currentPrice: 4600.0, change: 45.0, unit: 'QUINTAL', trend: 'STRONG'),
    CropPrice(crop: 'COTTON', currentPrice: 7200.0, change: -12.0, unit: 'QUINTAL', trend: 'WEAK'),
    CropPrice(crop: 'POTATO', currentPrice: 1200.0, change: 2.5, unit: 'QUINTAL', trend: 'NOMINAL'),
  ];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  String? _source;
  bool _hasLoaded = false;
  String _inventorySignature = '';
  Map<String, String> _blockSignals = {};

  List<CropPrice> get prices => _prices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  String? get source => _source;
  bool get hasLoaded => _hasLoaded;
  Map<String, String> get blockSignals => _blockSignals;

  static const String _defaultState = 'Gujarat';
  static const String _defaultDistrict = 'Vadodara';

  void updateSmartAdvice(List<StorageItem> inventory) {
    bool changed = false;
    for (var price in _prices) {
      // Find if this crop is in storage (case-insensitive)
      final items = inventory.where((it) => 
        !it.isSold && it.name.toUpperCase().contains(price.crop.toUpperCase())
      ).toList();

      if (items.isNotEmpty) {
        final totalQty = items.fold(0.0, (sum, it) => sum + it.qty);
        final unit = items.first.unit;
        
        // Find the one closest to expiry
        final minExpiryDays = items.map((it) => 
          it.expiryDate.difference(DateTime.now()).inDays
        ).reduce((a, b) => a < b ? a : b);

        if (price.trend == 'BULLISH' || price.trend == 'STRONG') {
          if (minExpiryDays < 30) {
            price.smartAdvice = "SELL NOW: HIGH PRICE + EXPIRING IN $minExpiryDays DAYS";
            price.adviceColor = 'red';
          } else {
            price.smartAdvice = "IN STORAGE ($totalQty $unit): PRICE IS CLIMBING";
            price.adviceColor = 'green';
          }
        } else if (price.trend == 'BEARISH' || price.trend == 'WEAK') {
          if (minExpiryDays < 15) {
            price.smartAdvice = "LIQUIDATE: PRICE DROPPING BUT EXPIRY CRITICAL";
            price.adviceColor = 'red';
          } else {
            price.smartAdvice = "HOLD: PRICE LOW, $minExpiryDays DAYS SHELF LIFE LEFT";
            price.adviceColor = 'yellow';
          }
        } else {
          price.smartAdvice = "IN STORAGE: $totalQty $unit | STABLE MARKET";
          price.adviceColor = 'green';
        }
        changed = true;
      } else {
        if (price.smartAdvice != null) {
          price.smartAdvice = null;
          price.adviceColor = null;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  void refreshPrices(List<StorageItem> inventory) {
    _prices = _prices.map((p) {
      final change = (p.currentPrice * 0.005) * (p.change >= 0 ? 1 : -1);
      return CropPrice(
        crop: p.crop,
        currentPrice: p.currentPrice + change,
        change: change,
        unit: p.unit,
        trend: change >= 0 ? 'BULLISH' : 'BEARISH',
        market: p.market,
        state: p.state,
        district: p.district,
        date: p.date,
      );
    }).toList();
    updateSmartAdvice(inventory);
    _blockSignals = _buildBlockSignals(inventory, _prices);
    notifyListeners();
  }

  Future<void> fetchLivePrices(List<StorageItem> inventory) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    final commodities = _buildCommodityList(inventory);
    if (commodities.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final uri = Uri.parse(ApiConstants.marketEndpoint).replace(
        queryParameters: {
          'commodities': commodities.join(','),
          'state': _defaultState,
          'district': _defaultDistrict,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final payload = json.decode(response.body);
        final List<dynamic> rows = payload['prices'] ?? [];
        final previous = {for (final p in _prices) p.crop: p.currentPrice};
        _prices = rows.map((row) {
          final crop = (row['crop'] ?? '').toString().toUpperCase();
          final price = (row['price'] as num?)?.toDouble() ?? 0.0;
          final prev = previous[crop];
          final change = prev == null ? 0.0 : price - prev;
          final trend = change > 0
              ? 'BULLISH'
              : (change < 0 ? 'BEARISH' : 'STABLE');
          return CropPrice(
            crop: crop,
            currentPrice: price,
            change: change,
            unit: row['unit'] ?? 'QUINTAL',
            trend: trend,
            market: row['market'],
            state: row['state'],
            district: row['district'],
            date: row['date'],
          );
        }).toList();
        _source = payload['source']?.toString();
        final updatedAt = payload['updated_at']?.toString();
        if (updatedAt != null && updatedAt.isNotEmpty) {
          _lastUpdated = DateTime.tryParse(updatedAt);
        } else {
          _lastUpdated = DateTime.now();
        }
        _hasLoaded = true;
        updateSmartAdvice(inventory);
        _blockSignals = _buildBlockSignals(inventory, _prices);
      } else {
        _errorMessage = "MARKET_ERROR: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "MARKET_OFFLINE";
      debugPrint('MARKET_FETCH_ERROR: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void syncInventory(List<StorageItem> inventory) {
    final signature = inventory
        .map((i) => '${i.id}:${i.qty}:${i.location}:${i.isSold}')
        .join('|');
    if (signature == _inventorySignature) return;
    _inventorySignature = signature;
    updateSmartAdvice(inventory);
    _blockSignals = _buildBlockSignals(inventory, _prices);
    notifyListeners();
  }

  List<String> _buildCommodityList(List<StorageItem> inventory) {
    const known = [
      'RICE',
      'WHEAT',
      'MAIZE',
      'CORN',
      'SOYBEAN',
      'COTTON',
      'POTATO',
      'ONION',
      'TOMATO',
      'SUGARCANE',
    ];
    final set = <String>{};
    for (final item in inventory) {
      if (item.isSold) continue;
      final name = item.name.toUpperCase();
      final match = known.firstWhere(
        (k) => name.contains(k),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        set.add(match);
      } else {
        final parts = name.split(RegExp(r'[\s_]+'));
        if (parts.isNotEmpty && parts.first.isNotEmpty) {
          set.add(parts.first);
        }
      }
    }
    if (set.isEmpty) {
      set.addAll(['RICE', 'WHEAT', 'CORN']);
    }
    return set.toList();
  }

  Map<String, String> _buildBlockSignals(
    List<StorageItem> inventory,
    List<CropPrice> prices,
  ) {
    final priceMap = {for (final p in prices) p.crop: p};
    final bestByBlock = <String, CropPrice>{};
    final daysByBlock = <String, int>{};

    for (final item in inventory) {
      if (item.isSold) continue;
      final cropKey = _matchPriceKey(item.name, priceMap.keys);
      if (cropKey == null) continue;
      final price = priceMap[cropKey]!;
      final block = item.location.toUpperCase();
      final days = item.expiryDate.difference(DateTime.now()).inDays;

      if (!bestByBlock.containsKey(block)) {
        bestByBlock[block] = price;
        daysByBlock[block] = days;
        continue;
      }
      if (price.currentPrice > bestByBlock[block]!.currentPrice) {
        bestByBlock[block] = price;
        daysByBlock[block] = days;
      }
    }

    final signals = <String, String>{};
    bestByBlock.forEach((block, price) {
      final days = daysByBlock[block] ?? 0;
      signals[block] =
          '${price.crop} ₹${price.currentPrice.toStringAsFixed(0)}/${price.unit} | EXP ${days}D';
    });
    return signals;
  }

  String? _matchPriceKey(String name, Iterable<String> keys) {
    final upper = name.toUpperCase();
    for (final key in keys) {
      if (upper.contains(key)) return key;
    }
    final parts = upper.split(RegExp(r'[\s_]+'));
    if (parts.isNotEmpty && keys.contains(parts.first)) {
      return parts.first;
    }
    return null;
  }
}
