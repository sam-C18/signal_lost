import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import '../models/sos_message.dart';

/// Manages Wi-Fi Direct (P2P) mesh networking using Google Nearby Connections API.
/// Provides unified Bluetooth + Wi-Fi P2P broadcasting via the Nearby API.
class WifiDirectManager {
  static final WifiDirectManager _instance = WifiDirectManager._internal();

  factory WifiDirectManager() {
    return _instance;
  }

  WifiDirectManager._internal();

  final Nearby _nearby = Nearby();
  final StreamController<SosMessage> _incomingMessagesController =
      StreamController<SosMessage>.broadcast();

  List<String> _connectedDeviceIds = [];
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  /// Stream of incoming SOS messages from other devices
  Stream<SosMessage> get incomingMessages => _incomingMessagesController.stream;

  /// List of currently connected nearby devices
  List<String> get connectedDeviceIds => _connectedDeviceIds;

  /// Start advertising this device as an endpoint for nearby devices to discover
  Future<bool> startAdvertising({
    required String deviceName,
    String serviceId = 'com.signallost.sos',
  }) async {
    if (_isAdvertising) return true;

    try {
      // Use Strategy constant from nearby_connections
      await _nearby.startAdvertising(
        deviceName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
        serviceId: serviceId,
      );
      _isAdvertising = true;
      print('[WifiDirect] Advertising started: $deviceName');
      return true;
    } catch (e) {
      print('[WifiDirect] Advertising start failed: $e');
      return false;
    }
  }

  /// Start discovering nearby endpoints
  Future<bool> startDiscovery({
    String serviceId = 'com.signallost.sos',
  }) async {
    if (_isDiscovering) return true;

    try {
      await _nearby.startDiscovery(
        serviceId,
        Strategy.P2P_CLUSTER,
        onEndpointFound: _handleEndpointFound,
        onEndpointLost: (endpointId) => _handleEndpointLost(endpointId ?? ''),
      );
      _isDiscovering = true;
      print('[WifiDirect] Discovery started');
      return true;
    } catch (e) {
      print('[WifiDirect] Discovery start failed: $e');
      return false;
    }
  }

  /// Request connection to a discovered endpoint
  Future<bool> requestConnection(String endpointId) async {
    try {
      await _nearby.requestConnection(
        deviceName,
        endpointId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );
      return true;
    } catch (e) {
      print('[WifiDirect] Connection request failed: $e');
      return false;
    }
  }

  /// Broadcast a SOS message to all connected devices
  Future<bool> broadcastMessage(SosMessage message) async {
    try {
      final jsonString = jsonEncode(message.toJson());
      final bytes = utf8.encode(jsonString);

      for (final deviceId in _connectedDeviceIds) {
        try {
          await _nearby.sendBytesPayload(
            deviceId,
            bytes,
          );
        } catch (e) {
          print('[WifiDirect] Failed to send to $deviceId: $e');
        }
      }

      if (_connectedDeviceIds.isNotEmpty) {
        print('[WifiDirect] Broadcasted SOS to ${_connectedDeviceIds.length} device(s)');
        return true;
      }
      return false;
    } catch (e) {
      print('[WifiDirect] Broadcast failed: $e');
      return false;
    }
  }

  // Get device name for requests
  String get deviceName => 'SignalLost_Device';

  /// Handlers for Nearby Connections API callbacks

  void _handleConnectionInitiated(String endpointId, ConnectionInfo connectionInfo) {
    print('[WifiDirect] Connection initiated from: ${connectionInfo.endpointName}');
    // Auto-accept connections for mesh relay
    _acceptConnection(endpointId);
  }

  void _handleConnectionResult(String endpointId, Status status) {
    if (status == Status.CONNECTED) {
      if (!_connectedDeviceIds.contains(endpointId)) {
        _connectedDeviceIds.add(endpointId);
      }
      print('[WifiDirect] Connected to: $endpointId (total: ${_connectedDeviceIds.length})');
      _listenForMessages(endpointId);
    } else {
      _connectedDeviceIds.remove(endpointId);
      print('[WifiDirect] Connection failed with: $endpointId');
    }
  }

  void _handleDisconnected(String endpointId) {
    _connectedDeviceIds.remove(endpointId);
    print('[WifiDirect] Disconnected from: $endpointId (remaining: ${_connectedDeviceIds.length})');
  }

  void _handleEndpointFound(String endpointId, String endpointName, String serviceId) {
    print('[WifiDirect] Endpoint found: $endpointName ($endpointId)');
    // Automatically request connection to discovered endpoints
    requestConnection(endpointId);
  }

  void _handleEndpointLost(String endpointId) {
    print('[WifiDirect] Endpoint lost: $endpointId');
    _connectedDeviceIds.remove(endpointId);
  }

  void _acceptConnection(String endpointId) {
    try {
      _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: _handlePayloadReceived,
      );
    } catch (e) {
      print('[WifiDirect] Failed to accept connection: $e');
    }
  }

  void _listenForMessages(String endpointId) {
    try {
      _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: _handlePayloadReceived,
      );
    } catch (e) {
      print('[WifiDirect] Failed to set message listener: $e');
    }
  }

  void _handlePayloadReceived(String endpointId, Payload payload) {
    try {
      if (payload.type == PayloadType.BYTES) {
        final jsonString = utf8.decode(payload.bytes!);
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final message = SosMessage.fromJson(json);

        print('[WifiDirect] Received SOS: ${message.messageId} (relay count: ${message.relayCount})');
        _incomingMessagesController.add(message);
      }
    } catch (e) {
      print('[WifiDirect] Failed to parse message: $e');
    }
  }

  /// Stop advertising and discovery
  Future<void> stopAdvertising() async {
    try {
      await _nearby.stopAdvertising();
      _isAdvertising = false;
      print('[WifiDirect] Advertising stopped');
    } catch (e) {
      print('[WifiDirect] Failed to stop advertising: $e');
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _nearby.stopDiscovery();
      _isDiscovering = false;
      print('[WifiDirect] Discovery stopped');
    } catch (e) {
      print('[WifiDirect] Failed to stop discovery: $e');
    }
  }

  /// Disconnect from all devices and cleanup
  Future<void> disconnect() async {
    try {
      for (final deviceId in _connectedDeviceIds.toList()) {
        await _nearby.disconnectFromEndpoint(deviceId);
      }
      _connectedDeviceIds.clear();
      await stopAdvertising();
      await stopDiscovery();
      print('[WifiDirect] All disconnected and stopped');
    } catch (e) {
      print('[WifiDirect] Disconnect failed: $e');
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await disconnect();
    _incomingMessagesController.close();
  }
}
