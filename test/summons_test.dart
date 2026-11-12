import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/core/summons_provider.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/models/summons.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  SummonsNotifier n() => c.read(summonsProvider.notifier);

  String issue(String source, DateTime at, {String place = 'عيادة'}) =>
      n().issue(
        patientId: MockData.currentPatientId,
        patientName: 'محمد الأمين',
        issuer: SummonsIssuer.doctor,
        issuerId: 'd1',
        issuerName: 'د. سارة',
        issuerDetailKey: 'sp_internal',
        issuerPhone: '22 12 34 56',
        place: place,
        city: 'نواكشوط',
        appointment: at,
        sourceId: source,
      );

  test('demo patient has a card to try', () {
    expect(n().forPatient(MockData.currentPatientId), isNotEmpty);
  });

  test('a new appointment replaces the card of the same case', () {
    final before = c.read(summonsProvider).length;
    issue('c9', DateTime(2026, 12, 1, 9));
    final id = issue('c9', DateTime(2026, 12, 2, 10));
    expect(c.read(summonsProvider), hasLength(before + 1));
    expect(n().bySource('c9')!.id, id);
    expect(n().bySource('c9')!.appointment, DateTime(2026, 12, 2, 10));
  });

  test('place is required and codes are stable', () {
    expect(
      () => issue('c10', DateTime(2026, 12, 1), place: ' '),
      throwsArgumentError,
    );
    final s = n().byId(issue('c11', DateTime(2026, 12, 1, 9)))!;
    expect(s.code, startsWith('CV-'));
    expect(s.verificationCode, hasLength(6));
    expect(s.verificationCode, s.verificationCode);
    expect(s.qrPayload, contains(s.code));
  });

  test('upcoming vs past visits', () {
    final now = DateTime(2026, 11, 12, 12);
    final s = n().byId(issue('c12', DateTime(2026, 11, 12, 9)))!;
    expect(s.isUpcoming(now), isTrue); // same day, still shown
    expect(s.isUpcoming(DateTime(2026, 11, 13, 12)), isFalse);
  });

  test('demo patient has a referral a facility can accept', () {
    final r = c
        .read(facilityProvider)
        .referrals
        .where((r) => r.patientId == MockData.currentPatientId);
    expect(r, isNotEmpty);
  });
}
