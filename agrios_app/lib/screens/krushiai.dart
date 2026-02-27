import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';
import '../providers/krushiai_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/field_provider.dart';
import '../widgets/infinity_loader.dart';

class KrushiAIScreen extends StatefulWidget {
  const KrushiAIScreen({super.key});

  @override
  State<KrushiAIScreen> createState() => _KrushiAIScreenState();
}

class _KrushiAIScreenState extends State<KrushiAIScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedLanguage;
  bool _isListening = false;
  static const List<String> _quickPrompts = [
    "My tomato leaves are turning yellow. What should I do?",
    "Give me an irrigation plan for the next 7 days.",
    "How can I prevent fungal disease this week?",
    "Best organic treatment for pest attack?",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedLanguage = "English";
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    try {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
        IosTextToSpeechAudioMode.defaultMode,
      );
    } catch (_) {
      // Non-iOS platforms can safely ignore this configuration.
    }
  }

  Future<void> _setVoiceForLanguage(String lang) async {
    if (lang == "Marathi") {
      try {
        final voices = await _flutterTts.getVoices;
        if (voices is List) {
          for (final v in voices) {
            if (v is Map &&
                (v["locale"]?.toString().toLowerCase().contains("mr-in") ??
                    false)) {
              await _flutterTts.setVoice({
                "name": v["name"],
                "locale": v["locale"],
              });
              await _flutterTts.setLanguage("mr-IN");
              return;
            }
          }
        }
      } catch (_) {
        // Fallback to setLanguage below.
      }
      await _flutterTts.setLanguage("mr-IN");
      return;
    }
    if (lang == "Hindi") {
      await _flutterTts.setLanguage("hi-IN");
      return;
    }
    await _flutterTts.setLanguage("en-US");
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final lang = _selectedLanguage ?? "English";
      final playedFromCloud = await _speakViaGoogleCloud(text, lang);
      if (!playedFromCloud) {
        await _setVoiceForLanguage(lang);
        await _audioPlayer.stop();
        await _flutterTts.stop();
        await _flutterTts.speak(text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Voice playback failed: $e")));
    }
  }

  Future<bool> _speakViaGoogleCloud(String text, String language) async {
    try {
      final provider = context.read<KrushiAIProvider>();
      final ok = await provider.ensureBackendConnected();
      if (!ok) return false;
      final ttsUri = Uri.parse('${provider.currentBaseUrl}/tts');
      final resp = await http.post(
        ttsUri,
        body: {'text': text, 'language': language},
      ).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) return false;
      final audioBase64 = data['audio_base64'];
      if (audioBase64 is! String || audioBase64.isEmpty) return false;
      final bytes = base64Decode(audioBase64);
      await _flutterTts.stop();
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes), volume: 1.0);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _sttLocaleForLanguage(String? lang) {
    switch (lang) {
      case "Hindi":
        return "hi_IN";
      case "Marathi":
        return "mr_IN";
      default:
        return "en_IN";
    }
  }

  Future<void> _toggleSpeechToText() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Hindi, English, or Marathi first."),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    final available = await _speechToText.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == "done" || status == "notListening") {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Speech error: ${error.errorMsg}")),
        );
      },
    );

    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speech recognition is not available on this device."),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isListening = true);
    await _speechToText.listen(
      localeId: _sttLocaleForLanguage(_selectedLanguage),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _chatController.text = result.recognizedWords;
          _chatController.selection = TextSelection.fromPosition(
            TextPosition(offset: _chatController.text.length),
          );
          if (result.finalResult) {
            _isListening = false;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const isDark = false;
    const accent = Color(0xFF1F8F55);
    const textColor = Color(0xFF111827);
    const mutedText = Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF4F7FA), Color(0xFFF7F9FC)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFD8DEE6)),
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu_rounded),
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFD8DEE6)),
                    ),
                    child: const Text(
                      'Krushi Copilot',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const SizedBox(width: 56, height: 56),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8DEE6)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                indicatorPadding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: textColor,
                unselectedLabelColor: mutedText,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Neural Advisor'),
                  Tab(text: 'Scan Engine'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(isDark, accent),
                _buildScanTab(isDark, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(bool isDark, Color color) {
    final provider = context.watch<KrushiAIProvider>();
    final sensorProvider = context.watch<SensorProvider>();
    final fieldProvider = context.watch<FieldProvider>();
    final media = MediaQuery.of(context);
    final bottomClearance = media.padding.bottom + 72;
    const surface = Colors.white;
    const softSurface = Color(0xFFF6F9FC);
    const bodyText = Color(0xFF0F172A);
    const subtleText = Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomClearance),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: softSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8DEE6)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: "Language",
                labelStyle: TextStyle(
                  color: subtleText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              dropdownColor: surface,
              style: TextStyle(
                color: bodyText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                DropdownMenuItem(value: "Marathi", child: Text("Marathi")),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedLanguage = value);
                context.read<KrushiAIProvider>().setLanguage(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFEFE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD8DEE6)),
              ),
              child: provider.chatMessages.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 1,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                14,
                                10,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4ED),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFB6DCC4),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.eco_rounded,
                                      color: color,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Krushi Copilot",
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Get actionable advice for crop health, irrigation,\npest control, and yield planning.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: subtleText,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _quickPrompts
                                        .map(
                                          (prompt) => _promptChip(
                                            title: prompt,
                                            onTap: () {
                                              _chatController.text = prompt;
                                              _chatController.selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: _chatController
                                                          .text
                                                          .length,
                                                    ),
                                                  );
                                              setState(() {});
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: provider.chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.chatMessages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: msg.isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!msg.isUser) ...[
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F4ED),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.72,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: msg.isUser
                                        ? const Color(0xFFE8F4ED)
                                        : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        msg.isUser ? 16 : 6,
                                      ),
                                      bottomRight: Radius.circular(
                                        msg.isUser ? 6 : 16,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFD8DEE6),
                                    ),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: bodyText,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                              if (!msg.isUser) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    size: 18,
                                    color: color,
                                  ),
                                  onPressed: () => _speak(msg.text),
                                  splashRadius: 18,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (provider.isTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB6DCC4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InfinityLoader(size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Analyzing farm context...',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD8DEE6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    onSubmitted: (_) => _sendCurrentMessage(
                      provider,
                      sensorProvider,
                      fieldProvider,
                    ),
                    style: TextStyle(color: bodyText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type your farming question',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _toggleSpeechToText,
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? Colors.red.withValues(alpha: 0.14)
                        : const Color(0xFFE8F4ED),
                    foregroundColor: _isListening ? Colors.redAccent : color,
                  ),
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none_rounded),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: () => _sendCurrentMessage(
                    provider,
                    sensorProvider,
                    fieldProvider,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendCurrentMessage(
    KrushiAIProvider provider,
    SensorProvider sensorProvider,
    FieldProvider fieldProvider,
  ) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final language = _selectedLanguage ?? "English";
    provider.setLanguage(language);

    provider.sendMessage(
      text: text,
      language: language,
      soil: sensorProvider.currentOutdoorSoilMoisture,
      temp: sensorProvider.currentOutdoorTemp,
      farmSize: fieldProvider.fields.isNotEmpty
          ? fieldProvider.fields.first.area
          : "1 acre",
      cropType: fieldProvider.fields.isNotEmpty
          ? fieldProvider.fields.first.crop
          : "Tomato",
    );
    _chatController.clear();
  }

  Widget _promptChip({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8DEE6)),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildScanTab(bool isDark, Color color) {
    final provider = context.watch<KrushiAIProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DIAGNOSTIC_TELEMETRY',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              if (provider.lastRemedy != null)
                IconButton(
                  icon: Icon(Icons.volume_up, size: 18, color: color),
                  onPressed: () => _speak(provider.lastRemedy!),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time pathological assessment and treatment vectors.',
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),

          if (provider.isScanning)
            const CyberCard(
              height: 200,
              child: Center(child: InfinityLoader(size: 40)),
            )
          else if (provider.lastDisease == null)
            CyberCard(
              height: 250,
              child: InkWell(
                onTap: () => _pickAndScan(ImageSource.camera),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 50,
                        color: color.withOpacity(0.2),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'UPLOAD_TISSUE_SAMPLE',
                        style: TextStyle(
                          color: color.withOpacity(0.4),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _buildTelemetryResults(isDark, color, provider),

          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  Icons.camera_alt,
                  'CAMERA',
                  () => _pickAndScan(ImageSource.camera),
                  color,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionButton(
                  Icons.photo_library,
                  'GALLERY',
                  () => _pickAndScan(ImageSource.gallery),
                  color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryResults(
    bool isDark,
    Color color,
    KrushiAIProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATHOGEN_ID:',
                style: TextStyle(
                  color: AppColors.getMutedText(isDark),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                provider.lastDisease!.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SEVERITY: ${provider.lastSeverity?.toUpperCase() ?? "UNKNOWN"}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CONFIDENCE_SCORE:',
          style: TextStyle(
            color: AppColors.getMutedText(isDark),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: provider.lastConfidence,
          color: color,
          backgroundColor: color.withOpacity(0.1),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(provider.lastConfidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'PATHOLOGICAL_DETAILS:',
          style: TextStyle(
            color: AppColors.getMutedText(isDark),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          provider.lastDetails ?? '',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 12,
            height: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 25),
        CyberCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TREATMENT_REQUISITION:',
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider.lastRemedy ?? '',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (!mounted) return;
    if (pickedFile != null) {
      final provider = context.read<KrushiAIProvider>();
      provider.setLanguage(_selectedLanguage ?? "English");
      provider.scanImage(File(pickedFile.path));
    }
  }
}
