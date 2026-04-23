import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  
  // Default to Jeddah / Saudi Arabia coordinates
  LatLng _currentCenter = const LatLng(21.5433, 39.1728); 
  bool _isLoading = false;

  Future<void> _confirmLocation() async {
    setState(() {
      _isLoading = true;
    });

    String addressName = "موقع محدد (${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)})";

    try {
      // Try to acquire the actual readable address via native geocoding
      if (!kIsWeb) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentCenter.latitude,
          _currentCenter.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final elements = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).toList();

          if (elements.isNotEmpty) {
            addressName = elements.join('، ');
          }
        }
      } else {
        // Fallback for Web where native Geocoding isn't supported out of the box
        debugPrint("Geocoding bypassed on Web platform. Using raw coordinates.");
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context, {
          'coordinates': _currentCenter,
          'address': addressName,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد الموقع'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                setState(() {
                  _currentCenter = camera.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.brightcleanprojet', 
              ),
            ],
          ),
          
          // Fixed center pin pointing directly to the center coordinates
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), 
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50.0,
              ),
            ),
          ),

          // Loading overlay while geocoding
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            
          // Confirm button
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _confirmLocation,
              child: _isLoading 
                ? const SizedBox(
                    height: 24, width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text(
                    'تأكيد الموقع',
                    style: TextStyle(fontSize: 18),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
