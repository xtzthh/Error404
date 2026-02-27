import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/storage_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_intelligence_service.dart';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _showArrayView = true;
  final _cropNameController = TextEditingController();
  final _cropVarController = TextEditingController();
  final _qtyController = TextEditingController(text: '100');
  final _shelfController = TextEditingController(text: '6');
  String _selectedUnit = 'kg';

  @override
  void dispose() {
    _cropNameController.dispose();
    _cropVarController.dispose();
    _qtyController.dispose();
    _shelfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storageProvider = Provider.of<StorageProvider>(context);
    final sensorProvider = Provider.of<SensorProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final riskMap = StorageIntelligenceService.buildBlockRiskMap(
      storageProvider.inventory,
      liveTemperatureC: sensorProvider.currentIndoorData?.temperature,
      liveHumidityPct: sensorProvider.currentIndoorData?.humidity,
      liveCo2Ppm: sensorProvider.currentIndoorData?.co2,
    );
    final kpi = StorageIntelligenceService.buildWarehouseKpi(
      storageProvider.inventory,
      riskMap,
    );

    return Column(
      children: [
        _buildHeader(storageProvider, isDark),
        if (storageProvider.isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.neonGreen),
            ),
          )
        else
          Expanded(
            child: _showArrayView
                ? _buildArrayView(storageProvider, sensorProvider, riskMap, kpi, isDark)
                : _buildEntryView(storageProvider, isDark),
          ),
      ],
    );
  }

  Widget _buildHeader(StorageProvider storageProvider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WAREHOUSE_COMMAND',
                      style: TextStyle(
                        color: isDark ? AppColors.neonGreen : AppColors.lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      _showArrayView ? 'TACTICAL_MAP + DISPATCH' : 'LOT_ENTRY_PROTOCOL',
                      style: TextStyle(
                        color: AppColors.getMutedText(isDark),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.sync,
                  color: isDark ? AppColors.neonGreen : AppColors.lightText,
                ),
                onPressed: () => storageProvider.fetchInventory(),
              ),
              TextButton(
                onPressed: () => setState(() => _showArrayView = !_showArrayView),
                child: Text(
                  _showArrayView ? 'ADD_LOT' : 'VIEW_HUD',
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          if (storageProvider.errorMessage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  storageProvider.errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                _buildTextField(_cropNameController, 'RICE_INDICA', isDark),
                const SizedBox(height: 14),
                _buildInputLabel('VARIETY', isDark),
                _buildTextField(_cropVarController, 'GRADE_A', isDark),
                const SizedBox(height: 14),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel('UNIT', isDark),
                          _buildUnitDropdown(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                          provider.selectedBlock ?? 'SELECT BLOCK FROM HUD...',
                          style: TextStyle(
                            color: provider.selectedBlock != null
                                ? (isDark ? AppColors.neonGreen : AppColors.lightText)
                                : AppColors.getMutedText(isDark),
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _showArrayView = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.neonGreen : AppColors.lightText,
                        foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('PICK'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInputLabel('SHELF_LIFE_MOS', isDark),
                _buildTextField(_shelfController, '6', isDark, isNumber: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_cropNameController.text.trim().isEmpty || provider.selectedBlock == null) {
                        return;
                      }
                      await provider.addItem(
                        StorageItem(
                          id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                          name: _cropNameController.text.trim().toUpperCase(),
                          variety: _cropVarController.text.trim().toUpperCase(),
                          qty: double.tryParse(_qtyController.text) ?? 0,
                          unit: _selectedUnit,
                          location: provider.selectedBlock!,
                          storedAt: DateTime.now(),
                          shelfMonths: int.tryParse(_shelfController.text) ?? 6,
                        ),
                      );

                      _cropNameController.clear();
                      _cropVarController.clear();
                      _qtyController.text = '100';
                      _shelfController.text = '6';
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('LOT_COMMITTED_TO_STORAGE')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.neonGreen : AppColors.lightText,
                      foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'COMMIT_TO_STORAGE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
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

  Widget _buildArrayView(
    StorageProvider provider,
    SensorProvider sensorProvider,
    Map<String, BlockRiskResult> riskMap,
    WarehouseKpi kpi,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildKpiStrip(kpi, isDark),
          const SizedBox(height: 14),
          CyberCard(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final blockName = 'BLOCK_${(index + 1).toString().padLeft(2, '0')}';
                final selected = provider.selectedBlock == blockName;
                final lots = provider.getItemsInBlock(blockName);
                final blockRisk = riskMap[blockName] ??
                    const BlockRiskResult(level: StorageRiskLevel.safe, reasons: ['No risk']);
                return GestureDetector(
                  onTap: () {
                    provider.selectBlock(blockName);
                    setState(() => _showArrayView = true);
                  },
                  child: _buildBlockTile(
                    blockNo: index + 1,
                    lots: lots,
                    risk: blockRisk.level,
                    selected: selected,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildSelectedBlockPanel(provider, sensorProvider, riskMap, isDark),
          const SizedBox(height: 110),
        ],
      ),
    );
  }

  Widget _buildKpiStrip(WarehouseKpi kpi, bool isDark) {
    return Row(
      children: [
        Expanded(child: _kpiCard('OCCUPIED', '${kpi.occupied}/9', isDark, AppColors.neonGreen)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard('WARNING', '${kpi.warning}', isDark, AppColors.warningOrange)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard('RISK', '${kpi.risk}', isDark, AppColors.errorRed)),
        const SizedBox(width: 8),
        Expanded(child: _kpiCard('RESCUED', '${kpi.rescued}', isDark, Colors.lightGreen)),
      ],
    );
  }

  Widget _kpiCard(String label, String value, bool isDark, Color color) {
    return CyberCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 8,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockTile({
    required int blockNo,
    required List<StorageItem> lots,
    required StorageRiskLevel risk,
    required bool selected,
    required bool isDark,
  }) {
    final occupied = lots.isNotEmpty;
    final border = _riskColor(risk);
    final fill = selected
        ? border.withOpacity(0.2)
        : occupied
            ? border.withOpacity(0.1)
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: selected ? border : border.withOpacity(0.8),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'B${blockNo.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            occupied ? lots.first.name : 'VACANT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: occupied ? border : AppColors.getMutedText(isDark).withOpacity(0.45),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            StorageIntelligenceService.riskLabel(risk),
            style: TextStyle(
              color: border,
              fontSize: 8,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBlockPanel(
    StorageProvider provider,
    SensorProvider sensorProvider,
    Map<String, BlockRiskResult> riskMap,
    bool isDark,
  ) {
    final block = provider.selectedBlock ?? 'BLOCK_01';
    final lots = provider.getItemsInBlock(block);
    final blockRisk = riskMap[block] ??
        const BlockRiskResult(level: StorageRiskLevel.safe, reasons: ['No risk']);
    final isLiveBlock = block == 'BLOCK_05';
    final live = sensorProvider.currentIndoorData;

    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECTOR_ANALYSIS: $block',
                style: TextStyle(
                  color: isDark ? AppColors.neonGreen : AppColors.lightText,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _riskColor(blockRisk.level).withOpacity(0.15),
                  border: Border.all(color: _riskColor(blockRisk.level).withOpacity(0.7)),
                ),
                child: Text(
                  StorageIntelligenceService.riskLabel(blockRisk.level),
                  style: TextStyle(
                    color: _riskColor(blockRisk.level),
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLiveBlock)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  _telemetryChip('TEMP', _fmtLive(live?.temperature, 'C'), isDark),
                  _telemetryChip('HUM', _fmtLive(live?.humidity, '%'), isDark),
                  _telemetryChip('NH3', _fmtLive(live?.ammonia, ' ppm'), isDark),
                  _telemetryChip('CO2', _fmtLive(live?.co2, ' ppm'), isDark),
                ],
              ),
            ),
          if (lots.isEmpty)
            Text(
              'BLOCK_VACANT — READY_FOR_INJECTION',
              style: TextStyle(
                color: AppColors.getMutedText(isDark),
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            )
          else
            ...lots.map((item) => _lotRow(item, isDark)),
          const SizedBox(height: 10),
          Text(
            'RISK_REASONING',
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...blockRisk.reasons.take(3).map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 5, right: 7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _riskColor(blockRisk.level),
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
  }

  Widget _lotRow(StorageItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.getBorder(isDark).withOpacity(0.5)),
        color: Colors.black12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} (${item.variety.isEmpty ? 'N/A' : item.variety})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'QTY ${item.qty} ${item.unit} • EXP ${_date(item.expiryDate)}',
                      style: TextStyle(
                        color: AppColors.getMutedText(isDark),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              TacticalCountdown(expiryDate: item.expiryDate, isDark: isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openDispatchAdvisor(item, isDark),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.neonGreen.withOpacity(0.7)),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'DISPATCH_ADVISOR',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await Provider.of<StorageProvider>(context, listen: false).markAsSold(item.id);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orangeAccent),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'MARK_SOLD',
                    style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openDispatchAdvisor(StorageItem item, bool isDark) async {
    final locations = const [
      'VADODARA',
      'AHMEDABAD',
      'SURAT',
      'PUNE',
      'MUMBAI',
      'NASHIK',
      'DELHI',
      'BENGALURU',
      'HYDERABAD',
    ];
    final transports = const ['MINI_TRUCK', 'TRUCK_10T', 'REEFER'];

    var farmer = locations.first;
    var transport = transports.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final rec = StorageIntelligenceService.getDispatchRecommendation(item, farmer, transport);
            final econ = StorageIntelligenceService.getBestProfitableMarket(item, farmer, transport);
            final priorityColor = rec.priority == 'DISPATCH_NOW'
                ? AppColors.errorRed
                : rec.priority == 'DISPATCH_TODAY'
                    ? AppColors.warningOrange
                    : AppColors.neonGreen;

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cyberBlack : Colors.white,
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.8)),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'DISPATCH_COMMAND :: ${item.name}',
                              style: const TextStyle(
                                color: AppColors.neonGreen,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close, color: AppColors.neonGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _dispatchPicker(
                        label: 'FARMER_LOCATION',
                        value: farmer,
                        options: locations,
                        onChanged: (v) => setModal(() => farmer = v!),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _dispatchPicker(
                        label: 'TRANSPORT_MODE',
                        value: transport,
                        options: transports,
                        onChanged: (v) => setModal(() => transport = v!),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          border: Border.all(color: priorityColor.withOpacity(0.7)),
                        ),
                        child: Text(
                          'PRIORITY: ${rec.priority}  •  ${rec.windowText}',
                          style: TextStyle(
                            color: priorityColor,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _dispatchLine('DEST_FARMER', rec.farmerLabel, isDark),
                      _dispatchLine('NEAREST_MARKET', rec.nearestMarket, isDark),
                      _dispatchLine('TRAVEL_DISTANCE', '${rec.distanceKm} KM', isDark),
                      _dispatchLine('EST_TRAVEL_TIME', rec.etaLabel, isDark),
                      _dispatchLine('SHELF_LIFE_LEFT', '${rec.daysLeft} DAY(S)', isDark),
                      _dispatchLine('BEST_PROFIT_MARKET', econ.bestMarket, isDark),
                      _dispatchLine('EST_NET_PAYOUT', '₹${_fmtInt(econ.bestNetPayout)}', isDark),
                      _dispatchLine('LOGISTICS_COST', '₹${_fmtInt(econ.bestLogisticsCost)}', isDark),
                      _dispatchLine(
                        'GAIN_VS_NEAREST',
                        '₹${_fmtInt(econ.gainVsNearest)}',
                        isDark,
                        valueColor: econ.gainVsNearest >= 0 ? Colors.lightGreenAccent : Colors.redAccent,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final storageProvider = Provider.of<StorageProvider>(
                              this.context,
                              listen: false,
                            );
                            await storageProvider.markAsSold(item.id);
                            if (!mounted) return;
                            Navigator.of(this.context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('DISPATCH_CONFIRMED_AND_MARKED_SOLD'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.neonGreen,
                            foregroundColor: AppColors.cyberBlack,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Text(
                            'CONFIRM_DISPATCH',
                            style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dispatchPicker({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.getMutedText(isDark),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.getBorder(isDark)),
            color: isDark ? Colors.black26 : Colors.grey.shade100,
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.cyberBlack : Colors.white,
            style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.lightText),
            items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _dispatchLine(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.getMutedText(isDark),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? (isDark ? AppColors.neonGreen : AppColors.lightText),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: AppColors.getBorder(isDark).withOpacity(0.4)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: isDark ? AppColors.neonGreen : AppColors.lightText,
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.getMutedText(isDark),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.lightText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.getMutedText(isDark).withOpacity(0.5)),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.getBorder(isDark)),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(bool isDark) {
    return Container(
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
        items: ['kg', 'quintal', 'tonne', 'bags']
            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
            .toList(),
        onChanged: (v) => setState(() => _selectedUnit = v ?? 'kg'),
      ),
    );
  }

  Color _riskColor(StorageRiskLevel level) {
    switch (level) {
      case StorageRiskLevel.risk:
        return AppColors.errorRed;
      case StorageRiskLevel.warning:
        return AppColors.warningOrange;
      case StorageRiskLevel.safe:
        return AppColors.neonGreen;
    }
  }

  String _fmtLive(double? value, String suffix) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}$suffix';
  }

  String _fmtInt(int value) {
    return value.toString();
  }

  String _date(DateTime d) {
    final m = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${d.day.toString().padLeft(2, '0')}-${m[d.month - 1]}-${d.year}';
  }
}

class TacticalCountdown extends StatefulWidget {
  final DateTime expiryDate;
  final bool isDark;

  const TacticalCountdown({
    super.key,
    required this.expiryDate,
    required this.isDark,
  });

  @override
  State<TacticalCountdown> createState() => _TacticalCountdownState();
}

class _TacticalCountdownState extends State<TacticalCountdown>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeLeft;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.expiryDate.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft = widget.expiryDate.difference(DateTime.now());
      });
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
      return const Text(
        'EXPIRED',
        style: TextStyle(
          color: AppColors.errorRed,
          fontSize: 10,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final d = _timeLeft.inDays;
    final h = _timeLeft.inHours % 24;
    final m = _timeLeft.inMinutes % 60;
    final s = _timeLeft.inSeconds % 60;
    final critical = d < 10;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final baseColor = critical
            ? Color.lerp(AppColors.errorRed, AppColors.errorRed.withOpacity(0.3), _pulseController.value)!
            : (widget.isDark ? AppColors.neonGreen : AppColors.lightText);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              critical ? 'CRITICAL' : 'COUNTDOWN',
              style: TextStyle(
                color: baseColor,
                fontSize: 8,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${d}D ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: baseColor,
                fontSize: 10,
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
