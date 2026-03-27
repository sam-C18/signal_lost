import 'dart:async';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/sos_message.dart';
import '../network/wifi_direct_manager.dart';
import '../network/ble_manager.dart';
import '../sos/sos_repository.dart';
import 'gps_service.dart';

/// Handles all SOS-related logic: message creation, mesh broadcasting, relay.
/// Integrates real GPS data from GpsService and mesh networking.
class SosService {
  Timer? _relayTimer;
  final _random = Random();
  final _gpsService = GpsService();
  final wifiDirectManager = WifiDirectManager();
  final bleManager = BleManager();
  final _sosRepository = SosRepository();
  final _deviceInfo = DeviceInfoPlugin();

  /// Generates a unique 8-character hex message ID
  String generateMessageId() {
    final hex = _random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return 'SOS-${hex.toUpperCase()}';
  }

  /// Get this device's ID (brand + model)
  Future<String> getDeviceId() async {
    try {
      if (true) { // Android
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand}_${androidInfo.model}'
            .replaceAll(' ', '_')
            .toUpperCase();
      }
    } catch (e) {
      print('Failed to get device ID: $e');
    }
    return 'UNKNOWN_DEVICE';
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
    final deviceId = await getDeviceId();

    return SosMessage(
      messageId: generateMessageId(),
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      relayCount: 0,
      isActive: true,
      deviceId: deviceId,
    );
  }

  /// Broadcast SOS message to nearby devices via mesh
  Future<bool> broadcastSos(SosMessage message) async {
    try {
      // Cache the message locally to prevent rebroadcast
      _sosRepository.cacheMessage(message.messageId, message.deviceId);

      // Broadcast via Wi-Fi Direct
      final wfResult = await wifiDirectManager.broadcastMessage(message);

      // Broadcast via BLE fallback
      final bleResult = await bleManager.broadcastMessage(message);

      print('[SosService] Broadcasted SOS ${message.messageId}: WiFi=$wfResult, BLE=$bleResult');
      return wfResult || bleResult;
    } catch (e) {
      print('[SosService] Broadcast failed: $e');
      return false;
    }
  }

  /// Handle incoming SOS message from other device - relay if not duplicate
  Future<void> broadcastSosRelay(
    SosMessage incomingMessage,
    Function(SosMessage?) onRelayUpdate,
  ) async {
    try {
      // Check if we've seen this message before (deduplication)
      if (_sosRepository.isDuplicate(incomingMessage.messageId)) {
        print('[SosService] Duplicate SOS ignored: ${incomingMessage.messageId}');
        return;
      }

      // Check hop limit (max 10 hops)
      if (!_sosRepository.canRelay(incomingMessage.messageId)) {
        print('[SosService] SOS relay limit reached: ${incomingMessage.messageId}');
        return;
      }

      // Cache this message
      _sosRepository.cacheMessage(incomingMessage.messageId, incomingMessage.deviceId);

      // Increment relay count and add this device to chain
      final deviceId = await getDeviceId();
      _sosRepository.addToRelayChain(incomingMessage.messageId, deviceId);

      final relayedMessage = incomingMessage.copyWith(
        relayCount: incomingMessage.relayCount + 1,
      );

      // Relay to other nearby devices
      await broadcastSos(relayedMessage);

      print('[SosService] Relayed SOS ${incomingMessage.messageId} (hop: ${relayedMessage.relayCount})');

      // Notify UI of relay
      onRelayUpdate(relayedMessage);
    } catch (e) {
      print('[SosService] Relay failed: $e');
      onRelayUpdate(null);
    }
  }

  /// Simulates relay count increasing as nearby devices pick up the signal.
  /// [onRelayUpdate] fires every time the relay count changes.
  /// This is kept for backward compatibility / UI animation.
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
    wifiDirectManager.dispose();
    bleManager.dispose();
  }
}
