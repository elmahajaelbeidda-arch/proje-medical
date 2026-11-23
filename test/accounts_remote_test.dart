import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/accounts_remote.dart';
import 'package:shifa/models/models.dart';
import 'package:shifa/models/registration.dart';

void main() {
  test('a server account becomes a registration with its code', () {
    final p = RemoteProfile.fromJson({
      'user_id': '6b1c2d3e-0000-4000-8000-000000000001',
      'role': 'doctor',
      'code': 'M-007',
      'name': 'د. مريم',
      'phone': '22123456',
      'national_id': '1234567890',
      'specialty_id': 'pediatrics',
      'license_number': 'ONMM-1',
      'certificate_path': '6b1c/certificate.pdf',
      'status': 'pending',
      'created_at': '2026-11-23T10:00:00Z',
    });
    final r = p.toRegistration();
    expect(r.code, 'M-007');
    expect(r.isDoctor, isTrue);
    expect(r.status, ReviewStatus.pending);
    expect(r.idNumber, '1234567890');
    expect(r.certificate!.kind, AttachmentKind.pdf);
    expect(r.copyWith(status: ReviewStatus.approved).code, 'M-007');
  });

  test('the hidden sign-in address comes from the phone number', () {
    final a = AccountsRemote.loginAddress(UserRole.patient, '+222 22 12 34 56');
    expect(a, startsWith('p22123456.'));
    expect(a, endsWith('@users.chifa-linnas.app'));
  });
}
