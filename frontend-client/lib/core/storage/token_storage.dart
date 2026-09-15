import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the Sanctum bearer token lives.
///
/// The Keychain on iOS and the Keystore-backed store on Android — not SharedPreferences, which
/// is a plain-text XML file any rooted device can read. A token is a credential: whoever holds
/// it *is* the user until it is revoked.
///
/// Cached in memory after the first read, because the Dio interceptor needs it on every single
/// request and a Keychain round-trip per call is a measurable cost on older Androids.
class TokenStorage {
  TokenStorage(this._storage);

  static const String _key = 'auth_token';

  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;

    _cached = await _storage.read(key: _key);
    _loaded = true;

    return _cached;
  }

  /// Set eagerly so the very next request is authenticated without waiting on a re-read.
  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }

  /// Cheap, synchronous, and only meaningful after [read] — routing guards use it to decide
  /// where to send someone without awaiting.
  bool get hasTokenInMemory => _cached != null && _cached!.isNotEmpty;
}
