/// «جهة طبية»: hospitals, clinics, labs, pharmacies and radiology centres
/// that cooperate with the association and receive referred patients.
library;

import 'models.dart';
import 'registration.dart';

enum FacilityType { hospital, clinic, lab, pharmacy, radiology }

/// What the facility offers to the association (one or more).
enum CooperationType { free, discounted, referrals }

enum ReferralStatus { sent, accepted, inProgress, completed, declined }

class MedicalFacility {
  final String id;
  final FacilityType type;
  final String name;
  final String managerName;
  final String licenseNumber;
  final String city;
  final String address;
  final String phone;
  final String email;
  final List<String> specialtyIds;
  final List<String> services;
  final Set<CooperationType> cooperation;

  /// Discount offered when [cooperation] contains `discounted`.
  final int? discountPercent;

  /// Referred patients the facility can receive per month.
  final int? monthlyCapacity;
  final String notes;
  final Attachment? licenseDocument;
  final ReviewStatus status;
  final DateTime createdAt;

  const MedicalFacility({
    required this.id,
    required this.type,
    required this.name,
    required this.managerName,
    required this.licenseNumber,
    required this.city,
    required this.address,
    required this.phone,
    required this.createdAt,
    this.email = '',
    this.specialtyIds = const [],
    this.services = const [],
    this.cooperation = const {},
    this.discountPercent,
    this.monthlyCapacity,
    this.notes = '',
    this.licenseDocument,
    this.status = ReviewStatus.pending,
  });

  bool get isApproved => status == ReviewStatus.approved;
  bool get acceptsReferrals => cooperation.contains(CooperationType.referrals);

  /// "H-001", "C-002", "L-003", "P-004", "R-005".
  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    const prefix = {
      FacilityType.hospital: 'H',
      FacilityType.clinic: 'C',
      FacilityType.lab: 'L',
      FacilityType.pharmacy: 'P',
      FacilityType.radiology: 'R',
    };
    return '${prefix[type]}-${digits.padLeft(3, '0')}';
  }

  MedicalFacility copyWith({ReviewStatus? status}) => MedicalFacility(
    id: id,
    type: type,
    name: name,
    managerName: managerName,
    licenseNumber: licenseNumber,
    city: city,
    address: address,
    phone: phone,
    createdAt: createdAt,
    email: email,
    specialtyIds: specialtyIds,
    services: services,
    cooperation: cooperation,
    discountPercent: discountPercent,
    monthlyCapacity: monthlyCapacity,
    notes: notes,
    licenseDocument: licenseDocument,
    status: status ?? this.status,
  );
}

/// A patient sent by the association to a medical facility.
class Referral {
  final String id;
  final String facilityId;
  final String patientName;

  /// Reference of the patient at the association (no ID card number).
  final String patientRef;
  final String service;
  final String notes;
  final bool urgent;
  final ReferralStatus status;

  /// Short note written by the facility (result, appointment...).
  final String facilityNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Referral({
    required this.id,
    required this.facilityId,
    required this.patientName,
    required this.patientRef,
    required this.service,
    required this.createdAt,
    DateTime? updatedAt,
    this.notes = '',
    this.urgent = false,
    this.status = ReferralStatus.sent,
    this.facilityNote = '',
  }) : updatedAt = updatedAt ?? createdAt;

  bool get isOpen =>
      status != ReferralStatus.completed && status != ReferralStatus.declined;

  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    return 'REF-${digits.padLeft(3, '0')}';
  }

  Referral copyWith({ReferralStatus? status, String? facilityNote}) => Referral(
    id: id,
    facilityId: facilityId,
    patientName: patientName,
    patientRef: patientRef,
    service: service,
    notes: notes,
    urgent: urgent,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    status: status ?? this.status,
    facilityNote: facilityNote ?? this.facilityNote,
  );
}

/// Allowed next steps of a referral, from the facility side.
List<ReferralStatus> nextReferralSteps(ReferralStatus s) => switch (s) {
  ReferralStatus.sent => [ReferralStatus.accepted, ReferralStatus.declined],
  ReferralStatus.accepted => [
    ReferralStatus.inProgress,
    ReferralStatus.completed,
  ],
  ReferralStatus.inProgress => [ReferralStatus.completed],
  _ => const [],
};
