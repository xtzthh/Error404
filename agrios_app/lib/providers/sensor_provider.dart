import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class SensorData {
  final double temperature;
  final double humidity;
  final double ammonia;
  final double co2;
  final bool fireAlert;
  final bool rodentAlert;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.co2,
    required this.fireAlert,
    required this.rodentAlert,
    required this.timestamp,
  });
}

class SensorProvider with ChangeNotifier {
  final String _channelId = "3214038";
  final String _readKey = "XIZY6ZXHB5VCKY2T";
  final String _outdoorChannelId = "3214977";
  final String _outdoorReadKey = "4A6UOTUS8ORX2GXH";

  // MQTT Config (Using same credentials for now, though unique ID is better)
  final String _mqttServer = "mqtt3.thingspeak.com";
  final String _mqttClientId =
      "App_HUD_${DateTime.now().millisecondsSinceEpoch}";
  final String _mqttUser = "MxMEESQqLxonJR8WJSYpMxc";
  final String _mqttPass = "0CAsGvDwP+YYkltOOgYrvsb1";

  MqttServerClient? _client;
  SensorData? _currentIndoorData;
  List<SensorData> _historicalIndoorData = [];
  double? _currentOutdoorTemp;
  double? _currentOutdoorHumidity;
  double? _currentOutdoorSoilMoisture;
  DateTime? _outdoorTempTimestamp;
  Timer? _outdoorTimer;
  bool _isLoading = false;
  bool _isMqttConnected = false;

  SensorData? get currentIndoorData => _currentIndoorData;
  List<SensorData> get historicalIndoorData => _historicalIndoorData;
  double? get currentOutdoorTemp => _currentOutdoorTemp;
  double? get currentOutdoorHumidity => _currentOutdoorHumidity;
  double? get currentOutdoorSoilMoisture => _currentOutdoorSoilMoisture;
  DateTime? get outdoorTempTimestamp => _outdoorTempTimestamp;
  bool get isLoading => _isLoading;
  bool get isMqttConnected => _isMqttConnected;

  SensorProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchHistoricalData();
    await fetchOutdoorLatest();
    _startOutdoorPolling();
    _setupMqtt();
  }

  void _startOutdoorPolling() {
    _outdoorTimer?.cancel();
    _outdoorTimer =
        Timer.periodic(const Duration(seconds: 20), (_) => fetchOutdoorLatest());
  }

  Future<void> _setupMqtt() async {
    _client = MqttServerClient(_mqttServer, _mqttClientId);
    _client!.port = 1883;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onMqttDisconnected;
    _client!.onConnected = _onMqttConnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_mqttClientId)
        .authenticateAs(_mqttUser, _mqttPass)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      debugPrint('MQTT Connection failed: $e');
      _client!.disconnect();
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _isMqttConnected = true;
      // Subscribe to the publish topic to see updates (ThingSpeak allows subscribing to feeds)
      // For ThingSpeak, subscription topic is: channels/<channelID>/subscribe/json
      final subscribeTopic = 'channels/$_channelId/subscribe/json';
      _client!.subscribe(subscribeTopic, MqttQos.atMostOnce);

      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          message.payload.message,
        );

        _processMqttUpdate(payload);
      });
    }
  }

  void _processMqttUpdate(String jsonString) {
    try {
      final data = json.decode(jsonString);
      // INDOOR MAPPING: 1:Temp, 2:Hum, 3:CO2, 4:NH3, 5:Fire flag
      _currentIndoorData = SensorData(
        temperature: double.tryParse(data['field1']?.toString() ?? '0') ?? 0.0,
        humidity: double.tryParse(data['field2']?.toString() ?? '0') ?? 0.0,
        ammonia: double.tryParse(data['field4']?.toString() ?? '0') ?? 0.0,
        co2: double.tryParse(data['field3']?.toString() ?? '0') ?? 0.0,
        fireAlert:
            (double.tryParse(data['field5']?.toString() ?? '0') ?? 0.0) > 0,
        rodentAlert:
            (double.tryParse(data['field6']?.toString() ?? '0') ?? 0.0) > 0,
        timestamp: DateTime.now(),
      );

      debugPrint(
        '🛰️ MQTT_UPDATE_PARSED: ${_currentIndoorData!.temperature}°C',
      );

      _historicalIndoorData.add(_currentIndoorData!);
      if (_historicalIndoorData.length > 30) {
        _historicalIndoorData.removeAt(0);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing MQTT update: $e');
    }
  }

  void _onMqttConnected() {
    debugPrint('CONNECTED TO MQTT HUD STREAM');
    _isMqttConnected = true;
    notifyListeners();
  }

  void _onMqttDisconnected() {
    debugPrint('DISCONNECTED FROM MQTT HUD STREAM');
    _isMqttConnected = false;
    notifyListeners();
    // Only attempt reconnect if it was actually connected before
    // This stops the bad credentials infinite loop
  }

  Future<void> fetchHistoricalData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final url = Uri.parse(
        'https://api.thingspeak.com/channels/$_channelId/feeds.json?api_key=$_readKey&results=30',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data['feeds'] as List;
        _historicalIndoorData = feeds.map((f) => _parseFeed(f)).toList();
        if (_historicalIndoorData.isNotEmpty) {
          _currentIndoorData = _historicalIndoorData.last;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching historical data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOutdoorLatest() async {
    try {
      final url = Uri.parse(
        'https://api.thingspeak.com/channels/$_outdoorChannelId/feeds.json?api_key=$_outdoorReadKey&results=1',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return;
      final data = json.decode(response.body);
      final feeds = data['feeds'] as List?;
      if (feeds == null || feeds.isEmpty) return;
      final feed = feeds.first as Map<String, dynamic>;
      final temp =
          double.tryParse(feed['field1']?.toString() ?? '') ?? double.nan;
      final humidity =
          double.tryParse(feed['field2']?.toString() ?? '') ?? double.nan;
      final soilMoisture =
          double.tryParse(feed['field3']?.toString() ?? '') ?? double.nan;
      final createdAt = feed['created_at']?.toString();
      _outdoorTempTimestamp =
          createdAt != null ? DateTime.parse(createdAt).toLocal() : null;
      if (!temp.isNaN) _currentOutdoorTemp = temp;
      if (!humidity.isNaN) _currentOutdoorHumidity = humidity;
      if (!soilMoisture.isNaN) _currentOutdoorSoilMoisture = soilMoisture;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching outdoor temp: $e');
    }
  }

  Future<void> refresh() async {
    await fetchHistoricalData();
    await fetchOutdoorLatest();
    if (!_isMqttConnected) {
      _setupMqtt();
    }
  }

  SensorData _parseFeed(Map<String, dynamic> feed) {
    return SensorData(
      temperature: double.tryParse(feed['field1'] ?? '0') ?? 0.0,
      humidity: double.tryParse(feed['field2'] ?? '0') ?? 0.0,
      ammonia: double.tryParse(feed['field4'] ?? '0') ?? 0.0,
      co2: double.tryParse(feed['field3'] ?? '0') ?? 0.0,
      fireAlert: (double.tryParse(feed['field5'] ?? '0') ?? 0.0) > 0,
      rodentAlert: (double.tryParse(feed['field6'] ?? '0') ?? 0.0) > 0,
      timestamp: DateTime.parse(feed['created_at']).toLocal(),
    );
  }

  @override
  void dispose() {
    _outdoorTimer?.cancel();
    _client?.disconnect();
    super.dispose();
  }
}
