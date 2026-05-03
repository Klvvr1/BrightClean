import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Default to a central location
  LatLng _selectedLocation = const LatLng(25.2048, 55.2708);
  final MapController _mapController = MapController();

  // Task 1: Fetch Current Location using Geolocator
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء تفعيل خدمات الموقع (GPS)')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفض صلاحيات الوصول للموقع.')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('صلاحيات الموقع مرفوضة نهائياً من إعدادات الجهاز.')));
      }
      return;
    }

    // Permissions are granted, fetch position
    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('جاري تحديد موقعك...'), duration: Duration(seconds: 1)));
    }
    
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    
    final newLoc = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _selectedLocation = newLoc;
    });

    // Animate map camera to center on current location
    _mapController.move(newLoc, 15.0);
  }

  void _onSaveLocation() {
    final mockAddress = 'موقع محدد (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})';
    Navigator.of(context).pop(mockAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الموقع'),
        actions: [
          TextButton(
            onPressed: _onSaveLocation,
            child: const Text('حفظ', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point; 
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.brightclean.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin, color: AppColors.error, size: 50),
                  ),
                ],
              ),
            ],
          ),
          
          // Current Location FAB
          Positioned(
            bottom: 160,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'currentLocationBtn',
              backgroundColor: AppColors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Confirmation Card
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'اضغط على أي مكان في الخريطة لتغيير موقعك بدقة',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _onSaveLocation,
                        child: const Text('تأكيد الموقع وحفظه', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
