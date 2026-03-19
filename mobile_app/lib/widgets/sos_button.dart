import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Animated SOS button with three pulsing rings.
/// When [isEnabled] is false, shows a grey disabled state.
/// When [isSending] is true, shows a spinner while activating.
class SosButton extends StatefulWidget {
  final bool isEnabled;
  final bool isSending;
  final VoidCallback? onPressed;

  const SosButton({
    super.key,
    required this.isEnabled,
    required this.isSending,
    this.onPressed,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isEnabled ? AppTheme.sosRed : AppTheme.disabledGrey;
    final glowColor = widget.isEnabled ? AppTheme.sosRed : AppTheme.disabledGrey;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Pulsing rings (only when enabled) ──────────────────────────
          if (widget.isEnabled) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return _PulseRing(
                  scale: 1.0 + _pulseAnimation.value * 0.45,
                  opacity: (1.0 - _pulseAnimation.value) * 0.25,
                  color: glowColor,
                  size: 180,
                );
              },
            ),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // Offset the second ring by half a cycle
                final offset =
                    (_pulseAnimation.value + 0.4) % 1.0;
                return _PulseRing(
                  scale: 1.0 + offset * 0.45,
                  opacity: (1.0 - offset) * 0.18,
                  color: glowColor,
                  size: 180,
                );
              },
            ),
          ],

          // ── Main button ─────────────────────────────────────────────────
          GestureDetector(
            onTap: widget.isEnabled && !widget.isSending
                ? widget.onPressed
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
                boxShadow: widget.isEnabled
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.2),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: widget.isSending
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: widget.isEnabled ? 1.0 : 0.4),
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 40,
                            height: 1.5,
                            color: Colors.white
                                .withValues(alpha: widget.isEnabled ? 0.4 : 0.15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PRESS',
                            style: TextStyle(
                              color: Colors.white
                                  .withValues(alpha: widget.isEnabled ? 0.6 : 0.25),
                              fontSize: 10,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single expanding ring used for the pulse animation
class _PulseRing extends StatelessWidget {
  final double scale;
  final double opacity;
  final Color color;
  final double size;

  const _PulseRing({
    required this.scale,
    required this.opacity,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}
