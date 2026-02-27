import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';
import '../providers/theme_provider.dart';
import '../providers/storage_provider.dart';
import 'dart:async';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _showArrayView = false;
  final _cropNameController = TextEditingController();
  final _cropVarController = TextEditingController();
  final _qtyController = TextEditingController(text: '100');
  final _shelfController = TextEditingController(text: '6');
  String _selectedUnit = 'kg';

  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      children: [
        _buildHeader(isDark),
        if (storageProvider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.neonGreen)))
        else
          Expanded(
            child: _showArrayView ? _buildArrayView(storageProvider, isDark) : _buildEntryView(storageProvider, isDark),
          ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final storageProvider = Provider.of<StorageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STORAGE_UNITS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? AppColors.neonGreen : AppColors.lightText,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _showArrayView ? 'TACTICAL_ARRAY_MAP' : 'STOCK_MANIFEST_ENTRY',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.getMutedText(isDark),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.sync, color: isDark ? AppColors.neonGreen : AppColors.lightText, size: 20),
                      onPressed: () => storageProvider.fetchInventory(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => setState(() => _showArrayView = !_showArrayView),
                child: Text(
                  _showArrayView ? 'BACK_TO_FORM' : 'VIEW_BLOCKS',
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (storageProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                storageProvider.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryView(StorageProvider provider, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          CyberCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel('CROP_IDENTIFIER', isDark),
                _buildTextField(_cropNameController, 'e.g. RICE_INDICA', isDark),
                const SizedBox(height: 15),
                _buildInputLabel('VARIETY_SPEC', isDark),
                _buildTextField(_cropVarController, 'e.g. BASMATI_GRADE_A', isDark),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('QUANTITY', isDark),
                          _buildTextField(_qtyController, '100', isDark, isNumber: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('UNIT', isDark),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.grey[100],
                              border: Border.all(color: AppColors.getBorder(isDark)),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor: isDark ? AppColors.cyberBlack : Colors.white,
                              style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.lightText),
                              items: ['kg', 'quintal', 'tonne', 'bags'].map((u) {
                                return DropdownMenuItem(value: u, child: Text(u));
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInputLabel('STORAGE_SECTOR', isDark),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey[100],
                          border: Border.all(color: AppColors.getBorder(isDark)),
                        ),
                        child: Text(
                          provider.selectedBlock ?? 'SELECT_SECTOR...',
                          style: TextStyle(
                            color: provider.selectedBlock != null 
                              ? (isDark ? AppColors.neonGreen : AppColors.lightText) 
                              : AppColors.getMutedText(isDark),
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.neonGreen : AppColors.lightText,
                        foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () => setState(() => _showArrayView = true),
                      child: const Text('PICK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildInputLabel('SHELF_LIFE_MOS', isDark),
                _buildTextField(_shelfController, '6', isDark, isNumber: true),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.neonGreen : AppColors.lightText,
                      foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: () {
                      if (_cropNameController.text.isNotEmpty && provider.selectedBlock != null) {
                        provider.addItem(StorageItem(
                          id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                          name: _cropNameController.text.toUpperCase(),
                          variety: _cropVarController.text.toUpperCase(),
                          qty: double.tryParse(_qtyController.text) ?? 0,
                          unit: _selectedUnit,
                          location: provider.selectedBlock!,
                          storedAt: DateTime.now(),
                          shelfMonths: int.tryParse(_shelfController.text) ?? 6,
                        ));
                        _cropNameController.clear();
                        _cropVarController.clear();
                        _qtyController.text = '100';
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PROTOCOL: ASSET_COMMITTED_SUCCESSFULLY')),
                        );
                      }
                    },
                    child: const Text('COMMIT_TO_STORAGE', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildArrayView(StorageProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          CyberCard(
            height: 400,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final blockName = 'BLOCK_${(index + 1).toString().padLeft(2, '0')}';
                final isOccupied = provider.isBlockOccupied(blockName);
                final isSelected = provider.selectedBlock == blockName;
                final items = provider.getItemsInBlock(blockName);
                
                // Check if any item in this block is critical (< 10 days)
                bool hasCriticalItem = false;
                if (isOccupied) {
                  hasCriticalItem = items.any((item) => 
                    item.expiryDate.difference(DateTime.now()).inDays < 10);
                }

                return GestureDetector(
                  onTap: () {
                    provider.selectBlock(blockName);
                    if (!_showArrayView) setState(() => _showArrayView = false);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (isDark ? AppColors.neonGreen.withOpacity(0.2) : Colors.black12)
                        : (isOccupied 
                            ? (hasCriticalItem ? AppColors.errorRed.withOpacity(0.1) : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05)))
                            : Colors.transparent),
                      border: Border.all(
                        color: isSelected 
                          ? (isDark ? AppColors.neonGreen : AppColors.lightText) 
                          : (isOccupied 
                              ? (hasCriticalItem ? AppColors.errorRed : Colors.blue) 
                              : AppColors.getBorder(isDark)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (hasCriticalItem)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.warning, color: AppColors.errorRed, size: 10),
                          ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'B${(index + 1).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: hasCriticalItem ? AppColors.errorRed : AppColors.getMutedText(isDark),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOccupied ? items.first.name : 'VACANT',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isOccupied 
                                    ? (hasCriticalItem ? AppColors.errorRed : (isDark ? AppColors.neonGreen : AppColors.lightText)) 
                                    : AppColors.getMutedText(isDark).withOpacity(0.3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (provider.selectedBlock != null)
            CyberCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTOR_ANALYSIS: ${provider.selectedBlock}',
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.lightText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...provider.getItemsInBlock(provider.selectedBlock!).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.name} (${item.variety})', 
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                                Text(
                                  'QUANTITY: ${item.qty} ${item.unit}', 
                                  style: TextStyle(color: AppColors.getMutedText(isDark), fontSize: 9, fontFamily: 'monospace')
                                ),
                              ],
                            ),
                          ),
                          TacticalCountdown(expiryDate: item.expiryDate, isDark: isDark),
                        ],
                      ),
                    );
                  }).toList(),
                  if (provider.getItemsInBlock(provider.selectedBlock!).isEmpty)
                    Text('STATUS: READY_FOR_INJECTION', style: TextStyle(color: AppColors.getMutedText(isDark), fontSize: 11)),
                  const SizedBox(height: 15),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.psychology, color: AppColors.neonGreen, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'AI_QUALITY_ANALYSIS',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAiDetail('SURFACE_MOLD_PROB:', '0.02%', isDark),
                        _buildAiDetail('RODENT_ACTIVITY:', 'NONE_DETECTED', isDark),
                        _buildAiDetail('GRAIN_TEXTURE:', 'OPTIMAL_DRY', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiDetail(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.getMutedText(isDark), fontSize: 8, fontFamily: 'monospace')),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.getMutedText(isDark),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.lightText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.getMutedText(isDark).withOpacity(0.5), fontSize: 14),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey[100],
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.getBorder(isDark)),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

class TacticalCountdown extends StatefulWidget {
  final DateTime expiryDate;
  final bool isDark;

  const TacticalCountdown({super.key, required this.expiryDate, required this.isDark});

  @override
  State<TacticalCountdown> createState() => _TacticalCountdownState();
}

class _TacticalCountdownState extends State<TacticalCountdown> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeLeft;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.expiryDate.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.expiryDate.difference(DateTime.now());
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (_timeLeft.inDays < 10) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) {
      return Text(
        'STATUS: ASSET_EXPIRED',
        style: TextStyle(
          color: AppColors.errorRed,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    final String timeStr = '${days}D ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final bool isCritical = days < 10;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final color = isCritical 
          ? Color.lerp(AppColors.errorRed, AppColors.errorRed.withOpacity(0.3), _pulseController.value)!
          : (widget.isDark ? AppColors.neonGreen : AppColors.lightText);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isCritical ? 'CRITICAL_EXPIRY' : 'STABILITY_COUNTDOWN',
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }
}

