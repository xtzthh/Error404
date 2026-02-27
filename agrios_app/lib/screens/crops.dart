import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/cyber_card.dart';
import '../services/crop_ai_service.dart';
import 'settings_fields.dart';

class CropsHubScreen extends StatefulWidget {
  const CropsHubScreen({super.key});

  @override
  State<CropsHubScreen> createState() => _CropsHubScreenState();
}

class _CropsHubScreenState extends State<CropsHubScreen> {
  final PageController _pageController = PageController();
  int _selectedCrop = 0;

  final List<String> _cropTabs = ['Cotton', 'Ratoon Sugarcane', 'Wheat'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(),
      children: [
        _CropsHome(
          crops: _cropTabs,
          selectedIndex: _selectedCrop,
          onSelect: (index) => setState(() => _selectedCrop = index),
        ),
        const SettingsFieldsScreen(),
      ],
    );
  }
}

class _CropsHome extends StatefulWidget {
  final List<String> crops;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _CropsHome({
    required this.crops,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_CropsHome> createState() => _CropsHomeState();
}

class _CropsHomeState extends State<_CropsHome> {
  final CropAiService _aiService = CropAiService();
  bool _isAiLoading = false;

  late final List<_CropItem> _cropCards = [
    _CropItem(icon: Icons.grass, label: 'Sugarcane'),
    _CropItem(icon: Icons.local_florist, label: 'Cotton'),
    _CropItem(icon: Icons.eco, label: 'Ratoon\nSugarcane'),
    _CropItem(icon: Icons.agriculture, label: 'Wheat'),
  ];
  String _selectedCropLabel = 'Sugarcane';

  Future<void> _fetchAiCropData(String cropName) async {
    final normalized = _normalizeLabel(cropName);

    // Check if we already have it to avoid redundant AI calls
    if (_contentByCrop.containsKey(normalized) &&
        _contentByCrop[normalized]!.isAiGenerated) {
      setState(() => _selectedCropLabel = cropName);
      return;
    }

    setState(() {
      _isAiLoading = true;
      _selectedCropLabel = cropName;
    });

    final data = await _aiService.fetchCropData(normalized);
    if (data != null) {
      final List<_StageItem> stages = (data['stages'] as List).map((s) {
        return _StageItem(
          title: s['title'],
          date: s['date'],
          status: s['status'],
          highlight: s['highlight'] ?? false,
          icon: _getIconForStage(s['title']),
          accent: _getColorForStage(s['status']),
        );
      }).toList();

      final List<_PracticeItem> practices = (data['practices'] as List).map((
        p,
      ) {
        return _PracticeItem(
          label: p['label'],
          imageUrl: _getImageForPractice(p['label']),
        );
      }).toList();

      // Update practice details map
      final Map<String, List<String>> detailsMap = {};
      for (var p in data['practices']) {
        detailsMap[_normalizePracticeLabel(p['label'])] = List<String>.from(
          p['details'],
        );
      }

      setState(() {
        _contentByCrop[normalized] = _CropContent(
          stages: stages,
          practices: practices,
          isAiGenerated: true,
        );
        _practiceDetailsByCrop[normalized] = detailsMap;
        _isAiLoading = false;
      });
    } else {
      setState(() => _isAiLoading = false);
    }
  }

  IconData _getIconForStage(String title) {
    title = title.toLowerCase();
    if (title.contains('pre') || title.contains('prep'))
      return Icons.agriculture;
    if (title.contains('plant') || title.contains('sow')) return Icons.grass;
    return Icons.local_florist;
  }

  Color _getColorForStage(String status) {
    status = status.toLowerCase();
    if (status.contains('complete')) return const Color(0xFF8BC34A);
    if (status.contains('ongoing')) return const Color(0xFF4CAF50);
    return const Color(0xFF81C784);
  }

  String _getImageForPractice(String label) {
    label = label.toLowerCase();
    if (label.contains('climate'))
      return 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800';
    if (label.contains('soil'))
      return 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800';
    if (label.contains('land'))
      return 'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800';
    return 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800';
  }

  static String _normalizeLabel(String label) {
    return label.replaceAll('\n', ' ').trim();
  }

  Map<String, _CropContent> _contentByCrop = {
    'Sugarcane': _CropContent(
      stages: [
        _StageItem(
          title: 'Land Preparation',
          date: 'Late Nov - Early Dec',
          status: 'Completed',
          highlight: true,
          icon: Icons.agriculture,
          accent: Color(0xFF8BC34A),
        ),
        _StageItem(
          title: 'Planting',
          date: 'Dec - Jan',
          status: 'Ongoing',
          highlight: true,
          icon: Icons.grass,
          accent: Color(0xFF4CAF50),
        ),
        _StageItem(
          title: 'Germination',
          date: 'Jan - Feb',
          status: 'Upcoming',
          highlight: false,
          icon: Icons.local_florist,
          accent: Color(0xFF81C784),
        ),
      ],
      practices: [
        _PracticeItem(
          label: 'Climate\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
        ),
        _PracticeItem(
          label: 'Soil\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
        ),
        _PracticeItem(
          label: 'Land\npreparation.',
          imageUrl:
              'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800',
        ),
        _PracticeItem(
          label: 'Sett treatment\n& planting.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Weed\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Irrigation\nschedule.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
      ],
    ),
    'Cotton': _CropContent(
      stages: [
        _StageItem(
          title: 'Field Preparation',
          date: '28 Dec - 27 Jan',
          status: 'Completed',
          highlight: true,
          icon: Icons.agriculture,
          accent: Color(0xFF8BC34A),
        ),
        _StageItem(
          title: 'Sowing',
          date: '27 Jan - 28 Jan',
          status: 'Ongoing',
          highlight: true,
          icon: Icons.grass,
          accent: Color(0xFF4CAF50),
        ),
        _StageItem(
          title: 'Germination',
          date: '29 Jan - 06 Feb',
          status: 'Upcoming',
          highlight: false,
          icon: Icons.local_florist,
          accent: Color(0xFF81C784),
        ),
      ],
      practices: [
        _PracticeItem(
          label: 'Climate\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
        ),
        _PracticeItem(
          label: 'Soil\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
        ),
        _PracticeItem(
          label: 'Land\npreparation.',
          imageUrl:
              'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800',
        ),
        _PracticeItem(
          label: 'Season, Seed\nand sowing.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Variety\nrecommendation.',
          imageUrl:
              'https://images.unsplash.com/photo-1471193945509-9ad0617afabf?w=800',
        ),
        _PracticeItem(
          label: 'Seed selection\nand treatment.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
      ],
    ),
    'Wheat': _CropContent(
      stages: [
        _StageItem(
          title: 'Land Preparation',
          date: 'Nov - Dec',
          status: 'Completed',
          highlight: true,
          icon: Icons.agriculture,
          accent: Color(0xFF8BC34A),
        ),
        _StageItem(
          title: 'Sowing',
          date: 'Dec - Jan',
          status: 'Ongoing',
          highlight: true,
          icon: Icons.grass,
          accent: Color(0xFF4CAF50),
        ),
        _StageItem(
          title: 'Tillering',
          date: 'Jan - Feb',
          status: 'Upcoming',
          highlight: false,
          icon: Icons.local_florist,
          accent: Color(0xFF81C784),
        ),
      ],
      practices: [
        _PracticeItem(
          label: 'Climate\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
        ),
        _PracticeItem(
          label: 'Soil\nrequirement.',
          imageUrl:
              'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
        ),
        _PracticeItem(
          label: 'Seed rate\n& spacing.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Nutrient\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1459666644539-a9755287d6b0?w=800',
        ),
        _PracticeItem(
          label: 'Weed\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Irrigation\nschedule.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
      ],
    ),
    'Ratoon Sugarcane': _CropContent(
      stages: [
        _StageItem(
          title: 'Stubble Management',
          date: 'After harvest',
          status: 'Ongoing',
          highlight: true,
          icon: Icons.agriculture,
          accent: Color(0xFF8BC34A),
        ),
        _StageItem(
          title: 'Sprouting',
          date: '2-4 weeks',
          status: 'Upcoming',
          highlight: false,
          icon: Icons.grass,
          accent: Color(0xFF4CAF50),
        ),
        _StageItem(
          title: 'Tillering',
          date: '4-8 weeks',
          status: 'Upcoming',
          highlight: false,
          icon: Icons.local_florist,
          accent: Color(0xFF81C784),
        ),
      ],
      practices: [
        _PracticeItem(
          label: 'Trash\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800',
        ),
        _PracticeItem(
          label: 'Nutrient\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1459666644539-a9755287d6b0?w=800',
        ),
        _PracticeItem(
          label: 'Irrigation\nschedule.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Weed\nmanagement.',
          imageUrl:
              'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
        ),
        _PracticeItem(
          label: 'Pest\nmonitoring.',
          imageUrl:
              'https://images.unsplash.com/photo-1471193945509-9ad0617afabf?w=800',
        ),
        _PracticeItem(
          label: 'Stubble\ncare.',
          imageUrl:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
        ),
      ],
    ),
  };

  static String _normalizePracticeLabel(String label) {
    return label.replaceAll('\n', ' ').trim();
  }

  Map<String, Map<String, List<String>>> _practiceDetailsByCrop = {
    'Sugarcane': {
      'Climate requirement.': [
        'Needs warm, humid climate with bright sunshine for good tillering.',
        'Protect young crop from cold winds and frost during early growth.',
        'Ideal rainfall is ~1000-1500 mm annually with good distribution.',
      ],
      'Soil requirement.': [
        'Deep, well-drained loam or clay loam gives best root growth.',
        'Maintain pH around 6.5-7.5 for proper nutrient uptake.',
        'Avoid saline or waterlogged fields to prevent poor germination.',
      ],
      'Land preparation.': [
        'Deep ploughing followed by 2-3 harrowings to loosen soil.',
        'Form ridges and furrows for better drainage and rooting.',
        'Incorporate FYM/compost before planting for soil health.',
      ],
      'Sett treatment & planting.': [
        'Use healthy 2-3 bud setts from disease-free fields.',
        'Treat setts with recommended fungicide to prevent rot.',
        'Plant at proper spacing and depth for uniform stand.',
      ],
      'Weed management.': [
        'Apply pre-emergence herbicide within 3 days after planting.',
        'Inter-cultivation at 30-45 days to break crust and remove weeds.',
        'Keep field clean until canopy closes to avoid yield loss.',
      ],
      'Irrigation schedule.': [
        'Irrigate immediately after planting to ensure sprouting.',
        'Critical stages: tillering and grand growth need steady moisture.',
        'Use drip irrigation where possible to save water.',
      ],
    },
    'Cotton': {
      'Climate requirement.': [
        'Warm climate with long sunny days supports boll formation.',
        'Avoid heavy rains during flowering and boll opening.',
        'Sow only after soil temperature is warm enough.',
      ],
      'Soil requirement.': [
        'Well-drained black or loamy soils perform best.',
        'Maintain pH 6.0-7.5 for nutrient availability.',
        'Avoid waterlogging and salinity to prevent root damage.',
      ],
      'Land preparation.': [
        'Deep ploughing in summer helps control pests and weeds.',
        'Level the field for uniform irrigation and emergence.',
        'Add organic matter before sowing for better soil health.',
      ],
      'Season, Seed and sowing.': [
        'Use certified hybrid seeds with good germination.',
        'Sow at recommended spacing and depth for aeration.',
        'Treat seed before sowing to reduce seed-borne diseases.',
      ],
      'Variety recommendation.': [
        'Choose varieties recommended for your region and season.',
        'Select based on local pest and disease pressure.',
        'Prefer high-yielding, resistant types for stable output.',
      ],
      'Seed selection and treatment.': [
        'Use bold, uniform seeds for better emergence.',
        'Treat with fungicide/insecticide as recommended.',
        'Avoid damaged or shriveled seeds to reduce plant gaps.',
      ],
    },
    'Wheat': {
      'Climate requirement.': [
        'Cool, dry climate is ideal during vegetative growth.',
        'Avoid heat stress at grain filling for better yield.',
        'Sow in the optimum window for your region.',
      ],
      'Soil requirement.': [
        'Well-drained loamy soils support strong rooting.',
        'Maintain pH 6.5-7.5 for balanced nutrition.',
        'Avoid saline or alkaline soils for good germination.',
      ],
      'Seed rate & spacing.': [
        'Use recommended seed rate to avoid overcrowding.',
        'Maintain proper row spacing for sunlight and airflow.',
        'Ensure uniform sowing depth for even emergence.',
      ],
      'Nutrient management.': [
        'Apply basal NPK at sowing for early growth.',
        'Top dress nitrogen at tillering to boost tiller count.',
        'Correct micronutrient deficiencies based on soil test.',
      ],
      'Weed management.': [
        'Apply pre-emergence herbicide within 2-3 days of sowing.',
        'Weed at 25-30 days after sowing if needed.',
        'Keep field weed-free early to protect yield.',
      ],
      'Irrigation schedule.': [
        'Critical stages: CRI, tillering, heading, grain filling.',
        'Avoid water stress at flowering and grain filling.',
        'Use light, timely irrigations based on soil moisture.',
      ],
    },
    'Ratoon Sugarcane': {
      'Trash management.': [
        'Remove trash or use it as mulch to conserve moisture.',
        'Prevent pest harboring by managing residues properly.',
        'Maintain soil moisture to support early sprouting.',
      ],
      'Nutrient management.': [
        'Apply basal dose soon after harvest for quick recovery.',
        'Split nitrogen after sprouting for uniform growth.',
        'Add organic manure to improve soil structure.',
      ],
      'Irrigation schedule.': [
        'Irrigate immediately after harvest to activate buds.',
        'Maintain moisture during sprouting stage.',
        'Avoid waterlogging to prevent root rot.',
      ],
      'Weed management.': [
        'Early weed control is critical for ratoon success.',
        'Use inter-cultivation tools to reduce weed pressure.',
        'Mulching suppresses weeds and conserves moisture.',
      ],
      'Pest monitoring.': [
        'Scout for borers and termites every week.',
        'Use traps and safe sprays when threshold is reached.',
        'Remove infected stubbles to prevent spread.',
      ],
      'Stubble care.': [
        'Cut stubbles close to ground to encourage uniform sprouting.',
        'Apply recommended biofertilizer or decomposer.',
        'Maintain plant population after gap filling.',
      ],
    },
  };

  static const List<String> _defaultPracticeDetails = [
    'Follow region-specific advisory from local agri offices.',
    'Inspect soil moisture and crop condition at least twice a week.',
    'Adjust irrigation and nutrients based on the current growth stage.',
  ];

  List<String> _detailsForPractice(String cropName, _PracticeItem practice) {
    final cropKey = _normalizeLabel(cropName);
    final labelKey = _normalizePracticeLabel(practice.label);
    final cropMap = _practiceDetailsByCrop[cropKey];
    if (cropMap == null) return _defaultPracticeDetails;
    return cropMap[labelKey] ?? _defaultPracticeDetails;
  }

  _CropContent get _fallbackContent => const _CropContent(
    stages: [
      _StageItem(
        title: 'Preparation',
        date: 'Phase 1',
        status: 'Planned',
        highlight: false,
        icon: Icons.agriculture,
        accent: Color(0xFF8BC34A),
      ),
      _StageItem(
        title: 'Planting',
        date: 'Phase 2',
        status: 'Planned',
        highlight: false,
        icon: Icons.grass,
        accent: Color(0xFF4CAF50),
      ),
      _StageItem(
        title: 'Early Growth',
        date: 'Phase 3',
        status: 'Planned',
        highlight: false,
        icon: Icons.local_florist,
        accent: Color(0xFF81C784),
      ),
    ],
    practices: [
      _PracticeItem(
        label: 'Climate\nrequirement.',
        imageUrl:
            'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
      ),
      _PracticeItem(
        label: 'Soil\nrequirement.',
        imageUrl:
            'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
      ),
      _PracticeItem(
        label: 'Land\npreparation.',
        imageUrl:
            'https://images.unsplash.com/photo-1464226184884-fa280b87c399?w=800',
      ),
      _PracticeItem(
        label: 'Seed\nselection.',
        imageUrl:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
      ),
      _PracticeItem(
        label: 'Nutrient\nmanagement.',
        imageUrl:
            'https://images.unsplash.com/photo-1459666644539-a9755287d6b0?w=800',
      ),
      _PracticeItem(
        label: 'Water\nmanagement.',
        imageUrl:
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
      ),
    ],
  );

  void _confirmDelete(BuildContext context, _CropItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove crop?'),
        content: Text(
          'Delete "${item.label.replaceAll('\n', ' ')}" from My crops?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _cropCards.remove(item));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddCropDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add crop'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Crop name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              _cropCards.add(_CropItem(icon: Icons.eco, label: name));
              _fetchAiCropData(name);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final titleColor = isDark ? Colors.white : AppColors.lightText;
    final chipBorder = AppColors.getBorder(isDark);
    final selectedCrop = _normalizeLabel(_selectedCropLabel);
    final activeContent = _contentByCrop[selectedCrop] ?? _fallbackContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isAiLoading)
          const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
            minHeight: 2,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.crops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final isSelected =
                          widget.crops[index] == _selectedCropLabel;
                      return GestureDetector(
                        onTap: () {
                          widget.onSelect(index);
                          _fetchAiCropData(widget.crops[index]);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDEDDC)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: chipBorder),
                          ),
                          child: Center(
                            child: Text(
                              widget.crops[index],
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'My crops.',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 118,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._cropCards.map(
                        (item) => _cropIconCard(
                          item,
                          isSelected: item.label == _selectedCropLabel,
                          onTap: () {
                            _fetchAiCropData(item.label);
                          },
                          onDelete: () => _confirmDelete(context, item),
                        ),
                      ),
                      _addCropCard(
                        isDark,
                        onTap: () => _showAddCropDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Crop growth stages.',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 170,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: activeContent.stages
                        .map(
                          (stage) => _stageCard(
                            stage.title,
                            stage.date,
                            stage.status,
                            stage.highlight,
                            stage.icon,
                            stage.accent,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Best practices.',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.neonGreen
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: activeContent.practices
                      .map(
                        (practice) => _imageCard(
                          practice.label,
                          practice.imageUrl,
                          onTap: () => _openPracticeDetails(
                            context,
                            selectedCrop,
                            practice,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pests and diseases.',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.neonGreen
                            : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _pestCard('American\nBollworm'),
                      _pestCard('Aphid'),
                      _pestCard('Jassid'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cropIconCard(
    _CropItem item, {
    required VoidCallback onDelete,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFB7D9B9) : const Color(0xFFE6E6E6),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF2F2F2),
              radius: 24,
              child: Icon(item.icon, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addCropCard(bool isDark, {required VoidCallback onTap}) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF2E7D32),
              radius: 24,
              child: Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add/\nRemove',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCard(
    String label,
    String imageUrl, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFEFEFEF));
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.15),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageCard(
    String title,
    String date,
    String status,
    bool highlight,
    IconData stageIcon,
    Color accent,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withOpacity(0.55),
                        accent.withOpacity(0.15),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      stageIcon,
                      size: 44,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: highlight
                    ? const Color(0xFFDDEDDC)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageCardOld(
    String title,
    String date,
    String status,
    bool highlight,
    String imageUrl,
    Color accent,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: CyberCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.55),
                            accent.withOpacity(0.15),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: highlight
                    ? const Color(0xFFDDEDDC)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pestCard(String label) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1468794422460-113633d6c34e?w=800',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFEFEFEF));
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPracticeDetails(
    BuildContext context,
    String cropName,
    _PracticeItem practice,
  ) {
    final details = _detailsForPractice(cropName, practice);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PracticeDetailScreen(
          cropName: cropName,
          practice: practice,
          details: details,
        ),
      ),
    );
  }
}

class _CropItem {
  final IconData icon;
  final String label;

  _CropItem({required this.icon, required this.label});
}

class _CropContent {
  final List<_StageItem> stages;
  final List<_PracticeItem> practices;
  final bool isAiGenerated;

  const _CropContent({
    required this.stages,
    required this.practices,
    this.isAiGenerated = false,
  });
}

class _StageItem {
  final String title;
  final String date;
  final String status;
  final bool highlight;
  final IconData icon;
  final Color accent;

  const _StageItem({
    required this.title,
    required this.date,
    required this.status,
    required this.highlight,
    required this.icon,
    required this.accent,
  });
}

class _PracticeItem {
  final String label;
  final String imageUrl;

  const _PracticeItem({required this.label, required this.imageUrl});
}

class _PracticeDetailScreen extends StatelessWidget {
  final String cropName;
  final _PracticeItem practice;
  final List<String> details;

  const _PracticeDetailScreen({
    required this.cropName,
    required this.practice,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final label = practice.label.replaceAll('\n', ' ');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$cropName • $label',
          style: const TextStyle(color: Color(0xFF1F2D1F)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2D1F),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              practice.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(height: 120, color: const Color(0xFFEFEFEF));
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          ...details.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '• $item',
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Color(0xFF2D3436),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
