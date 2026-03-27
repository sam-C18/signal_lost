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
  final String? deviceId; // Device that originated the SOS (brand + model)

  SosMessage({
    required this.messageId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
    required this.relayCount,
    required this.isActive,
    this.deviceId,
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
    String? deviceId,
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
      deviceId: deviceId ?? this.deviceId,
    );
  }

  // Convert to JSON for network transmission
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'relayCount': relayCount,
      'isActive': isActive,
      'deviceId': deviceId,
    };
  }

  // Create from JSON received from network
  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      messageId: json['messageId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      relayCount: json['relayCount'] as int,
      isActive: json['isActive'] as bool,
      deviceId: json['deviceId'] as String?,
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