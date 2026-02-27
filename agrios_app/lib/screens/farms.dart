import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/cyber_card.dart';

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  bool _isPumpOn = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const SizedBox(height: 30),
          CyberCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Strictly take only minimum space
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.opacity, 
                    color: _isPumpOn ? Colors.blue : color, 
                    size: 40 // Smaller icon
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SOIL_MOISTURE_LEVEL',
                    style: TextStyle(
                      color: color,
                      fontSize: 12, // Smaller label
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPumpOn ? '64%' : '42%',
                    style: TextStyle(
                      color: color,
                      fontSize: 36, // Significantly smaller font to avoid overflow
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isPumpOn ? '// IRRIGATION_IN_PROGRESS' : '// SECTOR_ANALYSIS_STABLE',
                    style: TextStyle(
                      color: AppColors.getMutedText(isDark),
                      fontSize: 9, // Smaller subtext
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoGrid(isDark, color),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(bool isDark, Color color) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.0, // Square ratio for more vertical space
      children: [
        _pumpControlCard(isDark, color),
        _waterFlowCard(isDark, color),
        _infoCard('YIELD_PROJ', '+12%', isDark, color),
        _infoCard('RISK_LEVEL', 'LOW', isDark, color),
      ],
    );
  }

  Widget _waterFlowCard(bool isDark, Color color) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WATERFLOW',
                style: TextStyle(
                  color: AppColors.getMutedText(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
              Icon(
                Icons.speed,
                color: _isPumpOn ? Colors.blue : AppColors.getMutedText(isDark),
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isPumpOn ? '12.5' : '0.0',
            style: TextStyle(
              color: _isPumpOn ? Colors.blue : color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Liters per minute (Lpm)',
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 7,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _isPumpOn ? 0.65 : 0.0,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_isPumpOn ? Colors.blue : color.withOpacity(0.3)),
            minHeight: 2,
          ),
        ],
      ),
    );
  }

  Widget _pumpControlCard(bool isDark, Color color) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RELAY (PUMP)',
                style: TextStyle(
                  color: AppColors.getMutedText(isDark),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isPumpOn ? Colors.blue : Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isPumpOn) BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _isPumpOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: _isPumpOn ? Colors.blue : AppColors.errorRed,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              _tacticalButton(
                onTap: () => setState(() => _isPumpOn = !_isPumpOn),
                isDark: isDark,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'MANUAL_OVERRIDE',
            style: TextStyle(
              color: AppColors.getMutedText(isDark).withOpacity(0.5),
              fontSize: 7,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tacticalButton({required VoidCallback onTap, required bool isDark, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          _isPumpOn ? 'TURN_OFF' : 'TURN_ON',
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, bool isDark, Color color) {
    return CyberCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

