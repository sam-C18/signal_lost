import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
// import '../models/app_status.dart';
import '../services/gps_service.dart';
import '../services/bluetooth_service.dart';
import '../services/sos_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/status_indicator.dart';
import '../widgets/sos_button.dart';

/// Home screen — the first screen users see.
/// Shows device status, the SOS button, and navigation to Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _isSending = false;

  final GpsService _gpsService = GpsService();
  final BluetoothService btService = BluetoothService();
  final SosService _sosService = SosService();
  bool _locationEnabled = false;
  bool _bluetoothEnabled = false;
  bool _wifiDirectManager = false;

  // Bluetooth messaging state
  int _btSentCount = 0;
  int _btReceivedCount = 0;

  bool get _canSendSos{
    return _bluetoothEnabled && _locationEnabled;
  }

  @override
  void initState() {
    super.initState();
    _initServices();
    _subscribeToBluetoothMessages();
  }

  /// Subscribe to incoming Bluetooth messages
  void _subscribeToBluetoothMessages() {
    btService.incomingMessages.listen((message) {
      if (!mounted) return;
      setState(() {
        _btReceivedCount = btService.receivedCount;
      });
    });
  }
  Future<void> _initServices() async{
    await _checkBluetooth();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkGps();
    // Request WiFi Direct permission (Android 13+)
    await _requestNearbyWifiPermission();
  }

  /// Request NEARBY_WIFI_DEVICES permission for WiFi Direct (Android 13+)
  Future<void> _requestNearbyWifiPermission() async {
    try {
      final status = await Permission.nearbyWifiDevices.request();
      if (status.isDenied) {
        print('NEARBY_WIFI_DEVICES permission denied');
      } else if (status.isGranted) {
        print('NEARBY_WIFI_DEVICES permission granted');
      }
    } catch (e) {
      print('Error requesting WiFi permission: $e');
    }
  }
Future<void> _checkBluetooth() async {
  final hasPermission = await btService.requestBluetoothPermissions();

  // Force Bluetooth ON (popup)
  await btService.enableBluetoothHardware();

  // Thoda sa wait (important, warna false aa sakta hai)
  await Future.delayed(const Duration(milliseconds: 500));

  final isBtOn = await btService.isBluetoothEnabled();

  if (!mounted) return;

  setState(() {
    _bluetoothEnabled = hasPermission && isBtOn;
  });
}
  
  Future<void> _checkGps() async {
    final hasPermission = await _gpsService.requestLocationPermission();
    final serviceEnabled = await _gpsService.isLocationServiceEnabled();

    if (!mounted) return;

    setState(() {
      _locationEnabled = hasPermission && serviceEnabled;
    });
  }

  void _handleSosPressed() async {
    if (!_canSendSos) return;

    setState(() => _isSending = true);

    try {
      // Create SOS message with GPS and device ID
      final sosMessage = await _sosService.createSosMessage();

      if (!mounted) return;
      setState(() => _isSending = false);

      // Navigate to confirmation screen to review before broadcasting
      Navigator.pushNamed(context, '/sos-confirm', arguments: sosMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.sosRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatusBar(),
            Expanded(child: _buildCenter()),
            _buildBottomHint(),
          ],
        ),
      ),
    );
  }

  // ── Top bar with app name and settings icon ──────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo / wordmark
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.sosRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SIGNALLOST',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          // Settings button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status chips for BT / Wi-Fi Direct / GPS ──────────────────
  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatusIndicator(
            icon: Icons.bluetooth_rounded,
            label: 'BT',
            statusText: _bluetoothEnabled ? 'ON' : 'OFF',
            isActive: _bluetoothEnabled,
          ),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          StatusIndicator(
            icon: Icons.wifi_tethering_rounded,
            label: 'P2P',
            statusText: _wifiDirectManager ? 'ON' : 'OFF',
            isActive: _wifiDirectManager,
          ),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          StatusIndicator(
            icon: Icons.gps_fixed_rounded,
            label: 'GPS',
            statusText: _locationEnabled ? 'ON' : 'OFF',
            isActive: _locationEnabled,
          ),
        ],
      ),
    );
  }

  // ── Center content: SOS button ───────────────────────────────────────────
  Widget _buildCenter() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Warning banner if permissions missing
        if (!_canSendSos) _buildWarningBanner(),
        const SizedBox(height: 20),
        SosButton(
          isEnabled: _canSendSos,
          isSending: _isSending,
          onPressed: _handleSosPressed,
        ),
        const SizedBox(height: 28),
        Text(
          _canSendSos
              ? 'PRESS SOS TO SEND EMERGENCY SIGNAL'
              : 'ENABLE BLUETOOTH OR WI-FI DIRECT + GPS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _canSendSos
                ? AppTheme.textSecondary
                : AppTheme.warningOrange,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        // Bluetooth messaging stats
        Text(
          'BT: Sent: $_btSentCount | Received: $_btReceivedCount',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppTheme.warningOrange, size: 14),
          SizedBox(width: 8),
          Text(
            'PERMISSIONS REQUIRED',
            style: TextStyle(
              color: AppTheme.warningOrange,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom mode chips ─────────────────────────────────────────────────────
  Widget _buildBottomHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildModeChip(
            Icons.bluetooth_searching_rounded,
            'BT MESH',
            _bluetoothEnabled,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            Icons.wifi_tethering_rounded,
            'WI-FI P2P',
            _wifiDirectManager,
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(IconData icon, String label, bool highlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.sosRed.withValues(alpha: 0.08)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppTheme.sosRed.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: highlighted ? AppTheme.sosRed : AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? AppTheme.sosRed : AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
