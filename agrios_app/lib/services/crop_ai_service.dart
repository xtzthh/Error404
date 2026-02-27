import 'dart:convert';
import 'package:http/http.dart' as http;

class CropAiService {
  static const String _apiKey =
      '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';
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  Future<Map<String, dynamic>?> fetchCropData(String cropName) async {
    final prompt =
        '''
    Act as a senior agricultural expert. Provide HIGHLY DETAILED, farmer-friendly, and actionable agricultural data for the crop "$cropName".
    Farmers need specific, practical, and highly detailed advice they can follow in the field. 
    Explain concepts clearly. Don't just list facts; give instructions.
    
    The response must strictly follow this structural JSON format:
    {
      "stages": [
        {
          "title": "Stage Name", 
          "date": "Specific month range", 
          "status": "Ongoing/Upcoming/Completed", 
          "highlight": true/false
        },
        ... (provide exactly 3 current/relevant stages)
      ],
      "practices": [
        {
          "label": "Practice Category (e.g. Climate requirement.)",
          "details": [
            "Detailed instruction 1 (long, descriptive, actionable)",
            "Detailed instruction 2 (long, descriptive, actionable)",
            "Detailed instruction 3 (long, descriptive, actionable)",
            "Detailed instruction 4 (long, descriptive, actionable)",
            "Detailed instruction 5 (long, descriptive, actionable)"
          ]
        },
        ... (provide exactly 6 standard agricultural practices: Climate, Soil, Preparation, Sowing/Planting, Nutrients, Irrigation)
      ]
    }
    Make each detail point long enough to explain the 'how' and 'why'. Mention specific temperatures (Celsius), pH levels, fertilizer quantities, or spacing (cm/inches) if applicable.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://agrios.app', // Required by OpenRouter
          'X-Title': 'AgriOS App',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-exp:free',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        print(
          'Error fetching crop data: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Exception in CropAiService: $e');
      return null;
    }
  }
}
