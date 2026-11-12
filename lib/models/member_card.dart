/// «بطاقة التسجيل والاعتماد»: proves that a patient, volunteer doctor or
/// medical facility is registered and approved by the association. Its QR
/// code opens the verification page.
library;

enum MemberKind { patient, doctor, facility }

enum CardCheck { valid, suspended, expired, unknown, wrongCode }

class MemberCard {
  /// e.g. "SL-P-2026-0013".
  final String number;
  final MemberKind kind;

  /// Registration id (patients, doctors) or facility id.
  final String holderId;
  final String name;

  /// ID card number (people) or licence number (facilities).
  final String idValue;

  /// Translation key: specialty, facility type or 'role_patient'.
  final String detailKey;
  final String city;
  final DateTime issuedAt;
  final bool suspended;

  /// Last renewal by the association (valid one year from it).
  final DateTime? renewedAt;

  const MemberCard({
    required this.number,
    required this.kind,
    required this.holderId,
    required this.name,
    required this.idValue,
    required this.detailKey,
    required this.city,
    required this.issuedAt,
    this.suspended = false,
    this.renewedAt,
  });

  /// Valid one year, renewed by the association.
  DateTime get expiresAt {
    final from = renewedAt ?? issuedAt;
    return DateTime(from.year + 1, from.month, from.day);
  }

  bool isExpired([DateTime? now]) => (now ?? DateTime.now()).isAfter(expiresAt);

  /// "•••• 5123" for ID cards; licences are shown in full.
  String get maskedIdValue => kind == MemberKind.facility || idValue.length <= 4
      ? idValue
      : '•••• ${idValue.substring(idValue.length - 4)}';

  /// Short code checked together with the number (a forged number without
  /// the right code is rejected).
  String get verificationCode {
    var h = 11;
    for (final c
        in '$number|$holderId|$name|${issuedAt.toIso8601String()}'.codeUnits) {
      h = (h * 37 + c) & 0x7fffffff;
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return [
      for (var i = 0; i < 6; i++) alphabet[(h >> (i * 5)) % alphabet.length],
    ].join();
  }

  MemberCard copyWith({bool? suspended}) => MemberCard(
    number: number,
    kind: kind,
    holderId: holderId,
    name: name,
    idValue: idValue,
    detailKey: detailKey,
    city: city,
    issuedAt: issuedAt,
    suspended: suspended ?? this.suspended,
    renewedAt: renewedAt,
  );
}

String memberNumber(MemberKind kind, String holderId, DateTime issuedAt) {
  var digits = holderId.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) digits = '0';
  if (digits.length > 4) digits = digits.substring(digits.length - 4);
  const prefix = {
    MemberKind.patient: 'P',
    MemberKind.doctor: 'D',
    MemberKind.facility: 'F',
  };
  return 'SL-${prefix[kind]}-${issuedAt.year}-${digits.padLeft(4, '0')}';
}

/// Checks a card number and code (from the QR code or typed by hand).
(CardCheck, MemberCard?) checkCard(
  Iterable<MemberCard> cards,
  String number,
  String code, {
  DateTime? now,
}) {
  final n = number.trim().toUpperCase();
  MemberCard? card;
  for (final c in cards) {
    if (c.number == n) card = c;
  }
  if (card == null) return (CardCheck.unknown, null);
  if (card.verificationCode != code.trim().toUpperCase()) {
    return (CardCheck.wrongCode, null);
  }
  if (card.suspended) return (CardCheck.suspended, card);
  if (card.isExpired(now)) return (CardCheck.expired, card);
  return (CardCheck.valid, card);
}

/// Reads "SL-P-2026-0013" and the code from a scanned QR text or link
/// (…/verify-card?n=SL-P-2026-0013&c=ABC123) or "SL-P-2026-0013 ABC123".
(String, String)? parseCardInput(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text);
  final fragment = uri?.fragment ?? '';
  final query = fragment.contains('?')
      ? Uri.splitQueryString(fragment.substring(fragment.indexOf('?') + 1))
      : uri?.queryParameters ?? const {};
  if (query['n'] != null && query['c'] != null) {
    return (query['n']!.toUpperCase(), query['c']!.toUpperCase());
  }
  final m = RegExp(
    r'(SL-[PDF]-\d{4}-\d{4})\W+([A-Z0-9]{6})',
    caseSensitive: false,
  ).firstMatch(text);
  if (m == null) return null;
  return (m.group(1)!.toUpperCase(), m.group(2)!.toUpperCase());
}
