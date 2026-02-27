import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/cyber_card.dart';
import 'fields.dart';

class SettingsFieldsScreen extends StatelessWidget {
  const SettingsFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.tune,
                color: isDark ? AppColors.neonGreen : AppColors.lightText,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CyberCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _settingTile(
                  isDark,
                  icon: Icons.notifications_active,
                  title: 'Notifications',
                  subtitle: 'Alerts, irrigation, weather',
                ),
                const Divider(height: 16),
                _settingTile(
                  isDark,
                  icon: Icons.location_on,
                  title: 'Location',
                  subtitle: 'Use current device GPS',
                ),
                const Divider(height: 16),
                _settingTile(
                  isDark,
                  icon: Icons.security,
                  title: 'Privacy',
                  subtitle: 'Device data protection',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: FieldsRegistry(showHeader: false)),
      ],
    );
  }

  Widget _settingTile(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppColors.neonGreen : AppColors.lightText,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.getMutedText(isDark),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: AppColors.getMutedText(isDark)),
      ],
    );
  }
}
