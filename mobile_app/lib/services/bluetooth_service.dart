import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Service to handle Bluetooth permissions, hardware status, and messaging.
class BluetoothService {
  // Singleton pattern
  static final BluetoothService _instance = BluetoothService._internal();

  factory BluetoothService() {
    return _instance;
  }

  BluetoothService._internal();

  // Bluetooth connection and messaging state
  BluetoothConnection? _connection;
  List<BluetoothDevice> _discoveredDevices = [];
  final StreamController<String> _incomingMessagesController =
      StreamController<String>.broadcast();

  // Message counters and tracking
  int _sentCount = 0;
  int _receivedCount = 0;
  String _lastSentDevice = '';
  String _lastReceivedDevice = '';
  String _lastSentMessage = '';
  String _lastReceivedMessage = '';

  // Getters for UI updates
  int get sentCount => _sentCount;
  int get receivedCount => _receivedCount;
  String get lastSentDevice => _lastSentDevice;
  String get lastReceivedDevice => _lastReceivedDevice;
  String get lastSentMessage => _lastSentMessage;
  String get lastReceivedMessage => _lastReceivedMessage;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;

  /// Stream of incoming Bluetooth messages
  Stream<String> get incomingMessages => _incomingMessagesController.stream;

  /// Checks if the device's Bluetooth hardware is currently ON.
  Future<bool> isBluetoothEnabled() async {
    try {
      if (Platform.isAndroid) {
        BluetoothState state = await FlutterBluetoothSerial.instance.state;
        return state == BluetoothState.STATE_ON;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Requests the necessary Bluetooth runtime permissions from the user.
  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      return scan.isGranted && connect.isGranted;

    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return false;
  }

  /// Prompts the Android system to forcibly turn ON the Bluetooth radio.
  /// This will show a system pop-up asking the user to allow Bluetooth to be enabled.
  Future<bool> enableBluetoothHardware() async {
      if (Platform.isAndroid) {
        // This relies on the flutter_bluetooth_serial package to hit the native Android API
        bool? isEnabled = await FlutterBluetoothSerial.instance.requestEnable();
        return isEnabled ?? false;
      }
      return false;
    }

  /// Discover nearby Bluetooth devices
  Future<List<BluetoothDevice>> discoverDevices() async {
    try {
      if (Platform.isAndroid) {
        // For flutter_bluetooth_serial, get bonded devices
        final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
        _discoveredDevices = List<BluetoothDevice>.from(devices);
        return _discoveredDevices;
      }
    } catch (e) {
      print('Error discovering devices: $e');
    }
    return [];
  }

  /// Connect to a Bluetooth device (first available bonded device)
  Future<bool> connectToDevice() async {
    try {
      // Get bonded devices from the system
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final devices = List<BluetoothDevice>.from(bondedDevices);

      if (devices.isEmpty) {
        print('No bonded devices found');
        return false;
      }

      // Connect to first available device
      final device = devices.first;
      _connection = await BluetoothConnection.toAddress(device.address);

      _lastSentDevice = device.name ?? device.address;
      print('Connected to ${device.name}');

      // Listen for incoming messages
      _listenForIncomingMessages();
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      return false;
    }
  }

  /// Listen for incoming Bluetooth messages
  void _listenForIncomingMessages() {
    if (_connection == null) return;

    _connection!.input?.listen((data) {
      if (data.isNotEmpty) {
        String message = String.fromCharCodes(data).trim();
        _lastReceivedMessage = message;
        _receivedCount++;

        // Update last received device (already connected to)
        _lastReceivedDevice = _lastSentDevice;

        _incomingMessagesController.add(message);
        print('BT Message Received: $message');
      }
    }).onError((error) {
      print('BT Listen Error: $error');
    });
  }

  /// Send a text message over Bluetooth
  Future<bool> sendMessage(String message) async {
    try {
      if (_connection == null || !_connection!.isConnected) {
        print('Not connected to any device');
        return false;
      }

      // Convert string to List<int> (UTF-8 code units)
      final data = message.codeUnits;
      _connection!.output.add(Uint8List.fromList(data));
      _lastSentMessage = message;
      _sentCount++;

      print('BT Message Sent: $message');
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      if (_connection != null && _connection!.isConnected) {
        await _connection!.close();
        _connection = null;
      }
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Cleanup
  void dispose() {
    disconnect();
    _incomingMessagesController.close();
  }
}
