import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String mapsUrl;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.mapsUrl,
  });
}

class LocationService {
  /// Request GPS permission and fetch current device position
  static Future<LocationResult?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        debugPrint("Location services are disabled.");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permission denied by user.");
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return null;
      }

      // Fetch accurate GPS coordinates
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final addressStr = 'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

      return LocationResult(
        latitude: lat,
        longitude: lng,
        formattedAddress: addressStr,
        mapsUrl: mapsUrl,
      );
    } catch (e) {
      debugPrint("Error obtaining GPS location: $e");
      return null;
    }
  }

  /// Open Google Maps / Yandex Maps for given query or coordinates
  static Future<void> openMap(String addressOrCoordinates) async {
    try {
      final query = Uri.encodeComponent(addressOrCoordinates);
      final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error opening map: $e");
    }
  }
}
