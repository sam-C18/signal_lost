/// Singleton repository for SOS message deduplication and relay chain tracking.
/// Prevents infinite loops in mesh networking by caching message IDs.
class SosRepository {
  static final SosRepository _instance = SosRepository._internal();

  factory SosRepository() {
    return _instance;
  }

  SosRepository._internal();

  // Cache of seen message IDs with timestamp
  final Map<String, DateTime> _messageCache = {};

  // Track relay paths: messageId -> list of device IDs that relayed it
  final Map<String, List<String>> _relayChains = {};

  // TTL for cache entries (3 hours in milliseconds)
  static const Duration _cacheTtl = Duration(hours: 3);

  /// Check if a message ID has already been seen (duplicate check)
  bool isDuplicate(String messageId) {
    _cleanExpiredEntries();
    return _messageCache.containsKey(messageId);
  }

  /// Cache a new message ID with timestamp
  void cacheMessage(String messageId, String? originDeviceId) {
    _messageCache[messageId] = DateTime.now();
    _relayChains[messageId] = originDeviceId != null ? [originDeviceId] : [];
  }

  /// Get the current relay chain length (hop count) for a message
  int getRelayChainLength(String messageId) {
    _cleanExpiredEntries();
    return _relayChains[messageId]?.length ?? 0;
  }

  /// Add a device to the relay chain (increments hop count)
  void addToRelayChain(String messageId, String deviceId) {
    _relayChains[messageId] ??= [];
    if (!_relayChains[messageId]!.contains(deviceId)) {
      _relayChains[messageId]!.add(deviceId);
    }
  }

  /// Check if message can be relayed (must be under 10-hop limit)
  bool canRelay(String messageId) {
    _cleanExpiredEntries();
    final hopCount = getRelayChainLength(messageId);
    return hopCount < 10; // Max 10 hops to prevent propagation beyond reasonable scale
  }

  /// Get the relay chain path for debugging/display
  List<String> getRelayChain(String messageId) {
    return _relayChains[messageId] ?? [];
  }

  /// Clean up expired cache entries
  void _cleanExpiredEntries() {
    final now = DateTime.now();
    _messageCache.removeWhere((messageId, timestamp) {
      return now.difference(timestamp) > _cacheTtl;
    });

    // Also clean relay chains
    _relayChains.removeWhere((messageId, _) {
      return !_messageCache.containsKey(messageId);
    });
  }

  /// Clear all cache (useful for testing or app reset)
  void clearAll() {
    _messageCache.clear();
    _relayChains.clear();
  }

  /// Get cache stats for debugging
  Map<String, dynamic> getStats() {
    _cleanExpiredEntries();
    return {
      'cachedMessages': _messageCache.length,
      'relayChains': _relayChains.length,
      'oldestEntry': _messageCache.isEmpty
          ? null
          : _messageCache.values.reduce(
              (a, b) => a.isBefore(b) ? a : b,
            ),
    };
  }
}
