import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/models/facility.dart';
import 'package:shifa/models/registration.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  FacilityNotifier n() => c.read(facilityProvider.notifier);

  String register() => n().register(
    type: FacilityType.lab,
    name: ' مختبر تجريبي ',
    managerName: 'أحمد',
    licenseNumber: 'LAB-1',
    city: 'نواكشوط',
    address: 'تفرغ زينة',
    phone: '22 33 44 55',
    services: const ['تحليل', ' '],
    cooperation: const {CooperationType.free},
    discountPercent: 40,
    monthlyCapacity: 9,
  );

  test('new facility is pending, trimmed, and ignores unused fields', () {
    final id = register();
    final f = c.read(facilityProvider).facility(id)!;
    expect(f.status, ReviewStatus.pending);
    expect(f.name, 'مختبر تجريبي');
    expect(f.services, ['تحليل']);
    expect(f.discountPercent, isNull);
    expect(f.monthlyCapacity, isNull);
    expect(f.code, startsWith('L-'));
  });

  test('referrals only go to approved facilities', () {
    final id = register();
    expect(
      () => n().refer(
        facilityId: id,
        patientName: 'x',
        patientRef: 'P-1',
        service: 's',
      ),
      throwsStateError,
    );
    n().review(id, ReviewStatus.approved);
    final rid = n().refer(
      facilityId: id,
      patientName: 'مريم',
      patientRef: 'P-1',
      service: 'تحليل',
    );
    expect(c.read(facilityProvider).referralsOf(id).single.id, rid);
  });

  test('referral moves through the allowed steps only', () {
    final id = register();
    n().review(id, ReviewStatus.approved);
    final rid = n().refer(
      facilityId: id,
      patientName: 'مريم',
      patientRef: 'P-1',
      service: 'تحليل',
    );
    expect(
      () => n().updateReferral(rid, ReferralStatus.completed),
      throwsStateError,
    );
    n().updateReferral(rid, ReferralStatus.accepted);
    n().updateReferral(rid, ReferralStatus.inProgress, note: 'موعد الأحد');
    n().updateReferral(rid, ReferralStatus.completed);
    final r = c.read(facilityProvider).referrals.firstWhere((r) => r.id == rid);
    expect(r.status, ReferralStatus.completed);
    expect(r.facilityNote, 'موعد الأحد');
    expect(r.isOpen, isFalse);
  });

  test('facility account login by phone and licence', () {
    final s = c.read(facilityProvider);
    expect(findFacilityAccount(s, '45251010', 'ms-nkc-2019-114')?.id, 'f1');
    expect(
      findFacilityAccount(s, '+222 45 25 10 10', 'MS-NKC-2019-114')?.id,
      'f1',
    );
    expect(findFacilityAccount(s, '45251010', 'wrong'), isNull);
  });
}
