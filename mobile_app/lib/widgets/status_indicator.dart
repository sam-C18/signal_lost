import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A compact row showing an icon, label, and color-coded status dot.
/// Used on the Home screen for Bluetooth / GPS /P2P.
class StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final String statusText;
  final bool isActive;

  const StatusIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.statusText,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.successGreen : AppTheme.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        // Status dot
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          statusText.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
