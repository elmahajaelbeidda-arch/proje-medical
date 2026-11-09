import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/models/models.dart';
import 'package:shifa/models/registration.dart';

void main() {
  test('new doctor account waits for the committee before being approved', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final auth = c.read(authProvider.notifier);
    final regs = c.read(registrationsProvider.notifier);

    auth.selectRole(UserRole.doctor);
    final id = regs.add(
      role: UserRole.doctor,
      name: 'د. Nadia',
      phone: '0550 11 22 33',
      idNumber: '109870512304821',
      specialtyId: 'cardio',
      licenseNumber: 'CNOM-16-1',
    );
    auth.register(
      name: 'د. Nadia',
      phone: '0550 11 22 33',
      idNumber: '109870512304821',
      registrationId: id,
    );
    regs.markPhoneVerified(id);
    auth.verifyPhone();

    final reg = regs.byId(id)!;
    expect(reg.code, startsWith('M-'));
    expect(reg.phoneVerified, isTrue);
    expect(c.read(myAccountStatusProvider), ReviewStatus.pending);

    regs.review(id, ReviewStatus.approved);
    expect(c.read(myAccountStatusProvider), ReviewStatus.approved);

    regs.review(id, ReviewStatus.rejected);
    expect(c.read(myAccountStatusProvider), ReviewStatus.rejected);
  });

  test('demo accounts without a registration are treated as approved', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(authProvider.notifier).login();
    expect(c.read(myAccountStatusProvider), ReviewStatus.approved);
    // Demo data includes pending patient and doctor accounts to review.
    final pending = c
        .read(registrationsProvider)
        .where((r) => r.status == ReviewStatus.pending);
    expect(pending.any((r) => r.role == UserRole.patient), isTrue);
    expect(pending.any((r) => r.role == UserRole.doctor), isTrue);
  });
}
