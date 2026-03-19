import 'package:flutter/material.dart';
import '../widgets/app_theme.dart';

/// Settings screen — manage all permissions required by SignalLost.
///
/// Mesh transport permissions (any ONE is enough to send SOS):
///   • Bluetooth   — BLE/Classic mesh relay between nearby devices
///   • Wi-Fi Direct (P2P) — higher-range, higher-bandwidth relay channel
///                   Android: ACCESS_WIFI_STATE + CHANGE_WIFI_STATE
///                            + ACCESS_FINE_LOCATION (required by Android for P2P discovery)
///                   iOS:     MultipeerConnectivity framework (Wi-Fi + BT combined)
///
/// Location permission (REQUIRED for SOS GPS payload):
///   • Android: ACCESS_FINE_LOCATION
///   • iOS: NSLocationWhenInUseUsageDescription
///
/// Background mode (OPTIONAL — improves relay coverage):
///   • Android: FOREGROUND_SERVICE + RECEIVE_BOOT_COMPLETED
///   • iOS: Background Modes → bluetooth-central + location
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock toggle state — replace with real platform calls in production
  bool _bluetoothEnabled = true;
  bool _wifiDirectEnabled = false; // starts off — requires explicit grant
  bool _locationEnabled = true;
  bool _backgroundEnabled = false;

  /// SOS can fire if at least one mesh transport + location are enabled
  bool get _canSendSos =>
      (_bluetoothEnabled || _wifiDirectEnabled) && _locationEnabled;

  /// Both mesh channels active = maximum relay coverage
  bool get _isDualMesh => _bluetoothEnabled && _wifiDirectEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Mesh Transport ─────────────────────────────────────
                  _buildSectionLabel('MESH TRANSPORT'),
                  const SizedBox(height: 4),
                  _buildSectionNote(
                    'At least one transport must be active to send SOS.',
                  ),
                  const SizedBox(height: 10),

                  // Bluetooth card
                  _buildToggleCard(
                    icon: Icons.bluetooth_rounded,
                    title: 'Bluetooth',
                    subtitle: 'BLE/Classic mesh relay — short range, low power',
                    badgeLabel: 'MESH',
                    value: _bluetoothEnabled,
                    onChanged: (v) => setState(() => _bluetoothEnabled = v),
                    actionLabel: _bluetoothEnabled ? null : 'ENABLE BLUETOOTH',
                    onAction: _bluetoothEnabled
                        ? null
                        : () => setState(() => _bluetoothEnabled = true),
                    permNote:
                        'Android: BLUETOOTH_CONNECT + BLUETOOTH_SCAN\n'
                        'iOS: NSBluetoothAlwaysUsageDescription',
                  ),
                  const SizedBox(height: 10),

                  // Wi-Fi Direct card
                  _buildToggleCard(
                    icon: Icons.wifi_tethering_rounded,
                    title: 'Wi-Fi Direct (P2P)',
                    subtitle:
                        'Device-to-device WiFi — longer range, higher speed',
                    badgeLabel: 'P2P',
                    badgeColor: AppTheme.wifiBlue,
                    value: _wifiDirectEnabled,
                    onChanged: (v) => setState(() => _wifiDirectEnabled = v),
                    actionLabel:
                        _wifiDirectEnabled ? null : 'ENABLE WI-FI DIRECT',
                    onAction: _wifiDirectEnabled
                        ? null
                        : () => setState(() => _wifiDirectEnabled = true),
                    permNote:
                        'Android: ACCESS_WIFI_STATE + CHANGE_WIFI_STATE\n'
                        '+ ACCESS_FINE_LOCATION (required for P2P discovery)\n'
                        'iOS: MultipeerConnectivity (Wi-Fi + BT combined)',
                    highlightColor: AppTheme.wifiBlue,
                  ),

                  // Dual-mesh badge when both are on
                  if (_isDualMesh) ...[
                    const SizedBox(height: 10),
                    _buildDualMeshBanner(),
                  ],

                  const SizedBox(height: 20),

                  // ── Location ───────────────────────────────────────────
                  _buildSectionLabel('LOCATION'),
                  const SizedBox(height: 4),
                  _buildSectionNote(
                    'GPS coordinates are embedded in every SOS broadcast.',
                  ),
                  const SizedBox(height: 10),
                  _buildToggleCard(
                    icon: Icons.gps_fixed_rounded,
                    title: 'Location / GPS',
                    subtitle: 'Embeds coordinates in SOS payload',
                    value: _locationEnabled,
                    onChanged: (v) => setState(() => _locationEnabled = v),
                    actionLabel:
                        _locationEnabled ? null : 'GRANT LOCATION ACCESS',
                    onAction: _locationEnabled
                        ? null
                        : () => setState(() => _locationEnabled = true),
                    permNote:
                        'Android: ACCESS_FINE_LOCATION\n'
                        'iOS: NSLocationWhenInUseUsageDescription',
                  ),

                  const SizedBox(height: 20),

                  // ── Background ─────────────────────────────────────────
                  _buildSectionLabel('BACKGROUND'),
                  const SizedBox(height: 4),
                  _buildSectionNote(
                    'Optional — keeps relay active when app is minimised.',
                  ),
                  const SizedBox(height: 10),
                  _buildToggleCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Background Mode',
                    subtitle: 'Relay SOS signals while app is closed',
                    value: _backgroundEnabled,
                    onChanged: (v) => setState(() => _backgroundEnabled = v),
                    permNote:
                        'Android: FOREGROUND_SERVICE + RECEIVE_BOOT_COMPLETED\n'
                        'iOS: Background Modes → bluetooth-central + location',
                  ),

                  const SizedBox(height: 24),

                  // ── About ──────────────────────────────────────────────
                  _buildSectionLabel('ABOUT'),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    title: 'SignalLost v1.0.0',
                    subtitle: 'Emergency mesh SOS — no internet required',
                  ),
                  _buildInfoCard(
                    icon: Icons.security_rounded,
                    title: 'Data Privacy',
                    subtitle:
                        'All signals are end-to-end encrypted. No server storage.',
                  ),
                  _buildInfoCard(
                    icon: Icons.hub_rounded,
                    title: 'Dual Mesh Protocol',
                    subtitle:
                        'Bluetooth + Wi-Fi P2P work in parallel for maximum reach.',
                  ),

                  const SizedBox(height: 20),
                  _buildStatusSummary(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Back header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'SETTINGS',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 10,
        letterSpacing: 3,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSectionNote(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
        letterSpacing: 0.3,
      ),
    );
  }

  // ── Permission toggle card ─────────────────────────────────────────────────
  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? badgeLabel,
    Color? badgeColor,
    Color? highlightColor,
    String? actionLabel,
    VoidCallback? onAction,
    String? permNote,
  }) {
    final activeColor = highlightColor ?? AppTheme.successGreen;
    final stateColor = value ? activeColor : AppTheme.sosRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppTheme.borderColor
              : AppTheme.sosRed.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: stateColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (badgeLabel != null) ...[
                          const SizedBox(width: 8),
                          _buildBadge(
                            badgeLabel,
                            badgeColor ?? AppTheme.successGreen,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: activeColor,
                inactiveThumbColor: AppTheme.textMuted,
                inactiveTrackColor: AppTheme.disabledGrey,
              ),
            ],
          ),

          // Platform permission manifest note
          if (permNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                permNote,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.3,
                  height: 1.6,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],

          // Action button when permission is not granted
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlightColor ?? AppTheme.sosRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ── Dual mesh active banner ────────────────────────────────────────────────
  Widget _buildDualMeshBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successGreen.withValues(alpha: 0.08),
            AppTheme.wifiBlue.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_rounded,
              color: AppTheme.successGreen, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 11),
                children: [
                  TextSpan(
                    text: 'DUAL MESH ACTIVE ',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextSpan(
                    text:
                        '— BT + Wi-Fi P2P running in parallel. '
                        'Maximum relay range and redundancy.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Static info card ───────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── System-wide readiness summary ──────────────────────────────────────────
  Widget _buildStatusSummary() {
    final String message;
    final Color color;
    final IconData icon;

    if (_canSendSos && _isDualMesh) {
      message = 'All systems ready. Dual mesh active — maximum coverage.';
      color = AppTheme.successGreen;
      icon = Icons.check_circle_outline_rounded;
    } else if (_canSendSos) {
      message = 'SOS ready. Enable Wi-Fi Direct for dual mesh coverage.';
      color = AppTheme.warningOrange;
      icon = Icons.info_outline_rounded;
    } else {
      message =
          'Enable at least one mesh transport + location to activate SOS.';
      color = AppTheme.sosRed;
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
