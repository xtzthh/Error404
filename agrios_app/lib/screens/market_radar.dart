import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../providers/theme_provider.dart';
import '../widgets/cyber_card.dart';

class MarketRadarScreen extends StatefulWidget {
  const MarketRadarScreen({super.key});

  @override
  State<MarketRadarScreen> createState() => _MarketRadarScreenState();
}

class _MarketRadarScreenState extends State<MarketRadarScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final titleColor = isDark ? Colors.white : AppColors.lightText;
    final chipBorder = isDark ? AppColors.getBorder(isDark) : AppColors.lightBorder;
    final chipSelected = const Color(0xFFDDEDDC);
    final alertBg = const Color(0xFFF8E7D7);
    final alertText = const Color(0xFF6A3A17);
    final mutedText = AppColors.getMutedText(isDark);

    final farmAlerts = [
      _AlertItem(
        category: 'Nutrition',
        time: '28 Jan, 09:00 AM',
        farm: 'Farm | Cotton',
        title: 'Pre-emergence weed Control',
        body:
            'Keeping cotton field weed free for initial 60 days is very important. To avoid weed problem spray the field with Pendimethalin 38.7% CS @ 3 ml/liter of water. Cover the complete field with spray solution. Ensure sufficient soil moisture in field at the time of application.',
        cta: 'View calendar',
        tagColor: const Color(0xFFC7663F),
      ),
      _AlertItem(
        category: 'Weather',
        time: '28 Jan, 06:19 AM',
        farm: 'Farm | Cotton',
        title: 'Dry Spell Predicted - Germination may affect.',
        body:
            'Dry spell with little or no rainfall is expected in next 10 days. Dry spell after sowing affects the seed germination. To maintain optimum plant population in field raise cotton nursery in polythene bags @400 - 500 seeds/acre and transplant when sufficient soil moisture is available.',
        cta: 'Record activity',
        tagColor: const Color(0xFFB76422),
      ),
    ];

    final weatherAlerts = [
      _AlertItem(
        category: 'Weather',
        time: '28 Jan, 06:19 AM',
        farm: 'Farm | Cotton',
        title: 'Dry Spell Predicted - Germination may affect.',
        body:
            'Dry spell with little or no rainfall is expected in next 10 days. Dry spell after sowing affects the seed germination. To maintain optimum plant population in field raise cotton nursery in polythene bags @400 - 500 seeds/acre and transplant when sufficient soil moisture is available.',
        cta: 'Record activity',
        tagColor: const Color(0xFFB76422),
      ),
    ];

    final nutritionAlerts = [
      _AlertItem(
        category: 'Nutrition',
        time: '28 Jan, 09:00 AM',
        farm: 'Farm_1 | Cotton',
        title: 'Pre-emergence weed Control',
        body:
            'Keeping cotton field weed free for initial 60 days is very important. To avoid weed problem spray the field with Pendimethalin 38.7% CS @ 3 ml/liter of water. Cover the complete field with spray solution. Ensure sufficient soil moisture in field at the time of application.',
        cta: 'View calendar',
        tagColor: const Color(0xFFC7663F),
      ),
    ];

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Alerts.',
              style: TextStyle(
                color: titleColor,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TabBar(
              labelColor: AppColors.lightText,
              unselectedLabelColor: titleColor,
              indicator: BoxDecoration(
                color: chipSelected,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipBorder),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Farm'),
                Tab(text: 'Weather'),
                Tab(text: 'Nutrition'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildAlertsList(
                  isDark: isDark,
                  alertBg: alertBg,
                  alertText: alertText,
                  mutedText: mutedText,
                  items: farmAlerts,
                ),
                _buildAlertsList(
                  isDark: isDark,
                  alertBg: alertBg,
                  alertText: alertText,
                  mutedText: mutedText,
                  items: weatherAlerts,
                ),
                _buildAlertsList(
                  isDark: isDark,
                  alertBg: alertBg,
                  alertText: alertText,
                  mutedText: mutedText,
                  items: nutritionAlerts,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AlertItem {
  final String category;
  final String time;
  final String farm;
  final String title;
  final String body;
  final String cta;
  final Color tagColor;

  _AlertItem({
    required this.category,
    required this.time,
    required this.farm,
    required this.title,
    required this.body,
    required this.cta,
    required this.tagColor,
  });
}

Widget _buildAlertsList({
  required bool isDark,
  required Color alertBg,
  required Color alertText,
  required Color mutedText,
  required List<_AlertItem> items,
}) {
  final cardText = isDark ? Colors.white : Colors.black;
  return ListView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alertBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: alertText.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.calendar_today, color: alertText, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add soil health report to receive precise nutrition advisory.',
                style: TextStyle(color: alertText, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: alertText),
          ],
        ),
      ),
      ...items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CyberCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.tagColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.time,
                      style: TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.farm,
                  style: TextStyle(color: mutedText, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    color: cardText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  style: TextStyle(color: mutedText, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                      foregroundColor: cardText,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(item.cta),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      const SizedBox(height: 60),
    ],
  );
}
