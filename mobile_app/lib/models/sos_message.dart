// Model representing an active SOS message broadcast
class SosMessage {
  final String messageId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;
  final int relayCount;
  final bool isActive;

  SosMessage({
    required this.messageId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.relayCount,
    required this.isActive,
  });

  SosMessage copyWith({
    String? messageId,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    int? relayCount,
    bool? isActive,
  }) {
    return SosMessage(
      messageId: messageId ?? this.messageId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      relayCount: relayCount ?? this.relayCount,
      isActive: isActive ?? this.isActive,
    );
  }

  // Format coordinates for display
  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}, ${altitude.toStringAsFixed(2)}';

  // Format accuracy for display (rounds to 1 decimal place)
  String get formattedAccuracy => 'Accuracy: ~${accuracy.toStringAsFixed(1)}m';

  // Relay status message
  String get relayStatus => relayCount == 0
      ? 'Searching for relay devices...'
      : 'Relayed via $relayCount device${relayCount > 1 ? 's' : ''}';
}