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
  });

  bool get isDoctor => role == UserRole.doctor;

  /// "P-012" for patients, "M-004" for doctors (médecins).
  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    return '${isDoctor ? 'M' : 'P'}-${digits.padLeft(3, '0')}';
  }

  Registration copyWith({ReviewStatus? status, bool? phoneVerified}) =>
      Registration(
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
      );
}
