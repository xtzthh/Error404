import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/disease_event.dart';
import '../services/disease_api_config.dart';
import '../services/notification_service.dart';

class DiseaseAlertProvider with ChangeNotifier {
  final String baseUrl;
  DiseaseEvent? _latestEvent;
  Timer? _pollTimer;
  bool _isPolling = false;
  String? _lastEventId;

  DiseaseAlertProvider({String? baseUrlOverride})
      : baseUrl = baseUrlOverride ?? DiseaseApiConfig.baseUrl {
    _startPolling();
  }

  DiseaseEvent? get latestEvent => _latestEvent;
  bool get isPolling => _isPolling;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => fetchLatestEvent(),
    );
    fetchLatestEvent();
  }

  Future<void> fetchLatestEvent() async {
    _isPolling = true;
    try {
      final url = Uri.parse('$baseUrl/disease-events/latest');
      final response = await http.get(url).timeout(
        const Duration(seconds: 4),
      );
      if (response.statusCode != 200) {
        _isPolling = false;
        notifyListeners();
        return;
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final event = DiseaseEvent.fromJson(data);
      if (_lastEventId != event.id) {
        _lastEventId = event.id;
        _latestEvent = event;
        await NotificationService.showDiseaseAlert(event);
        notifyListeners();
      }
    } catch (_) {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
