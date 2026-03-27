import 'package:flutter/material.dart';
import '../models/sos_message.dart';
import '../widgets/app_theme.dart';

/// Screen displayed before broadcasting SOS.
/// Shows message details and lets user review before confirming.
class SosConfirmationScreen extends StatefulWidget {
  final SosMessage message;

  const SosConfirmationScreen({
    super.key,
    required this.message,
  });

  @override
  State<SosConfirmationScreen> createState() => _SosConfirmationScreenState();
}

class _SosConfirmationScreenState extends State<SosConfirmationScreen> {
  bool _isConfirming = false;

  void _handleConfirm() {
    setState(() => _isConfirming = true);

    // Small delay for UI feedback, then navigate to active screen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, '/sos-active', arguments: widget.message);
    });
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            // Content
            Expanded(
              child: _buildContent(),
            ),
            // Buttons
            _buildButtonRow(),
          ],
        ),
      ),
    );
  }

  // ── Top bar with back button ─────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'CONFIRM SOS',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Content: SOS details ────────────────────────────────────────────
  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Title
        const Text(
          'REVIEW EMERGENCY SIGNAL',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Message ID card
        _buildDetailCard(
          icon: Icons.tag_rounded,
          label: 'Message ID',
          value: widget.message.messageId,
          copyable: true,
        ),
        const SizedBox(height: 12),

        // Coordinates card
        _buildDetailCard(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: widget.message.formattedCoordinates,
          copyable: true,
        ),
        const SizedBox(height: 12),

        // Accuracy card
        _buildDetailCard(
          icon: Icons.pin_drop_rounded,
          label: 'Accuracy',
          value: widget.message.formattedAccuracy,
          copyable: false,
        ),
        const SizedBox(height: 12),

        // Timestamp card
        _buildDetailCard(
          icon: Icons.access_time_rounded,
          label: 'Timestamp',
          value: widget.message.timestamp.toString().split('.')[0],
          copyable: false,
        ),
        const SizedBox(height: 24),

        // Warning banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.sosRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.sosRed.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.sosRed,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This will broadcast your location to nearby devices and alert rescue services if connected to internet.',
                  style: TextStyle(
                    color: AppTheme.sosRed.withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 0.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Detail card component ────────────────────────────────────────────
  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required bool copyable,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.sosRed, size: 14),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (copyable)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied: $label'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.surfaceCard,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    color: AppTheme.textMuted,
                    size: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Button row: Confirm / Cancel ─────────────────────────────────────
  Widget _buildButtonRow() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: GestureDetector(
              onTap: _isConfirming ? null : _handleCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isConfirming
                        ? AppTheme.borderColor
                        : AppTheme.textSecondary,
                  ),
                ),
                child: Text(
                  'CANCEL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isConfirming
                        ? AppTheme.textMuted
                        : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Confirm button
          Expanded(
            child: GestureDetector(
              onTap: _isConfirming ? null : _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isConfirming
                      ? AppTheme.sosRed.withValues(alpha: 0.6)
                      : AppTheme.sosRed,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isConfirming
                        ? AppTheme.sosRed.withValues(alpha: 0.6)
                        : AppTheme.sosRed,
                  ),
                ),
                child: _isConfirming
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(AppTheme.textPrimary),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRM & SEND',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
