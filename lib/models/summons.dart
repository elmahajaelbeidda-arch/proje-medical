/// «بطاقة استدعاء طبية»: issued when a volunteer doctor sets an in-person
/// visit for an accepted case, or when a medical facility accepts a referred
/// patient. The patient downloads or prints it and shows it at the visit.
library;

enum SummonsIssuer { doctor, facility }

class Summons {
  final String id;
  final String patientId;
  final String patientName;

  /// File number at the association (e.g. P-011), when known.
  final String patientRef;
  final SummonsIssuer issuer;

  /// Doctor id or facility id.
  final String issuerId;
  final String issuerName;

  /// Translation key of the specialty or facility type (e.g. sp_cardio).
  final String issuerDetailKey;
  final String issuerPhone;
  final String place;
  final String city;
  final DateTime appointment;
  final String instructions;

  /// Consultation or referral that led to the visit.
  final String sourceId;
  final DateTime issuedAt;

  const Summons({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.issuer,
    required this.issuerId,
    required this.issuerName,
    required this.issuerDetailKey,
    required this.issuerPhone,
    required this.place,
    required this.city,
    required this.appointment,
    required this.sourceId,
    required this.issuedAt,
    this.patientRef = '',
    this.instructions = '',
  });

  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    return 'CV-${digits.padLeft(4, '0')}';
  }

  /// Short code the reception can check with the association.
  String get verificationCode {
    var h = 7;
    for (final c
        in '$id|$patientName|${appointment.toIso8601String()}'.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return [
      for (var i = 0; i < 6; i++) alphabet[(h >> (i * 5)) % alphabet.length],
    ].join();
  }

  /// Content of the QR code printed on the card.
  String get qrPayload =>
      'SHIFA-LINNAS|$code|$verificationCode|${appointment.toIso8601String()}';

  bool isUpcoming([DateTime? now]) => appointment.isAfter(
    (now ?? DateTime.now()).subtract(const Duration(hours: 6)),
  );
}
