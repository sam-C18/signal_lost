import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Service to handle Bluetooth permissions and hardware status.
class BluetoothService {
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

  
}
