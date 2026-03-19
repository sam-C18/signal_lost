import 'package:flutter/material.dart';
import '../models/app_status.dart';
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
  // Mock status — in production, these come from platform services
  final AppStatus _status = const AppStatus(
    bluetoothEnabled: true,
    locationEnabled: true,
    internetConnected: false,
    wifiDirectEnabled: false, // off until user grants Wi-Fi Direct permission
  );

  bool _isSending = false;

  void _handleSosPressed() async {
    if (!_status.canSendSos) return;

    setState(() => _isSending = true);

    // Simulate a short activation delay before navigating
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isSending = false);

    Navigator.pushNamed(context, '/sos-active');
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

  // ── Status chips for BT / Wi-Fi Direct / GPS / Internet ──────────────────
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
            statusText: _status.bluetoothEnabled ? 'ON' : 'OFF',
            isActive: _status.bluetoothEnabled,
          ),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          StatusIndicator(
            icon: Icons.wifi_tethering_rounded,
            label: 'P2P',
            statusText: _status.wifiDirectEnabled ? 'ON' : 'OFF',
            isActive: _status.wifiDirectEnabled,
          ),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          StatusIndicator(
            icon: Icons.gps_fixed_rounded,
            label: 'GPS',
            statusText: _status.locationEnabled ? 'ON' : 'OFF',
            isActive: _status.locationEnabled,
          ),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          StatusIndicator(
            icon: Icons.wifi_rounded,
            label: 'NET',
            statusText: _status.internetConnected ? 'ON' : 'OFF',
            isActive: _status.internetConnected,
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
        if (!_status.canSendSos) _buildWarningBanner(),
        const SizedBox(height: 20),
        SosButton(
          isEnabled: _status.canSendSos,
          isSending: _isSending,
          onPressed: _handleSosPressed,
        ),
        const SizedBox(height: 28),
        Text(
          _status.canSendSos
              ? 'PRESS SOS TO SEND EMERGENCY SIGNAL'
              : 'ENABLE BLUETOOTH OR WI-FI DIRECT + GPS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _status.canSendSos
                ? AppTheme.textSecondary
                : AppTheme.warningOrange,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
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
            _status.bluetoothEnabled,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            Icons.wifi_tethering_rounded,
            'WI-FI P2P',
            _status.wifiDirectEnabled,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            Icons.signal_wifi_off_rounded,
            'NO INTERNET',
            false,
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
