class DiseaseEvent {
  final String id;
  final DateTime timestamp;
  final String source;
  final String disease;
  final double confidence;
  final String severity;
  final String category;
  final String description;
  final String treatment;
  final String imageName;
  final String imageBase64;
  final String language;

  DiseaseEvent({
    required this.id,
    required this.timestamp,
    required this.source,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.category,
    required this.description,
    required this.treatment,
    required this.imageName,
    required this.imageBase64,
    required this.language,
  });

  factory DiseaseEvent.fromJson(Map<String, dynamic> json) {
    return DiseaseEvent(
      id: json['id']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      source: json['source']?.toString() ?? 'unknown',
      disease: json['disease']?.toString() ?? 'UNKNOWN',
      confidence: _parseDouble(json['confidence']),
      severity: json['severity']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'AI_DIAGNOSIS',
      description: json['description']?.toString() ?? '',
      treatment: json['treatment']?.toString() ?? '',
      imageName: json['image_name']?.toString() ?? 'capture.jpg',
      imageBase64: json['image_base64']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'category': category,
      'description': description,
      'treatment': treatment,
      'image_name': imageName,
      'image_base64': imageBase64,
      'language': language,
    };
  }
}
