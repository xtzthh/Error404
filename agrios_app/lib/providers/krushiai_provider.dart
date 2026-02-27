import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/disease_api_config.dart';

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
}

class KrushiAIProvider with ChangeNotifier {
  List<Message> _chatMessages = [];
  bool _isTyping = false;

  // New Telemetry Fields
  String? lastDisease;
  String? lastSeverity;
  double lastConfidence = 0.0;
  String? lastDetails;
  String? lastRemedy;

  bool _isScanning = false;
  String? _workingBaseUrl;

  List<Message> get chatMessages => _chatMessages;
  bool get isTyping => _isTyping;
  bool get isScanning => _isScanning;
  String get _baseUrl => _workingBaseUrl ?? DiseaseApiConfig.baseUrl;
  Uri get _chatUri => Uri.parse('$_baseUrl/chat');
  Uri get _detectUri => Uri.parse('$_baseUrl/detect');
  String get currentBaseUrl => _baseUrl;

  Future<bool> _ensureReachableBaseUrl() async {
    if (_workingBaseUrl != null) return true;
    for (final base in DiseaseApiConfig.candidateBaseUrls) {
      final healthUri = Uri.parse('$base/health');
      try {
        debugPrint('[KrushiAI] probing -> $healthUri');
        final resp = await http
            .get(healthUri)
            .timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          _workingBaseUrl = base;
          debugPrint('[KrushiAI] connected -> $base');
          return true;
        }
      } catch (_) {
        // Try next candidate.
      }
    }
    return false;
  }

  Future<bool> ensureBackendConnected() => _ensureReachableBaseUrl();

  Future<void> sendMessage({
    required String text,
    required String language,
    double? soil,
    double? temp,
    String? farmSize,
    String? cropType,
  }) async {
    _lastLanguageUsed = language;
    _chatMessages.add(Message(text, true));
    _isTyping = true;
    notifyListeners();

    try {
      final ok = await _ensureReachableBaseUrl();
      if (!ok) {
        _chatMessages.add(Message("Error: backend not reachable.", false));
        _isTyping = false;
        notifyListeners();
        return;
      }
      debugPrint('[KrushiAI] chat -> $_chatUri');
      var request = http.MultipartRequest('POST', _chatUri);
      request.fields['message'] = text;
      if (soil != null) request.fields['soil'] = soil.toString();
      if (temp != null) request.fields['temp'] = temp.toString();
      if (farmSize != null) request.fields['size'] = farmSize;
      if (cropType != null) request.fields['crop'] = cropType;
      request.fields['language'] = language;

      var response = await request.send().timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        _chatMessages.add(
          Message("Error: backend returned ${response.statusCode}.", false),
        );
        _isTyping = false;
        notifyListeners();
        return;
      }
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);
      _chatMessages.add(
        Message(data['response'] ?? "I'm having trouble connecting.", false),
      );
    } catch (e) {
      debugPrint('[KrushiAI] chat error: $e');
      _chatMessages.add(Message("Error: AI core offline.", false));
    }
    _isTyping = false;
    notifyListeners();
  }

  Future<void> scanImage(File image) async {
    _isScanning = true;
    lastDisease = null;
    notifyListeners();

    try {
      final ok = await _ensureReachableBaseUrl();
      if (!ok) {
        lastDisease = "CORE_SYNC_FAILED";
        lastDetails = "Backend not reachable from this device.";
        _isScanning = false;
        notifyListeners();
        return;
      }
      debugPrint('[KrushiAI] detect -> $_detectUri');
      var request = http.MultipartRequest('POST', _detectUri);
      request.fields['language'] = _lastLanguageUsed ?? 'English';
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send().timeout(const Duration(seconds: 40));
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (data['error'] != null) {
        lastDisease = "API_ERROR";
        lastDetails = data['error'];
      } else {
        lastDisease = data['disease'];
        lastSeverity =
            data['severity'] ?? _severityFromConfidence(data['confidence']);
        lastConfidence = (data['confidence'] ?? 0.0).toDouble();
        lastDetails =
            data['details'] ??
            'Model provider: ${data['provider'] ?? 'unknown'}';
        lastRemedy = data['recommendation'];
      }
    } catch (e) {
      debugPrint('[KrushiAI] detect error: $e');
      lastDisease = "CORE_SYNC_FAILED";
    }

    _isScanning = false;
    notifyListeners();
  }

  String _severityFromConfidence(dynamic confidenceRaw) {
    final confidence = double.tryParse('${confidenceRaw ?? 0}') ?? 0;
    if (confidence >= 0.85) return 'High';
    if (confidence >= 0.60) return 'Medium';
    return 'Low';
  }

  String? _lastLanguageUsed;
  void setLanguage(String language) {
    _lastLanguageUsed = language;
  }
}
