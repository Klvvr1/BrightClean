import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({
    super.key,
    this.initialLocation = const LatLng(24.7136, 46.6753), // Riyadh default
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = null; // Do not mark initial as selected
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الموقع'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                // Use a dark map tile provider for dark mode if desired, but openstreetmap is light by default
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.brightclean.app',
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
                // Add a slight color filter in dark mode to make the map less glaring
                tileBuilder: (context, widget, tile) {
                  if (isDark) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -1,  0,  0, 0, 255,
                         0, -1,  0, 0, 255,
                         0,  0, -1, 0, 255,
                         0,  0,  0, 1,   0,
                      ]),
                      child: widget,
                    );
                  }
                  return widget;
                },
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: AppSpacing.xl,
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.card,
                    boxShadow: AppShadows.getMd(context),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'اضغط على الخريطة لتحديد موقعك بدقة',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedLocation == null
                        ? null
                        : () => Navigator.pop(context, {
                              'coordinates': _selectedLocation,
                              'address':
                                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                            }),
                    child: const Text('تأكيد الموقع الحالي'),
                  ),
                ),
              ],
            ),
          ),
          // Floating Action Button for Reset
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: FloatingActionButton.small(
              onPressed: () {
                _mapController.move(widget.initialLocation, 13.0);
                setState(() {
                  _selectedLocation = widget.initialLocation;
                });
              },
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
