import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';
import '../providers/theme_provider.dart';
import 'crops.dart';
import 'storage_hud.dart';
import 'market_radar.dart';
import 'krushiai.dart';
import '../widgets/tactical_line_chart.dart';
import '../widgets/infinity_loader.dart';
import '../providers/module_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/market_provider.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  double _pullDistance = 0;
  bool _refreshArmed = false;
  Future<_DecisionContext>? _decisionFuture;
  final String _decisionCity = 'Mumbai';

  static const _weatherApiKey = '3RZRLWMFYCVRCPUMYT2R8ECFG';

  Future<void> _handleRefresh(SensorProvider sensorProvider) async {
    setState(() => _isRefreshing = true);
    await sensorProvider.refresh();
    if (mounted) {
      setState(() {
        _decisionFuture = null;
      });
    }
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  Future<_DecisionContext> _fetchDecisionContext(
    SensorProvider sensorProvider,
  ) async {
    await sensorProvider.fetchOutdoorLatest();
    final outdoorTemp = sensorProvider.currentOutdoorTemp;
    final outdoorHumidity = sensorProvider.currentOutdoorHumidity;
    final outdoorSoilMoisture = sensorProvider.currentOutdoorSoilMoisture;

    if (outdoorTemp == null ||
        outdoorHumidity == null ||
        outdoorSoilMoisture == null) {
      throw Exception('NO_OUTDOOR_DATA');
    }

    final uri = Uri.parse(
      'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/$_decisionCity?unitGroup=metric&key=$_weatherApiKey&contentType=json',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 6));
    double rainProb = 0;
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final current = data['currentConditions'] as Map<String, dynamic>?;
      if (current != null && current['precipprob'] != null) {
        rainProb = (current['precipprob'] as num).toDouble();
      } else if (data['days'] is List && (data['days'] as List).isNotEmpty) {
        final day0 = (data['days'] as List).first as Map<String, dynamic>;
        rainProb = (day0['precipprob'] as num?)?.toDouble() ?? 0;
      }
    }

    return _DecisionContext(
      soilMoisture: outdoorSoilMoisture,
      temperature: outdoorTemp,
      humidity: outdoorHumidity,
      rainProb: rainProb,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final moduleProvider = Provider.of<ModuleProvider>(context);
    final sensorProvider = Provider.of<SensorProvider>(context);
    final storageProvider = Provider.of<StorageProvider>(context);
    final marketProvider = Provider.of<MarketProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.02,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                repeat: ImageRepeat.repeat,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                if (_selectedIndex == 0)
                  _buildHeader(themeProvider, moduleProvider),
                Expanded(
                  child: _buildBody(
                    isDark,
                    moduleProvider,
                    themeProvider,
                    sensorProvider,
                    storageProvider,
                    marketProvider,
                  ),
                ),
              ],
            ),
          ),

          _buildBottomHUDNav(isDark),
        ],
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    ModuleProvider moduleProvider,
    ThemeProvider themeProvider,
    SensorProvider sensorProvider,
    StorageProvider storageProvider,
    MarketProvider marketProvider,
  ) {
    switch (_selectedIndex) {
      case 0:
        return Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (_isRefreshing) return false;
                if (notification is ScrollStartNotification) {
                  _pullDistance = 0;
                  _refreshArmed = false;
                } else if (notification is ScrollUpdateNotification &&
                    notification.metrics.pixels < 0) {
                  _pullDistance = -notification.metrics.pixels;
                  if (_pullDistance > 60 && !_refreshArmed) {
                    _refreshArmed = true;
                    _handleRefresh(sensorProvider);
                  }
                } else if (notification is OverscrollNotification &&
                    notification.overscroll < 0) {
                  _pullDistance += -notification.overscroll;
                  if (_pullDistance > 60 && !_refreshArmed) {
                    _refreshArmed = true;
                    _handleRefresh(sensorProvider);
                  }
                } else if (notification is ScrollEndNotification) {
                  _pullDistance = 0;
                  _refreshArmed = false;
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _buildModuleSelector(moduleProvider, isDark),
                    const SizedBox(height: 25),
                    _buildMetricsGrid(
                      isDark,
                      moduleProvider.currentModule,
                      sensorProvider,
                    ),
                    const SizedBox(height: 25),
                    moduleProvider.currentModule == AgriModule.indoor
                        ? _buildStorageAdvisory(
                            isDark,
                            storageProvider,
                            marketProvider,
                          )
                        : _buildTelemetryChart(
                            isDark,
                            moduleProvider.currentModule,
                            sensorProvider,
                          ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _isRefreshing ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cyberBlack.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.neonGreen.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const InfinityLoader(size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'SYNCING_STREAM...',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        return const CropsHubScreen();
      case 2:
        return const StorageScreen();
      case 3:
        return const MarketRadarScreen();
      case 4:
        return const KrushiAIScreen();
      default:
        return Center(
          child: Text(
            'SYSTEM_SYNC_REQUIRED',
            style: TextStyle(
              color: isDark ? AppColors.neonGreen : AppColors.lightText,
              fontFamily: 'monospace',
            ),
          ),
        );
    }
  }

  Widget _buildHeader(
    ThemeProvider themeProvider,
    ModuleProvider moduleProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                color: isDark ? AppColors.neonGreen : AppColors.lightText,
                alignment: Alignment.center,
                child: Text(
                  'AS',
                  style: TextStyle(
                    color: isDark ? AppColors.cyberBlack : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Text(
                  'AGRI-OS [V2.1_SYNC]',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Theme toggle removed; app is dark-only.
              MilitaryTag(text: '[ BETA V2 ]', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSelector(ModuleProvider moduleProvider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusPulse(isDark: isDark),
            const SizedBox(width: 10),
            Text(
              'COMMAND_CENTER / ',
              style: TextStyle(
                color: AppColors.getMutedText(isDark),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            PopupMenuButton<AgriModule>(
              onSelected: (module) => moduleProvider.setModule(module),
              offset: const Offset(0, 25),
              color: isDark ? AppColors.cyberBlack : Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moduleProvider.moduleName,
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.lightText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                  ),
                ],
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: AgriModule.indoor,
                  child: Text(
                    'INDOOR_MODULE',
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.lightText,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: AgriModule.outdoor,
                  child: Text(
                    'OUTDOOR_MODULE',
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.lightText,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(
    bool isDark,
    AgriModule module,
    SensorProvider sensorProvider,
  ) {
    if (module == AgriModule.indoor) {
      final data = sensorProvider.currentIndoorData;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.2,
        children: [
          MetricCard(
            icon: Icons.thermostat,
            label: 'TEMPERATURE',
            value: data != null
                ? '${data.temperature.toStringAsFixed(1)}°C'
                : '--°C',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.water_drop,
            label: 'HUMIDITY',
            value: data != null
                ? '${data.humidity.toStringAsFixed(1)}%'
                : '--%',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.science,
            label: 'AMMONIA_PPM',
            value: data != null ? data.ammonia.toStringAsFixed(2) : '--',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.co2,
            label: 'CO2_DENSITY',
            value: data != null ? '${data.co2.toStringAsFixed(0)} PPM' : '--',
            trend: 'NOMINAL',
            isDark: isDark,
          ),
        ],
      );
    } else {
      final outdoorTemp = sensorProvider.currentOutdoorTemp;
      final outdoorHumidity = sensorProvider.currentOutdoorHumidity;
      final outdoorSoilMoisture = sensorProvider.currentOutdoorSoilMoisture;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.2,
        children: [
          MetricCard(
            icon: Icons.thermostat,
            label: 'TEMPERATURE',
            value: outdoorTemp != null
                ? '${outdoorTemp.toStringAsFixed(1)}°C'
                : '--°C',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.water_drop,
            label: 'HUMIDITY',
            value: outdoorHumidity != null
                ? '${outdoorHumidity.toStringAsFixed(1)}%'
                : '--%',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.grass,
            label: 'SOIL_MOISTURE',
            value: outdoorSoilMoisture != null
                ? outdoorSoilMoisture.toStringAsFixed(1)
                : '--',
            trend: 'LIVE',
            isDark: isDark,
          ),
          MetricCard(
            icon: Icons.science,
            label: 'SOIL_PH',
            value: '6.8 pH',
            trend: 'OPTIMAL',
            isDark: isDark,
          ),
        ],
      );
    }
  }

  Widget _buildTelemetryChart(
    bool isDark,
    AgriModule module,
    SensorProvider sensorProvider,
  ) {
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;
    final moduleTag = module == AgriModule.indoor ? 'INDOOR' : 'OUTDOOR';

    if (module == AgriModule.outdoor) {
      _decisionFuture ??= _fetchDecisionContext(sensorProvider);
      return FutureBuilder<_DecisionContext>(
        future: _decisionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CyberCard(
              height: 250,
              child: Center(child: InfinityLoader(size: 28)),
            );
          }

          if (!snapshot.hasData) {
            return CyberCard(
              height: 250,
              child: Center(
                child: Text(
                  'DECISION_ENGINE_OFFLINE',
                  style: TextStyle(
                    color: AppColors.getMutedText(isDark),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }

          final ctx = snapshot.data!;
          final decision = _computeDecision(ctx);
          return CyberCard(
            height: 230,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OUTDOOR_DECISION_ENGINE',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getCard(isDark),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.getBorder(isDark).withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        decision.decision,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.neonGreen
                              : AppColors.lightBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.neonGreen
                                      : AppColors.lightBlue)
                                  .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(decision.confidence * 100).round()}%',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.neonGreen
                                : AppColors.lightBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      'SOIL',
                      '${ctx.soilMoisture.toStringAsFixed(0)}%',
                      isDark,
                    ),
                    _buildInfoChip(
                      'RAIN',
                      '${ctx.rainProb.toStringAsFixed(0)}%',
                      isDark,
                    ),
                    _buildInfoChip(
                      'TEMP',
                      '${ctx.temperature.toStringAsFixed(0)}°C',
                      isDark,
                    ),
                    _buildInfoChip(
                      'HUM',
                      '${ctx.humidity.toStringAsFixed(0)}%',
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...decision.reasons
                    .take(3)
                    .map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.neonGreen
                                    : AppColors.lightBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: AppColors.getMutedText(isDark),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      );
    }

    // Data for the 4 categories
    List<double> tempData = [25, 26, 25.5, 27, 28, 27.5, 28.4];
    List<double> humData = [60, 62, 61, 63, 62, 60, 62];
    List<double> ammData = [10, 11, 12, 11.5, 12.8, 12, 12.5];
    List<double> co2Data = [400, 410, 405, 420, 415, 418, 420];

    if (module == AgriModule.indoor &&
        sensorProvider.historicalIndoorData.isNotEmpty) {
      tempData = sensorProvider.historicalIndoorData
          .map((d) => d.temperature)
          .toList();
      humData = sensorProvider.historicalIndoorData
          .map((d) => d.humidity)
          .toList();
      ammData = sensorProvider.historicalIndoorData
          .map((d) => d.ammonia)
          .toList();
      co2Data = sensorProvider.historicalIndoorData.map((d) => d.co2).toList();
    }

    return CyberCard(
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${moduleTag}_TELEMETRY',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              if (module == AgriModule.indoor && sensorProvider.isLoading)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.neonGreen),
                  ),
                )
              else
                Icon(Icons.show_chart, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Stack(
              children: [
                // Temperature (Red)
                TacticalLineChart(
                  data: tempData,
                  color: Colors.red,
                  min: 15,
                  max: 40,
                ),
                // Humidity (Blue)
                TacticalLineChart(
                  data: humData,
                  color: Colors.blue,
                  min: 30,
                  max: 90,
                ),
                // Ammonia (Green)
                if (module == AgriModule.indoor)
                  TacticalLineChart(
                    data: ammData,
                    color: Colors.green,
                    min: 0,
                    max: 30,
                  ),
                // CO2
                if (module == AgriModule.indoor)
                  TacticalLineChart(
                    data: co2Data,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black,
                    min: 300,
                    max: 1000,
                  ),

                // Overlay text
                Center(
                  child: Text(
                    sensorProvider.isLoading
                        ? '// SYNCING_STREAMS...'
                        : '// MULTI_STREAM_ACTIVE',
                    style: TextStyle(
                      color: AppColors.getMutedText(isDark).withOpacity(0.3),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartLabel('TEMP', Colors.red, isDark),
              _chartLabel('HUM', Colors.blue, isDark),
              if (module == AgriModule.indoor)
                _chartLabel('NH3', Colors.green, isDark),
              if (module == AgriModule.indoor)
                _chartLabel(
                  'CO2',
                  isDark ? Colors.white : Colors.black,
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, bool isDark) {
    final borderColor = AppColors.getBorder(isDark);
    final textColor = isDark ? AppColors.neonGreen : AppColors.lightBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.getCard(isDark).withOpacity(0.5),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildStorageAdvisory(
    bool isDark,
    StorageProvider storageProvider,
    MarketProvider marketProvider,
  ) {
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;
    final muted = AppColors.getMutedText(isDark);
    final items = storageProvider.inventory.where((it) => !it.isSold).toList();
    final now = DateTime.now();

    int? nearestExpiryDays;
    for (final item in items) {
      final days = item.expiryDate.difference(now).inDays;
      if (nearestExpiryDays == null || days < nearestExpiryDays) {
        nearestExpiryDays = days;
      }
    }

    final advisories = <_Advisory>[];
    for (final price in marketProvider.prices) {
      final matching = items
          .where(
            (it) => it.name.toUpperCase().contains(price.crop.toUpperCase()),
          )
          .toList();
      if (matching.isEmpty) continue;

      final minExpiryDays = matching
          .map((it) => it.expiryDate.difference(now).inDays)
          .reduce((a, b) => a < b ? a : b);
      final trend = price.trend.toUpperCase();
      final isDropping = trend == 'BEARISH' || trend == 'WEAK';
      final isRising = trend == 'BULLISH' || trend == 'STRONG';

      if (minExpiryDays <= 0) {
        advisories.add(
          _Advisory(
            priority: 0,
            color: Colors.redAccent,
            text: '${price.crop}: EXPIRED — SELL/PROCESS IMMEDIATELY',
          ),
        );
      } else if (minExpiryDays <= 7) {
        advisories.add(
          _Advisory(
            priority: 1,
            color: Colors.orangeAccent,
            text: '${price.crop}: ${minExpiryDays} DAYS LEFT — SELL NOW',
          ),
        );
      } else if (minExpiryDays <= 30) {
        advisories.add(
          _Advisory(
            priority: 2,
            color: Colors.amber,
            text: '${price.crop}: ${minExpiryDays} DAYS LEFT — PLAN SALE',
          ),
        );
      } else if (isDropping) {
        advisories.add(
          _Advisory(
            priority: 3,
            color: Colors.orange,
            text: '${price.crop}: PRICE DROPPING — CONSIDER SELLING',
          ),
        );
      } else if (isRising) {
        advisories.add(
          _Advisory(
            priority: 4,
            color: Colors.green,
            text: '${price.crop}: PRICE RISING — HOLD FOR BETTER RATE',
          ),
        );
      } else {
        advisories.add(
          _Advisory(
            priority: 5,
            color: Colors.lightGreen,
            text: '${price.crop}: MARKET STABLE — HOLD OK',
          ),
        );
      }
    }

    advisories.sort((a, b) => a.priority.compareTo(b.priority));
    final topAdvisories = advisories.take(3).toList();

    return CyberCard(
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INDOOR_STORAGE_BRIEF',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Icon(Icons.inventory_2, color: color, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            items.isEmpty
                ? 'NO_ACTIVE_STORAGE_FOUND'
                : 'LOTS: ${items.length} • NEAREST EXPIRY: ${nearestExpiryDays ?? '--'} DAYS',
            style: TextStyle(
              color: muted,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'ADD CROPS IN STORAGE TO GET SELL ALERTS',
                      style: TextStyle(
                        color: muted.withOpacity(0.8),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: topAdvisories.isEmpty
                        ? [
                            Text(
                              'NO MARKET SIGNALS YET — STORAGE OK',
                              style: TextStyle(
                                color: muted,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ]
                        : topAdvisories
                              .map(
                                (advice) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(
                                          top: 5,
                                          right: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: advice.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          advice.text,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chartLabel(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(width: 8, height: 2, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.getMutedText(isDark),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildBottomHUDNav(bool isDark) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: CyberCard(
        height: 70,
        padding: EdgeInsets.zero,
        showCorner: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_customize, 'DASH', isDark),
            _navItem(1, Icons.grass, 'CROPS', isDark),
            _navItem(4, Icons.auto_awesome, 'KRUSHI_AI', isDark),
            _navItem(2, Icons.inventory_2, 'STORAGE', isDark),
            _navItem(3, Icons.notifications, 'MARKET', isDark),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool isDark) {
    bool isSelected = _selectedIndex == index;
    final selectedColor = isDark ? AppColors.neonGreen : AppColors.lightText;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? selectedColor : AppColors.getMutedText(isDark),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? selectedColor
                  : AppColors.getMutedText(isDark),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionContext {
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final double rainProb;

  _DecisionContext({
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    required this.rainProb,
  });
}

class _DecisionResult {
  final String decision;
  final double confidence;
  final List<String> reasons;

  _DecisionResult({
    required this.decision,
    required this.confidence,
    required this.reasons,
  });
}

_DecisionResult _computeDecision(_DecisionContext ctx) {
  final hotStress = ctx.temperature >= 32;
  final veryDry = ctx.soilMoisture < 20;
  final rainLikely = ctx.rainProb > 60;
  final reasons = <String>[];

  String decision = 'HOLD_COMMAND';
  double confidence = 0.6;

  if (veryDry && !rainLikely) {
    decision = 'IRRIGATION_ON';
    reasons.add('Soil moisture is critically low.');
    reasons.add('Rain probability is not sufficient to recover moisture.');
    reasons.add(
      hotStress
          ? 'Temperature is high, increasing evapotranspiration.'
          : 'Temperature is within normal range.',
    );
    confidence = hotStress ? 0.88 : 0.82;
  } else if (veryDry && rainLikely) {
    decision = 'HOLD_COMMAND';
    reasons.add('Soil moisture is low but rainfall is likely soon.');
    reasons.add('Irrigation now could waste water or cause runoff.');
    reasons.add(
      hotStress
          ? 'Temperature is high; monitor closely.'
          : 'No critical heat stress detected.',
    );
    confidence = hotStress ? 0.7 : 0.75;
  } else if (!veryDry && rainLikely) {
    decision = 'IRRIGATION_OFF';
    reasons.add('Soil moisture is adequate.');
    reasons.add('Rain probability is high in the next 24h.');
    reasons.add('Conserving water budget.');
    confidence = 0.78;
  } else {
    decision = 'HOLD_COMMAND';
    reasons.add('Soil moisture is moderate.');
    reasons.add(
      hotStress
          ? 'Temperature is high; monitor conditions.'
          : 'No critical stress detected.',
    );
    reasons.add('Monitor conditions before activating irrigation.');
    confidence = 0.65;
  }

  return _DecisionResult(
    decision: decision,
    confidence: confidence,
    reasons: reasons,
  );
}

class _Advisory {
  final int priority;
  final Color color;
  final String text;

  _Advisory({required this.priority, required this.color, required this.text});
}

class MilitaryTag extends StatelessWidget {
  final String text;
  final bool isDark;
  const MilitaryTag({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class StatusPulse extends StatefulWidget {
  final bool isDark;
  const StatusPulse({super.key, required this.isDark});

  @override
  State<StatusPulse> createState() => _StatusPulseState();
}

class _StatusPulseState extends State<StatusPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark ? AppColors.neonGreen : AppColors.lightText;
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 10)],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool isDark;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: trend.startsWith('-') ? AppColors.errorRed : color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
