import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/sos_message.dart';

/// Manages Bluetooth Low Energy (BLE) fallback for mesh networking.
/// Provides BLE scanning and advertising as a secondary mesh transport.
class BleManager {
  static final BleManager _instance = BleManager._internal();

  factory BleManager() {
    return _instance;
  }

  BleManager._internal();

  final _flutterReactiveBle = FlutterReactiveBle();
  final StreamController<SosMessage> _incomingMessagesController =
      StreamController<SosMessage>.broadcast();

  // BLE Service/Characteristic UUIDs for SOS
  static final sosServiceUuid = Uuid.parse('12345678-1234-1234-1234-123456789012');
  static final sosCharacteristicUuid = Uuid.parse('87654321-4321-4321-4321-210987654321');

  List<DiscoveredDevice> _nearbyDevices = [];
  bool _isScanning = false;
  bool _isAdvertising = false;

  /// Stream of incoming SOS messages received via BLE
  Stream<SosMessage> get incomingMessages => _incomingMessagesController.stream;

  /// List of discovered nearby devices
  List<DiscoveredDevice> get nearbyDevices => _nearbyDevices;

  /// Start BLE scanning for nearby devices
  Future<bool> startScanning() async {
    if (_isScanning) return true;

    try {
      _flutterReactiveBle.scanForDevices(
        withServices: [sosServiceUuid],
        scanMode: ScanMode.balanced,
      ).listen(
        (device) {
          if (!_nearbyDevices.any((d) => d.id == device.id)) {
            _nearbyDevices.add(device);
            print('[BLE] Device found: ${device.name} (${device.id})');
          }
        },
        onError: (err) {
          print('[BLE] Scanning error: $err');
        },
      );

      _isScanning = true;
      print('[BLE] Scanning started');
      return true;
    } catch (e) {
      print('[BLE] Scanning start failed: $e');
      return false;
    }
  }

  /// Stop BLE scanning
  Future<bool> stopScanning() async {
    try {
      _isScanning = false;
      print('[BLE] Scanning stopped');
      return true;
    } catch (e) {
      print('[BLE] Scanning stop failed: $e');
      return false;
    }
  }

  /// Attempt to connect to a BLE device and subscribe to characteristic
  Future<bool> connectToDevice(DiscoveredDevice device) async {
    try {
                 _flutterReactiveBle.connectToDevice(
        id: device.id,
        connectionTimeout: const Duration(seconds: 10),
      ).listen(
        (connectionState) {
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            print('[BLE] Connected to: ${device.name}');
            _subscribeToCharacteristic(device.id);
          }
        },
        onError: (err) {
          print('[BLE] Connection error: $err');
        },
      );

      return true;
    } catch (e) {
      print('[BLE] Connection attempt failed: $e');
      return false;
    }
  }

  /// Subscribe to SOS characteristic for incoming messages
  void _subscribeToCharacteristic(String deviceId) {
    try {
      _flutterReactiveBle
          .subscribeToCharacteristic(
        QualifiedCharacteristic(
          serviceId: sosServiceUuid,
          characteristicId: sosCharacteristicUuid,
          deviceId: deviceId,
        ),
      )
          .listen(
        (data) {
          try {
            final jsonString = utf8.decode(data);
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final message = SosMessage.fromJson(json);
            print('[BLE] Received SOS: ${message.messageId}');
            _incomingMessagesController.add(message);
          } catch (e) {
            print('[BLE] Failed to parse message: $e');
          }
        },
        onError: (err) {
          print('[BLE] Subscription error: $err');
        },
      );
    } catch (e) {
      print('[BLE] Subscription failed: $e');
    }
  }

  /// Broadcast a SOS message via BLE to all nearby devices
  Future<bool> broadcastMessage(SosMessage message) async {
    try {
      if (_nearbyDevices.isEmpty) {
        print('[BLE] No devices to broadcast to');
        return false;
      }

      final jsonString = jsonEncode(message.toJson());
      final bytes = utf8.encode(jsonString);

      for (final device in _nearbyDevices) {
        try {
          await connectToDevice(device);
          // Send via characteristic write
          await _flutterReactiveBle.writeCharacteristicWithoutResponse(
            QualifiedCharacteristic(
              serviceId: sosServiceUuid,
              characteristicId: sosCharacteristicUuid,
              deviceId: device.id,
            ),
            value: bytes,
          );
          print('[BLE] Sent SOS to: ${device.name}');
        } catch (e) {
          print('[BLE] Failed to send to ${device.name}: $e');
        }
      }

      return true;
    } catch (e) {
      print('[BLE] Broadcast failed: $e');
      return false;
    }
  }

  /// Start advertising this device as a BLE peripheral (for receiving)
  Future<bool> startAdvertising({
    required String deviceName,
  }) async {
    if (_isAdvertising) return true;

    try {
      // Note: Direct BLE advertising API varies by platform.
      // This is a placeholder for cross-platform approach.
      _isAdvertising = true;
      print('[BLE] Advertising started as: $deviceName');
      return true;
    } catch (e) {
      print('[BLE] Advertising start failed: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<bool> stopAdvertising() async {
    try {
      _isAdvertising = false;
      print('[BLE] Advertising stopped');
      return true;
    } catch (e) {
      print('[BLE] Advertising stop failed: $e');
      return false;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await stopScanning();
    await stopAdvertising();
    _incomingMessagesController.close();
    print('[BLE] Disposed');
  }
}
