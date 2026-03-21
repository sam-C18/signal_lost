// Represents the connectivity and permission status of the device
class AppStatus {
  final bool bluetoothEnabled;
  final bool locationEnabled;

  /// Wi-Fi Direct (P2P) permission — allows device-to-device WiFi without
  /// a router. Used as a secondary mesh channel alongside Bluetooth.
  /// Android: ACCESS_WIFI_STATE + CHANGE_WIFI_STATE + ACCESS_FINE_LOCATION
  /// iOS: requires NetworkExtension entitlement (MultipeerConnectivity)
  final bool wifiDirectEnabled;

  const AppStatus({
    required this.bluetoothEnabled,
    required this.locationEnabled,
    required this.wifiDirectEnabled,
  });

  /// SOS can be triggered when Bluetooth OR Wi-Fi Direct is available,
  /// AND Location is granted (needed to embed GPS in the SOS payload).
  bool get canSendSos =>
      (bluetoothEnabled || wifiDirectEnabled) && locationEnabled;

  /// True when both mesh transports are active — maximum relay coverage
  bool get isDualMesh => bluetoothEnabled && wifiDirectEnabled;

  AppStatus copyWith({
    bool? bluetoothEnabled,
    bool? locationEnabled,
    bool? wifiDirectEnabled,
  }) {
    return AppStatus(
      bluetoothEnabled: bluetoothEnabled ?? this.bluetoothEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      wifiDirectEnabled: wifiDirectEnabled ?? this.wifiDirectEnabled,
    );
  }
}
