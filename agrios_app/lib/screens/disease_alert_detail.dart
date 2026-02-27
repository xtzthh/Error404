import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/disease_event.dart';
import '../theme/colors.dart';

class DiseaseAlertDetailScreen extends StatelessWidget {
  final DiseaseEvent event;

  const DiseaseAlertDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBg(isDark),
        elevation: 0,
        title: const Text('Disease Alert'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildImageCard(),
            const SizedBox(height: 20),
            _buildInfoCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    if (event.imageBase64.isEmpty) {
      return _buildPlaceholderCard('No image available');
    }

    try {
      final bytes = base64Decode(event.imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return _buildPlaceholderCard('Image failed to load');
    }
  }

  Widget _buildPlaceholderCard(String message) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cyberBlack.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cyberBlack : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.disease.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.neonGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Confidence: ${event.confidence.toStringAsFixed(1)}%',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            'Severity: ${event.severity}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'Diagnosis',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(event.description.isNotEmpty
              ? event.description
              : 'No description available.'),
          const SizedBox(height: 14),
          const Text(
            'Treatment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(event.treatment.isNotEmpty
              ? event.treatment
              : 'No treatment guidance available.'),
          const SizedBox(height: 14),
          Text(
            'Captured: ${event.timestamp.toLocal().toString().split('.').first}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
