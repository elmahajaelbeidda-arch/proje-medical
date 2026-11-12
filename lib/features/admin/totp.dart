import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Time-based one-time passwords (RFC 6238), compatible with Google
/// Authenticator, Microsoft Authenticator, etc.
class Totp {
  Totp._();

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// New random secret (base32, 160 bits).
  static String newSecret([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(32, (_) => _alphabet[r.nextInt(32)]).join();
  }

  static Uint8List _base32Decode(String input) {
    final s = input.toUpperCase().replaceAll(RegExp('[^A-Z2-7]'), '');
    final out = <int>[];
    var buffer = 0, bits = 0;
    for (final ch in s.split('')) {
      buffer = (buffer << 5) | _alphabet.indexOf(ch);
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xff);
      }
    }
    return Uint8List.fromList(out);
  }

  /// 6-digit code for [time] (30-second steps).
  static String code(String secret, DateTime time) {
    var counter = time.millisecondsSinceEpoch ~/ 1000 ~/ 30;
    final msg = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      msg[i] = counter & 0xff;
      counter >>= 8;
    }
    final h = Hmac(sha1, _base32Decode(secret)).convert(msg).bytes;
    final o = h.last & 0xf;
    final bin =
        ((h[o] & 0x7f) << 24) | (h[o + 1] << 16) | (h[o + 2] << 8) | h[o + 3];
    return (bin % 1000000).toString().padLeft(6, '0');
  }

  /// Accepts the current code and the previous/next one (clock drift).
  static bool verify(String secret, String input, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final c = input.replaceAll(' ', '');
    for (final d in [-30, 0, 30]) {
      if (code(secret, t.add(Duration(seconds: d))) == c) return true;
    }
    return false;
  }

  /// Link to put in a QR code for authenticator apps.
  static String uri(String secret, String account) =>
      'otpauth://totp/${Uri.encodeComponent('Shifa Linnas:$account')}'
      '?secret=$secret&issuer=${Uri.encodeComponent('Shifa Linnas')}';
}
