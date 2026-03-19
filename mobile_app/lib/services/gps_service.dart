import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles GPS location retrieval with permission checks and error handling.
class GpsService {
  /// Requests location permissions and returns true if granted.
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Gets the current GPS position.
  /// Returns null if location is unavailable or permission denied.
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission status
      final status = await Permission.location.status;
      if (!status.isGranted) {
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      return null;
    }
  }

  /// Gets GPS coordinates as a map for easy access.
  Future<Map<String, double>?> getCoordinates() async {
    final position = await getCurrentPosition();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'altitude': position.altitude,
        'accuracy': position.accuracy,
      };
    }
    return null;
  }

  /// Gets accuracy info (useful for SOS payload).
  Future<double?> getAccuracy() async {
    final position = await getCurrentPosition();
    return position?.accuracy;
  }
}
