/// One sign-in for everybody: the person types a phone number, an account
/// code (P-013, M-023, H-001) or a national ID number (NNI), and the app
/// finds the account and opens the space that concerns it.
///
/// Demo stage: accounts come from the app's own data. Once the server is
/// linked (Supabase), the same lookup is made on the server with the
/// password.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/facility.dart';
import '../models/models.dart';
import '../models/registration.dart';
import 'facility_provider.dart';
import 'providers.dart';

enum AccountKind { patient, doctor, facility }

class FoundAccount {
  final AccountKind kind;
  final String name;
  final String phone;
  final String idNumber;
  final String? registrationId;
  final String? specialtyId;
  final String? facilityId;
  const FoundAccount({
    required this.kind,
    required this.name,
    this.phone = '',
    this.idNumber = '',
    this.registrationId,
    this.specialtyId,
    this.facilityId,
  });
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

bool _samePhone(String a, String b) {
  final x = _digits(a), y = _digits(b);
  if (x.isEmpty || y.isEmpty) return false;
  return x == y || '222$x' == y || x == '222$y';
}

/// The account behind [input], or null when none matches.
FoundAccount? findAccount(
  List<Registration> registrations,
  List<MedicalFacility> facilities,
  String input,
) {
  final raw = input.trim();
  if (raw.isEmpty) return null;
  final upper = raw.toUpperCase().replaceAll(' ', '');
  final digits = _digits(raw);
  for (final r in registrations) {
    if (r.status == ReviewStatus.rejected) continue;
    final match =
        r.code == upper ||
        _samePhone(r.phone, raw) ||
        (digits.length == 10 && r.idNumber == digits);
    if (match) {
      return FoundAccount(
        kind: r.isDoctor ? AccountKind.doctor : AccountKind.patient,
        name: r.name,
        phone: r.phone,
        idNumber: r.idNumber,
        registrationId: r.id,
        specialtyId: r.specialtyId,
      );
    }
  }
  for (final f in facilities) {
    if (f.status == FacilityStatus.rejected) continue;
    final match =
        f.code == upper ||
        f.licenseNumber.toUpperCase() == upper ||
        _samePhone(f.phone, raw);
    if (match) {
      return FoundAccount(
        kind: AccountKind.facility,
        name: f.name,
        phone: f.phone,
        facilityId: f.id,
      );
    }
  }
  return null;
}

FoundAccount? lookupAccount(Ref ref, String input) => findAccount(
  ref.read(registrationsProvider),
  ref.read(facilityProvider).facilities,
  input,
);

/// Demo accounts shown under the sign-in form (any password works until
/// the server is linked).
const demoLoginCodes = [
  ('role_patient', 'P-013'),
  ('role_doctor', 'M-023'),
  ('psych_doctor_short', 'M-024'),
  ('role_facility', 'H-001'),
];

/// Kept for callers that only need the role.
UserRole roleOf(FoundAccount a) =>
    a.kind == AccountKind.doctor ? UserRole.doctor : UserRole.patient;
