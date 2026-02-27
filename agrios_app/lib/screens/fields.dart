import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';
import '../providers/theme_provider.dart';
import '../providers/field_provider.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FieldsRegistry(showHeader: true);
  }
}

class FieldsRegistry extends StatelessWidget {
  final bool showHeader;

  const FieldsRegistry({super.key, required this.showHeader});

  void _showAddFieldDialog(BuildContext context) {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final ownerController = TextEditingController();
    final areaController = TextEditingController();
    final phoneController = TextEditingController();
    final cropController = TextEditingController(); // Added this
    final isDark = Provider.of<ThemeProvider>(
      context,
      listen: false,
    ).isDarkMode;
    bool isFetching = false;
    String? locationError;
    bool didAutoFetch = false;

    Future<void> fetchLocation(StateSetter setState) async {
      setState(() {
        isFetching = true;
        locationError = null;
      });
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            locationError = 'Location services are off';
            isFetching = false;
          });
          return;
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied) {
          setState(() {
            locationError = 'Location permission denied';
            isFetching = false;
          });
          return;
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() {
            locationError = 'Location permission denied forever';
            isFetching = false;
          });
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        latController.text = position.latitude.toStringAsFixed(6);
        lngController.text = position.longitude.toStringAsFixed(6);
        setState(() => isFetching = false);
      } catch (_) {
        setState(() {
          locationError = 'Unable to fetch location';
          isFetching = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (!didAutoFetch) {
            didAutoFetch = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchLocation(setState);
            });
          }

          return AlertDialog(
            backgroundColor: isDark ? AppColors.cyberBlack : Colors.white,
            title: Text(
              'REGISTER_NEW_FIELD',
              style: TextStyle(
                color: isDark ? AppColors.neonGreen : AppColors.lightText,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFieldInput('SITE_NAME', nameController, isDark),
                  _buildFieldInput('CROP_NAME (e.g. Cotton)', cropController, isDark), // Added this
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: isFetching
                          ? null
                          : () => fetchLocation(setState),
                      icon: const Icon(Icons.my_location, size: 16),
                      label: Text(
                        isFetching
                            ? 'FETCHING_LOCATION'
                            : 'USE_CURRENT_LOCATION',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.neonGreen
                            : AppColors.lightText,
                        side: BorderSide(color: AppColors.getBorder(isDark)),
                      ),
                    ),
                  ),
                  if (locationError != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        locationError!,
                        style: const TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFieldInput(
                          'LATITUDE',
                          latController,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFieldInput(
                          'LONGITUDE',
                          lngController,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  _buildFieldInput('OWNER_NAME', ownerController, isDark),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFieldInput(
                          'AREA_ACRES',
                          areaController,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFieldInput(
                          'PHONE',
                          phoneController,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: AppColors.getMutedText(isDark)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.neonGreen
                      : AppColors.lightText,
                  foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Provider.of<FieldProvider>(context, listen: false).addField(
                      Field(
                        id: 'site${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text,
                        owner: ownerController.text,
                        phone: phoneController.text,
                        area: '${areaController.text} acres',
                        crop: cropController.text.isEmpty ? 'Tomato' : cropController.text, // Fixed this
                        lat: double.tryParse(latController.text) ?? 0.0,
                        lng: double.tryParse(lngController.text) ?? 0.0,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'SAVE_PROTOCOL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFieldInput(
    String label,
    TextEditingController controller,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.getMutedText(isDark),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            style: TextStyle(
              color: isDark ? AppColors.neonGreen : AppColors.lightText,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.black26 : Colors.grey[100],
              border: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.getBorder(isDark)),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldProvider = Provider.of<FieldProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Column(
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIELDS_REGISTRY',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.neonGreen
                            : AppColors.lightText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SATELLITE_VIEW / INSTALLED_SITES',
                      style: TextStyle(
                        color: AppColors.getMutedText(isDark),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_box,
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                  ),
                  onPressed: () => _showAddFieldDialog(context),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FIELDS_REGISTRY',
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_box,
                    color: isDark ? AppColors.neonGreen : AppColors.lightText,
                  ),
                  onPressed: () => _showAddFieldDialog(context),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: fieldProvider.fields.length,
            itemBuilder: (context, index) {
              final field = fieldProvider.fields[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CyberCard(
                  height: 350,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Tactical Map with Error Handling
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          color: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                'https://static-maps.yandex.ru/1.x/?ll=${field.lng},${field.lat}&z=14&l=sat&size=450,250',
                                fit: BoxFit.cover,
                                opacity: const AlwaysStoppedAnimation(0.8),
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.satellite_alt,
                                          color: Colors.grey[700],
                                          size: 40,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'SIGNAL_LOST: INVALID_COORDINATES',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 10,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: AppColors.neonGreen,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  field.name,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.neonGreen
                                        : AppColors.lightText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.errorRed,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Provider.of<FieldProvider>(
                                      context,
                                      listen: false,
                                    ).removeField(field.id);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _metaItem('OWNER', field.owner, isDark),
                                _metaItem('AREA', field.area, isDark),
                                _metaItem('CROP', field.crop, isDark), // Show crop name
                                _metaItem('PHONE', field.phone, isDark),
                              ],
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
      ],
    );
  }

  Widget _metaItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.getMutedText(isDark),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.neonGreen : AppColors.lightText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
