import 'models.dart';

/// Committee decision on a new account (patient or doctor).
enum ReviewStatus { pending, approved, rejected }

/// Sign-up of a patient (beneficiary) or volunteer doctor, reviewed by the
/// committee before the account is fully active.
class Registration {
  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final String idNumber;
  final Attachment? idFront;
  final Attachment? idBack;

  /// Doctors only.
  final String? specialtyId;
  final String? licenseNumber;
  final Attachment? certificate;

  final bool phoneVerified;
  final DateTime createdAt;
  final ReviewStatus status;

  /// When the committee approved or rejected the account.
  final DateTime? reviewedAt;

  const Registration({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    required this.idNumber,
    required this.createdAt,
    this.idFront,
    this.idBack,
    this.specialtyId,
    this.licenseNumber,
    this.certificate,
    this.phoneVerified = false,
    this.status = ReviewStatus.pending,
    this.reviewedAt,
  });

  bool get isDoctor => role == UserRole.doctor;

  /// "P-012" for patients, "M-004" for doctors (médecins).
  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    return '${isDoctor ? 'M' : 'P'}-${digits.padLeft(3, '0')}';
  }

  Registration copyWith({
    ReviewStatus? status,
    bool? phoneVerified,
    DateTime? reviewedAt,
  }) => Registration(
    id: id,
    role: role,
    name: name,
    phone: phone,
    idNumber: idNumber,
    createdAt: createdAt,
    idFront: idFront,
    idBack: idBack,
    specialtyId: specialtyId,
    licenseNumber: licenseNumber,
    certificate: certificate,
    phoneVerified: phoneVerified ?? this.phoneVerified,
    status: status ?? this.status,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
}

/// Same ID card number, phone or licence already registered.
class DuplicateRegistrationException implements Exception {
  /// 'id', 'phone' or 'license'.
  final String field;
  const DuplicateRegistrationException(this.field);
  @override
  String toString() => 'DuplicateRegistrationException($field)';
}

String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Last 8 digits: "+222 22 12 34 56" and "22123456" are the same number.
String normalizePhone(String s) {
  final d = digitsOnly(s);
  return d.length > 8 ? d.substring(d.length - 8) : d;
}

/// Other registrations sharing the ID number or phone (committee warning).
List<Registration> possibleDuplicates(
  Registration r,
  Iterable<Registration> all,
) => [
  for (final o in all)
    if (o.id != r.id &&
        ((digitsOnly(o.idNumber).isNotEmpty &&
                digitsOnly(o.idNumber) == digitsOnly(r.idNumber)) ||
            (normalizePhone(o.phone).isNotEmpty &&
                normalizePhone(o.phone) == normalizePhone(r.phone))))
      o,
];
