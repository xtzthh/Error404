import 'dart:math';
import '../providers/storage_provider.dart';

enum StorageRiskLevel { safe, warning, risk }

class BlockRiskResult {
  final StorageRiskLevel level;
  final List<String> reasons;

  const BlockRiskResult({required this.level, required this.reasons});
}

class WarehouseKpi {
  final int occupied;
  final int warning;
  final int risk;
  final int rescued;

  const WarehouseKpi({
    required this.occupied,
    required this.warning,
    required this.risk,
    required this.rescued,
  });
}

class DispatchMarketEconomics {
  final String bestMarket;
  final int bestNetPayout;
  final int bestLogisticsCost;
  final double bestDistanceKm;
  final String nearestMarket;
  final int gainVsNearest;

  const DispatchMarketEconomics({
    required this.bestMarket,
    required this.bestNetPayout,
    required this.bestLogisticsCost,
    required this.bestDistanceKm,
    required this.nearestMarket,
    required this.gainVsNearest,
  });
}

class DispatchRecommendation {
  final double distanceKm;
  final double travelHours;
  final String priority;
  final String etaLabel;
  final String windowText;
  final int daysLeft;
  final String nearestMarket;
  final String farmerLabel;

  const DispatchRecommendation({
    required this.distanceKm,
    required this.travelHours,
    required this.priority,
    required this.etaLabel,
    required this.windowText,
    required this.daysLeft,
    required this.nearestMarket,
    required this.farmerLabel,
  });
}

class _Geo {
  final double lat;
  final double lon;

  const _Geo(this.lat, this.lon);
}

class _CropProfile {
  final double tempWarn;
  final double tempRisk;
  final double humWarn;
  final double humRisk;
  final double co2Warn;
  final double co2Risk;

  const _CropProfile({
    required this.tempWarn,
    required this.tempRisk,
    required this.humWarn,
    required this.humRisk,
    required this.co2Warn,
    required this.co2Risk,
  });
}

class StorageIntelligenceService {
  static const Map<String, _CropProfile> _cropProfiles = {
    'RICE': _CropProfile(
      tempWarn: 33,
      tempRisk: 36,
      humWarn: 78,
      humRisk: 86,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'WHEAT': _CropProfile(
      tempWarn: 30,
      tempRisk: 34,
      humWarn: 70,
      humRisk: 80,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'MAIZE': _CropProfile(
      tempWarn: 32,
      tempRisk: 36,
      humWarn: 75,
      humRisk: 84,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'CORN': _CropProfile(
      tempWarn: 32,
      tempRisk: 36,
      humWarn: 75,
      humRisk: 84,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'SOY': _CropProfile(
      tempWarn: 30,
      tempRisk: 34,
      humWarn: 72,
      humRisk: 80,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'COTTON': _CropProfile(
      tempWarn: 31,
      tempRisk: 35,
      humWarn: 72,
      humRisk: 82,
      co2Warn: 900,
      co2Risk: 1200,
    ),
    'DEFAULT': _CropProfile(
      tempWarn: 32,
      tempRisk: 36,
      humWarn: 75,
      humRisk: 85,
      co2Warn: 900,
      co2Risk: 1200,
    ),
  };

  static const Map<String, _Geo> _farmerCoords = {
    'VADODARA': _Geo(22.3072, 73.1812),
    'BARODA': _Geo(22.3072, 73.1812),
    'AHMEDABAD': _Geo(23.0225, 72.5714),
    'SURAT': _Geo(21.1702, 72.8311),
    'PUNE': _Geo(18.5204, 73.8567),
    'MUMBAI': _Geo(19.0760, 72.8777),
    'NASHIK': _Geo(19.9975, 73.7898),
    'NAGPUR': _Geo(21.1458, 79.0882),
    'DELHI': _Geo(28.6139, 77.2090),
    'BENGALURU': _Geo(12.9716, 77.5946),
    'HYDERABAD': _Geo(17.3850, 78.4867),
    'CHENNAI': _Geo(13.0827, 80.2707),
    'KOLKATA': _Geo(22.5726, 88.3639),
  };

  static const Map<String, _Geo> _marketCoords = {
    'VADODARA_MANDI': _Geo(22.3072, 73.1812),
    'AHMEDABAD_MANDI': _Geo(23.0225, 72.5714),
    'SURAT_MANDI': _Geo(21.1702, 72.8311),
    'PUNE_MANDI': _Geo(18.5204, 73.8567),
    'MUMBAI_MANDI': _Geo(19.0760, 72.8777),
    'NASHIK_MANDI': _Geo(19.9975, 73.7898),
    'NAGPUR_MANDI': _Geo(21.1458, 79.0882),
    'DELHI_AZADPUR_MANDI': _Geo(28.7041, 77.1025),
    'BENGALURU_MANDI': _Geo(12.9716, 77.5946),
    'HYDERABAD_MANDI': _Geo(17.3850, 78.4867),
    'CHENNAI_MANDI': _Geo(13.0827, 80.2707),
    'KOLKATA_MANDI': _Geo(22.5726, 88.3639),
  };

  static const Map<String, double> _marketPriceMultiplier = {
    'VADODARA_MANDI': 1.00,
    'AHMEDABAD_MANDI': 1.06,
    'SURAT_MANDI': 0.98,
    'PUNE_MANDI': 1.03,
    'MUMBAI_MANDI': 1.08,
    'NASHIK_MANDI': 1.01,
    'NAGPUR_MANDI': 1.00,
    'DELHI_AZADPUR_MANDI': 1.07,
    'BENGALURU_MANDI': 1.05,
    'HYDERABAD_MANDI': 1.04,
    'CHENNAI_MANDI': 1.03,
    'KOLKATA_MANDI': 1.02,
  };

  static const Map<String, double> _transportCostPerKm = {
    'MINI_TRUCK': 22,
    'TRUCK_10T': 30,
    'REEFER': 38,
  };

  static const Map<String, double> _transportSpeed = {
    'MINI_TRUCK': 42,
    'TRUCK_10T': 36,
    'REEFER': 34,
  };

  static int daysBetween(DateTime a, DateTime b) {
    return ((b.millisecondsSinceEpoch - a.millisecondsSinceEpoch) /
            (1000 * 60 * 60 * 24))
        .ceil();
  }

  static StorageRiskLevel _higherRisk(StorageRiskLevel a, StorageRiskLevel b) {
    if (a == StorageRiskLevel.risk || b == StorageRiskLevel.risk) {
      return StorageRiskLevel.risk;
    }
    if (a == StorageRiskLevel.warning || b == StorageRiskLevel.warning) {
      return StorageRiskLevel.warning;
    }
    return StorageRiskLevel.safe;
  }

  static _CropProfile _cropProfile(String cropName) {
    final upper = cropName.toUpperCase();
    for (final entry in _cropProfiles.entries) {
      if (entry.key == 'DEFAULT') continue;
      if (upper.contains(entry.key)) return entry.value;
    }
    return _cropProfiles['DEFAULT']!;
  }

  static BlockRiskResult evaluateBlockRisk({
    required int daysLeft,
    required String cropName,
    double? temperatureC,
    double? humidityPct,
    double? co2Ppm,
  }) {
    final reasons = <String>[];
    var level = StorageRiskLevel.safe;

    if (daysLeft < 0) {
      level = StorageRiskLevel.risk;
      reasons.add('Lot already expired');
    } else if (daysLeft <= 7) {
      level = StorageRiskLevel.warning;
      reasons.add('Low shelf life ($daysLeft day${daysLeft == 1 ? '' : 's'})');
    }

    final profile = _cropProfile(cropName);

    void setRisk(String msg) {
      level = StorageRiskLevel.risk;
      reasons.add(msg);
    }

    void setWarn(String msg) {
      if (level != StorageRiskLevel.risk) level = StorageRiskLevel.warning;
      reasons.add(msg);
    }

    if (temperatureC != null) {
      if (temperatureC >= profile.tempRisk) {
        setRisk('Temp high (${temperatureC.toStringAsFixed(1)}C)');
      } else if (temperatureC >= profile.tempWarn) {
        setWarn('Temp elevated (${temperatureC.toStringAsFixed(1)}C)');
      }
    }

    if (humidityPct != null) {
      if (humidityPct >= profile.humRisk) {
        setRisk('Humidity high (${humidityPct.toStringAsFixed(1)}%)');
      } else if (humidityPct >= profile.humWarn) {
        setWarn('Humidity elevated (${humidityPct.toStringAsFixed(1)}%)');
      }
    }

    if (co2Ppm != null) {
      if (co2Ppm >= profile.co2Risk) {
        setRisk('CO2 high (${co2Ppm.toStringAsFixed(1)} ppm)');
      } else if (co2Ppm >= profile.co2Warn) {
        setWarn('CO2 elevated (${co2Ppm.toStringAsFixed(1)} ppm)');
      }
    }

    if (reasons.isEmpty) {
      reasons.add('All monitored conditions within safe limits');
    }

    return BlockRiskResult(level: level, reasons: reasons);
  }

  static Map<String, BlockRiskResult> buildBlockRiskMap(
    List<StorageItem> inventory, {
    double? liveTemperatureC,
    double? liveHumidityPct,
    double? liveCo2Ppm,
  }) {
    final map = <String, BlockRiskResult>{};
    final active = inventory.where((it) => !it.isSold).toList();
    final now = DateTime.now();

    for (var i = 1; i <= 9; i++) {
      final blockName = 'BLOCK_${i.toString().padLeft(2, '0')}';
      final rows = active.where((it) => it.location == blockName).toList();

      if (rows.isEmpty) {
        if (i == 5) {
          map[blockName] = evaluateBlockRisk(
            daysLeft: 999,
            cropName: 'UNASSIGNED',
            temperatureC: liveTemperatureC,
            humidityPct: liveHumidityPct,
            co2Ppm: liveCo2Ppm,
          );
        } else {
          map[blockName] = const BlockRiskResult(
            level: StorageRiskLevel.safe,
            reasons: ['Block vacant'],
          );
        }
        continue;
      }

      var aggregateLevel = StorageRiskLevel.safe;
      final aggregateReasons = <String>{};
      for (final row in rows) {
        final daysLeft = row.expiryDate.difference(now).inDays;
        final eval = evaluateBlockRisk(
          daysLeft: daysLeft,
          cropName: row.name,
          temperatureC: i == 5 ? liveTemperatureC : null,
          humidityPct: i == 5 ? liveHumidityPct : null,
          co2Ppm: i == 5 ? liveCo2Ppm : null,
        );
        aggregateLevel = _higherRisk(aggregateLevel, eval.level);
        aggregateReasons.addAll(eval.reasons);
      }
      map[blockName] = BlockRiskResult(
        level: aggregateLevel,
        reasons: aggregateReasons.toList(),
      );
    }

    return map;
  }

  static WarehouseKpi buildWarehouseKpi(
    List<StorageItem> inventory,
    Map<String, BlockRiskResult> riskMap,
  ) {
    final active = inventory.where((it) => !it.isSold).toList();
    final occupied = <String>{};
    for (final item in active) {
      if (item.location.startsWith('BLOCK_')) occupied.add(item.location);
    }

    var warning = 0;
    var risk = 0;
    for (var i = 1; i <= 9; i++) {
      final blockName = 'BLOCK_${i.toString().padLeft(2, '0')}';
      final row = riskMap[blockName];
      if (row == null) continue;
      if (row.level == StorageRiskLevel.warning) warning += 1;
      if (row.level == StorageRiskLevel.risk) risk += 1;
    }

    final rescued = inventory.where((it) => it.isSold).length;
    return WarehouseKpi(
      occupied: occupied.length,
      warning: warning,
      risk: risk,
      rescued: rescued,
    );
  }

  static String normalizePlaceKey(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9 ]'), '');
  }

  static double _haversineKm(_Geo a, _Geo b) {
    double toRad(double deg) => (deg * 3.141592653589793) / 180;
    final dLat = toRad(b.lat - a.lat);
    final dLon = toRad(b.lon - a.lon);
    final lat1 = toRad(a.lat);
    final lat2 = toRad(b.lat);
    final h = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2));
    return 2 * 6371 * asin(sqrt(h));
  }

  static double _qtyToKg(StorageItem item) {
    final q = item.qty;
    final unit = item.unit.toLowerCase();
    if (q <= 0) return 0;
    if (unit.contains('quintal')) return q * 100;
    if (unit.contains('tonne') || unit.contains('ton')) return q * 1000;
    if (unit.contains('bag')) return q * 50;
    return q;
  }

  static double _estimateBasePricePerKg(StorageItem item) {
    final n = item.name.toUpperCase();
    if (n.contains('RICE')) return 32;
    if (n.contains('WHEAT')) return 24.5;
    if (n.contains('MAIZE') || n.contains('CORN')) return 18.5;
    if (n.contains('SOY')) return 46;
    if (n.contains('COTTON')) return 72;
    return 24;
  }

  static ({String label, _Geo? coords}) _resolveFarmerCoords(String rawInput) {
    final typed = normalizePlaceKey(rawInput);
    if (typed.isEmpty) {
      return (label: 'VADODARA', coords: _farmerCoords['VADODARA']);
    }

    if (_farmerCoords.containsKey(typed)) {
      return (label: typed, coords: _farmerCoords[typed]);
    }

    for (final key in _farmerCoords.keys) {
      if (typed.contains(key) || key.contains(typed)) {
        return (label: typed, coords: _farmerCoords[key]);
      }
    }
    return (label: typed, coords: null);
  }

  static ({String market, double distanceKm}) _nearestMarket(_Geo farmer) {
    String bestMarket = 'VADODARA_MANDI';
    double bestDistance = 999999;
    for (final entry in _marketCoords.entries) {
      final distance = _haversineKm(farmer, entry.value);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMarket = entry.key;
      }
    }
    return (market: bestMarket, distanceKm: bestDistance);
  }

  static DispatchMarketEconomics getBestProfitableMarket(
    StorageItem item,
    String farmerLocation,
    String transportMode,
  ) {
    final farmer = _resolveFarmerCoords(farmerLocation);
    final farmerCoords = farmer.coords ?? _farmerCoords['VADODARA']!;
    final qtyKg = _qtyToKg(item);
    final basePricePerKg = _estimateBasePricePerKg(item);
    final kmCost = _transportCostPerKm[transportMode] ?? 26;
    final handlingCost = 250 + qtyKg * 0.12;

    ({String marketName, double distanceKm, double netPayout, double logisticsCost})
    best = (
      marketName: 'VADODARA_MANDI',
      distanceKm: 80,
      netPayout: -999999,
      logisticsCost: 0,
    );

    ({String marketName, double distanceKm, double netPayout})
    nearest = (
      marketName: 'VADODARA_MANDI',
      distanceKm: 999999,
      netPayout: 0,
    );

    for (final entry in _marketCoords.entries) {
      final marketName = entry.key;
      final distanceKm = _haversineKm(farmerCoords, entry.value);
      final grossValue =
          qtyKg * basePricePerKg * (_marketPriceMultiplier[marketName] ?? 1);
      final logisticsCost = handlingCost + distanceKm * kmCost;
      final netPayout = grossValue - logisticsCost;

      if (netPayout > best.netPayout) {
        best = (
          marketName: marketName,
          distanceKm: distanceKm,
          netPayout: netPayout,
          logisticsCost: logisticsCost,
        );
      }
      if (distanceKm < nearest.distanceKm) {
        nearest = (
          marketName: marketName,
          distanceKm: distanceKm,
          netPayout: netPayout,
        );
      }
    }

    final gainVsNearest = best.netPayout - nearest.netPayout;
    return DispatchMarketEconomics(
      bestMarket: best.marketName,
      bestNetPayout: best.netPayout.round(),
      bestLogisticsCost: best.logisticsCost.round(),
      bestDistanceKm: double.parse(best.distanceKm.toStringAsFixed(1)),
      nearestMarket: nearest.marketName,
      gainVsNearest: gainVsNearest.round(),
    );
  }

  static DispatchRecommendation getDispatchRecommendation(
    StorageItem item,
    String farmerLocation,
    String transportMode,
  ) {
    final farmer = _resolveFarmerCoords(farmerLocation);
    final nearest = farmer.coords != null
        ? _nearestMarket(farmer.coords!)
        : (market: 'VADODARA_MANDI', distanceKm: 80.0);

    final speed = _transportSpeed[transportMode] ?? 38;
    final travelHours = nearest.distanceKm / speed + 0.6;
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    var priority = 'HOLD';
    if (daysLeft <= 2 || travelHours > 6) {
      priority = 'DISPATCH_NOW';
    } else if (daysLeft <= 7 || travelHours > 4) {
      priority = 'DISPATCH_TODAY';
    } else if (daysLeft <= 15) {
      priority = 'DISPATCH_24H';
    }

    final windowText = switch (priority) {
      'DISPATCH_NOW' => 'WINDOW: < 6 HOURS',
      'DISPATCH_TODAY' => 'WINDOW: TODAY',
      'DISPATCH_24H' => 'WINDOW: < 24 HOURS',
      _ => 'WINDOW: FLEXIBLE',
    };

    return DispatchRecommendation(
      distanceKm: double.parse(nearest.distanceKm.toStringAsFixed(1)),
      travelHours: travelHours,
      priority: priority,
      etaLabel: '${travelHours.toStringAsFixed(1)} HRS',
      windowText: windowText,
      daysLeft: daysLeft,
      nearestMarket: nearest.market,
      farmerLabel: farmer.label,
    );
  }

  static String riskLabel(StorageRiskLevel level) {
    return switch (level) {
      StorageRiskLevel.safe => 'SAFE',
      StorageRiskLevel.warning => 'WARNING',
      StorageRiskLevel.risk => 'RISK',
    };
  }
}
