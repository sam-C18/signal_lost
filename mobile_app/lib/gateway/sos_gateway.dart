import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sos_message.dart';

/// Manages internet gateway functionality for SOS messages.
/// Detects internet connectivity and POSTs SOS to backend.
class SosGateway {
  static final SosGateway _instance = SosGateway._internal();

  factory SosGateway() {
    return _instance;
  }

  SosGateway._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  Future<bool> isInternetAvailable() async {
    try {
      final result = await _connectivity.checkConnectivity();
      final hasConnection = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
      return hasConnection;
    } catch (e) {
      print('[SosGateway] Internet check failed: $e');
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Post SOS message to backend with exponential backoff retry
  Future<bool> postSosToBackend(
    SosMessage message,
    String backendUrl, {
    int maxRetries = 3,
  }) async {
    print('[SosGateway] Posting SOS ${message.messageId} to $backendUrl');

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await http
            .post(
          Uri.parse(backendUrl),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'SignalLost/1.0',
          },
          body: jsonEncode(message.toJson()),
        )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('[SosGateway] POST successful: ${message.messageId}');
          return true;
        } else {
          print(
              '[SosGateway] POST failed with status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        final waitTime = _exponentialBackoff(attempt);
        print(
            '[SosGateway] POST attempt $attempt failed: $e. Retrying in ${waitTime}ms...');

        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: waitTime));
        }
      }
    }

    print('[SosGateway] All POST attempts failed for ${message.messageId}');
    return false;
  }

  /// Calculate exponential backoff time in milliseconds
  int _exponentialBackoff(int attempt) {
    // 1sec, 2sec, 4sec
    return (1000 * (1 << attempt)).clamp(1000, 8000);
  }

  /// Show alert modal for received SOS (would be called from UI layer)
  /// This returns the alert details - actual UI display is handled in the screen
  Map<String, dynamic> getAlertDetails(SosMessage message) {
    return {
      'title': 'SOS RECEIVED',
      'messageId': message.messageId,
      'location': message.formattedCoordinates,
      'accuracy': message.formattedAccuracy,
      'relayedVia': message.relayCount,
      'timestamp': message.timestamp.toString(),
      'action': 'SEND TO BACKEND',
    };
  }
}
