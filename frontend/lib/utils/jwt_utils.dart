import 'dart:convert';

/// Minimal JWT payload decoding - just enough to read `exp` for proactive
/// refresh. This does NOT verify the signature (the client has no business
/// verifying a token it didn't issue; that's the server's job every time it
/// receives the token). It only reads the claims to decide "should I bother
/// refreshing before this expires", which is a UX optimization, not a
/// security control.
class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null; // not a JWT (opaque token) - that's fine
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime? expiryOf(String token) {
    final exp = decodePayload(token)?['exp'];
    if (exp is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  }

  /// True if the token is a JWT with an `exp` claim that is already past,
  /// or within [threshold] of expiring. Always false for opaque tokens
  /// (no `exp` to read) - those fall back entirely to reactive 401 handling
  /// in the API client.
  static bool isExpiringSoon(String token, {Duration threshold = const Duration(seconds: 45)}) {
    final expiry = expiryOf(token);
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(expiry.subtract(threshold));
  }
}
