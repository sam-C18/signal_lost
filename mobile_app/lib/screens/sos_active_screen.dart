import 'package:flutter/material.dart';
import '../models/sos_message.dart';
import '../services/sos_service.dart';
import '../widgets/app_theme.dart';

/// Screen shown after SOS is activated.
/// Displays live message ID, GPS coordinates, and relay status.
class SosActiveScreen extends StatefulWidget {
  final SosMessage? message;

  const SosActiveScreen({
    super.key,
    this.message,
  });

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<SosActiveScreen>
    with TickerProviderStateMixin {
  final _sosService = SosService();
  late SosMessage _message;
  late AnimationController _ringController;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _flashAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    // Initialize SOS message and broadcasting
    if (widget.message != null) {
      // Message passed from confirmation screen
      _initializeWithMessage(widget.message!);
    } else {
      // Fallback: create new message (for backward compatibility)
      _initializeSosMessage();
    }
  }

  /// Initialize with message from confirmation screen and start broadcasting
  Future<void> _initializeWithMessage(SosMessage message) async {
    try {
      _message = message;

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Broadcast SOS via mesh networking
      await _sosService.broadcastSos(message);

      // Listen for incoming relay messages from other devices
      if (!mounted) return;
      _subscribeToRelayMessages();

      // Optional: keep relay simulation for UI feedback animation
      _sosService.startRelaySimulation(_message, (updated) {
        if (mounted) setState(() => _message = updated);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  /// Subscribe to incoming relay messages from other devices
  void _subscribeToRelayMessages() {
    // Listen to WiFi Direct messages
    _sosService.wifiDirectManager.incomingMessages.listen(
      (incomingMessage) {
        print('[SosActiveScreen] Received relay: ${incomingMessage.messageId}');
        // Relay the message (will check dedup cache)
        _sosService.broadcastSosRelay(incomingMessage, (relayedMessage) {
          if (relayedMessage != null && mounted) {
            setState(() => _message = relayedMessage);
          }
        });
      },
      onError: (err) {
        print('[SosActiveScreen] WiFi Direct listen error: $err');
      },
    );

    // Listen to BLE messages
    _sosService.bleManager.incomingMessages.listen(
      (incomingMessage) {
        print('[SosActiveScreen] Received BLE relay: ${incomingMessage.messageId}');
        // Relay the message (will check dedup cache)
        _sosService.broadcastSosRelay(incomingMessage, (relayedMessage) {
          if (relayedMessage != null && mounted) {
            setState(() => _message = relayedMessage);
          }
        });
      },
      onError: (err) {
        print('[SosActiveScreen] BLE listen error: $err');
      },
    );
  }

  /// Create the SOS message with real GPS coordinates
  Future<void> _initializeSosMessage() async {
    try {
      _message = await _sosService.createSosMessage();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Start simulating relay growth
      _sosService.startRelaySimulation(_message, (updated) {
        if (mounted) setState(() => _message = updated);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    _flashController.dispose();
    _sosService.dispose();
    super.dispose();
  }

  void _cancelSos() {
    _sosService.cancelSos();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  // ── Header with flashing SOS SENT ────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Column(
        children: [
          FadeTransition(
            opacity: _flashAnimation,
            child: const Text(
              '⚠ SOS SENT',
              style: TextStyle(
                color: AppTheme.sosRed,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'EMERGENCY BROADCAST ACTIVE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Main body with pulse animation and data cards ─────────────────────────
  Widget _buildBody() {
    // Show error if GPS acquisition failed
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.warningOrange.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppTheme.warningOrange.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.location_disabled_rounded,
                  color: AppTheme.warningOrange,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'GPS UNAVAILABLE',
                style: TextStyle(
                  color: AppTheme.sosRed,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.sosRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'GO BACK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading indicator while GPS data is being fetched
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _ringController,
                    builder: (context, _) {
                      return Container(
                        width: 60 * (_ringController.value * 0.8 + 0.4),
                        height: 60 * (_ringController.value * 0.8 + 0.4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.sosRed.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppTheme.sosRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ACQUIRING GPS...',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildPulseIndicator(),
          const SizedBox(height: 36),
          _buildInfoCard(
            icon: Icons.tag_rounded,
            label: 'MESSAGE ID',
            value: _message.messageId,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.gps_fixed_rounded,
            label: 'COORDINATES',
            value: _message.formattedCoordinates,
            subValue: _message.formattedAccuracy,
          ),
          const SizedBox(height: 12),
          _buildRelayCard(),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.schedule_rounded,
            label: 'SENT AT',
            value: _formatTime(_message.timestamp),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Pulsing radar-like animation ──────────────────────────────────────────
  Widget _buildPulseIndicator() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Three expanding rings at different phases
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ringController,
              builder: (context, _) {
                final phase = (_ringController.value + i / 3) % 1.0;
                return Transform.scale(
                  scale: 0.4 + phase * 0.6,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.sosRed.withValues(alpha: (1 - phase) * 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Center dot
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.sosRed.withValues(alpha: 0.15),
              border: Border.all(color: AppTheme.sosRed, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.sosRed.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.cell_tower_rounded,
              color: AppTheme.sosRed,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic info card ─────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.sosRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.sosRed, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subValue,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Relay card with live loading indicator ────────────────────────────────
  Widget _buildRelayCard() {
    final hasRelays = _message.relayCount > 0;
    final color = hasRelays ? AppTheme.successGreen : AppTheme.warningOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasRelays ? Icons.hub_rounded : Icons.search_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RELAY STATUS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _message.relayStatus,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Loading spinner while waiting for first relay
          if (!hasRelays)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: AppTheme.warningOrange,
                strokeWidth: 1.5,
              ),
            ),
          if (hasRelays)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '×${_message.relayCount}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Cancel SOS button ─────────────────────────────────────────────────────
  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: _cancelSos,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text(
            'CANCEL SOS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s — ${dt.day}/${dt.month}/${dt.year}';
  }
}
