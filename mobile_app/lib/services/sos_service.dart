import 'dart:async';
import 'dart:math';
import '../models/sos_message.dart';
import 'gps_service.dart';

/// Handles all SOS-related logic: message creation, relay simulation, cancellation.
/// Integrates real GPS data from GpsService.
class SosService {
  Timer? _relayTimer;
  final _random = Random();
  final _gpsService = GpsService();

  /// Generates a unique 8-character hex message ID
  String generateMessageId() {
    final hex = _random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return 'SOS-${hex.toUpperCase()}';
  }

  /// Creates a new SOS message with real GPS data only
  /// Throws exception if GPS is unavailable or permission denied
  Future<SosMessage> createSosMessage() async {
    // Try to get real GPS coordinates
    final coords = await _gpsService.getCoordinates();
    
    // Require real GPS data — no fallback
    if (coords == null) {
      throw Exception('GPS location unavailable. Check permissions and try again.');
    }
    
    final latitude = coords['latitude']!;
    final longitude = coords['longitude']!;
    final altitude = coords['altitude'] ?? 0.0;
    final accuracy = coords['accuracy'] ?? 0.0; 

    return SosMessage(
      messageId: generateMessageId(),
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy, 
      timestamp: DateTime.now(),
      relayCount: 0,
      isActive: true,
    );
  }

  /// Simulates relay count increasing as nearby devices pick up the signal.
  /// [onRelayUpdate] fires every time the relay count changes.
  void startRelaySimulation(
    SosMessage message,
    Function(SosMessage updated) onRelayUpdate,
  ) {
    int count = 0;
    _relayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (count < 5) {
        count++;
        onRelayUpdate(message.copyWith(relayCount: count));
      } else {
        timer.cancel();
      }
    });
  }

  /// Stops any ongoing relay simulation
  void cancelSos() {
    _relayTimer?.cancel();
    _relayTimer = null;
  }

  void dispose() {
    _relayTimer?.cancel();
  }
}
