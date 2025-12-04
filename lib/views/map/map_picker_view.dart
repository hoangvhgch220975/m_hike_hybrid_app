// lib/views/map/map_picker_view.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/web_map_service.dart';
import '../../services/location_service.dart';

class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  late final WebViewController _controller;
  final WebMapService _webMapService = WebMapService();
  final LocationService _locationService = LocationService();
  bool _isLoading = true;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  // Get current location and send to map
  Future<void> _getCurrentLocationAndSendToMap() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    // Default location - Hanoi (default fallback when GPS fails)
    const double defaultLat = 21.023989;
    const double defaultLon = 105.790357;

    try {
      print('🌍 [FLUTTER] Getting current location from device...');

      // Get current position from device
      final position = await _locationService.getCurrentLocation();

      double lat;
      double lon;
      String popupText;
      String snackBarMessage;
      Color snackBarColor;

      if (position != null) {
        // GPS success
        lat = position.latitude;
        lon = position.longitude;
        popupText = '📍 Your Current Location (from device)';
        snackBarMessage = '✅ Current location detected';
        snackBarColor = const Color(0xFF2C5E1A);

        print('✅ [FLUTTER] Got GPS location: $lat, $lon');
      } else {
        // GPS failed - use default location
        lat = defaultLat;
        lon = defaultLon;
        popupText = '📍 Default Location (Hanoi)';
        snackBarMessage = '⚠️ Using default location. GPS not available.';
        snackBarColor = Colors.orange;

        print('⚠️ [FLUTTER] GPS failed. Using default location: $lat, $lon');
      }

      // Send to map via JavaScript
      final jsCode = '''
        (function() {
          try {
            // Set location from Flutter
            if (typeof startLatLng !== 'undefined') {
              startLatLng = L.latLng($lat, $lon);
              if (typeof startMarker !== 'undefined') {
                startMarker.setLatLng(startLatLng);
                map.setView(startLatLng, 15);
                startMarker.bindPopup('$popupText').openPopup();
              }
              console.log('✅ Location set from Flutter:', $lat, $lon);
            }
          } catch (e) {
            console.error('❌ Error setting location:', e);
          }
        })();
      ''';

      await _controller.runJavaScript(jsCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
            duration: const Duration(seconds: 2),
            backgroundColor: snackBarColor,
          ),
        );
      }
    } catch (e) {
      print('❌ [FLUTTER] Error getting location: $e');
      print('⚠️ [FLUTTER] Falling back to default location');

      // Exception - fallback to default location
      final jsCode = '''
        (function() {
          try {
            if (typeof startLatLng !== 'undefined') {
              startLatLng = L.latLng($defaultLat, $defaultLon);
              if (typeof startMarker !== 'undefined') {
                startMarker.setLatLng(startLatLng);
                map.setView(startLatLng, 15);
                startMarker.bindPopup('📍 Default Location (Hanoi)').openPopup();
              }
              console.log('✅ Default location set:', $defaultLat, $defaultLon);
            }
          } catch (e) {
            console.error('❌ Error setting default location:', e);
          }
        })();
      ''';

      await _controller.runJavaScript(jsCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Using default location. Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'MapPickerChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // Parse the JSON message from the map using WebMapService
          try {
            print('🗺️ [MAP] RAW MESSAGE: ${message.message}');

            // Using WebMapService to parse message
            final data = _webMapService.parseMapPickerMessage(message.message);

            if (data == null) {
              print('❌ [MAP] Failed to parse message');
              return;
            }

            // Validate data
            if (!_webMapService.validateLocationData(data)) {
              print('❌ [MAP] Invalid location data');
              return;
            }

            // Log received data
            _webMapService.logReceivedData(data);

            // Check if distance is present
            if (data['distance'] != null) {
              print('✅ [MAP] Distance: ${_webMapService.formatDistance(data['distance'])} km');
            } else {
              print('⚠️ [MAP] No distance in payload. Map HTML may need update.');
            }

            print('📤 [MAP] Returning location data to form');

            // Return picked location to previous screen
            Navigator.of(context).pop(data);
          } catch (e) {
            print('❌ [MAP] ERROR: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Get current location from device and send to map
            // Delay ensures map JavaScript is fully loaded
            Future.delayed(const Duration(milliseconds: 1500), () {
              _getCurrentLocationAndSendToMap();
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_webMapService.getDefaultMapUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pick Location on Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C5E1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to use'),
                  content: const Text(
                    '1. App will auto-detect your current location\n'
                        '2. Or use the GPS button to refresh location\n'
                        '3. Search for a location using the search bar\n'
                        '4. Or tap anywhere on the map to pick\n'
                        '5. Tap confirm button to save location',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5E1A)),
              ),
            ),

          // Floating GPS button for refreshing location
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'gps_button',
              onPressed: _isGettingLocation ? null : _getCurrentLocationAndSendToMap,
              backgroundColor: const Color(0xFF2C5E1A),
              child: _isGettingLocation
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
