import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/blood_provider.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/models/admin.dart';
import 'package:shifa/models/blood.dart';

void main() {
  late ProviderContainer c;
  setUp(
    () => c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    ),
  );
  tearDown(() => c.dispose());
  BloodNotifier n() => c.read(bloodProvider.notifier);
  BloodState s() => c.read(bloodProvider);

  void becomeDonor(String type, {bool approve = true}) {
    n().saveMyDonor(
      name: 'متبرع',
      bloodType: type,
      city: 'نواكشوط',
      phone: '22 33 44 55',
      shareContact: true,
      kind: DonorKind.other,
    );
    if (approve) n().reviewDonor(s().myDonorId!, DonorStatus.approved);
  }

  test(
    'only reviewed, open requests still missing blood are public, urgent first',
    () {
      final needs = s().publicNeeds;
      expect(needs, isNotEmpty);
      for (final r in needs) {
        expect(r.isOpen, isTrue);
        expect(r.status, isNot(BloodRequestStatus.submitted));
        expect(unitsStillNeeded(r), greaterThan(0));
      }
      expect(needs.first.urgent, isTrue);
      // br4 is fulfilled; br3 needs 1 unit and already has 1 linked donor.
      expect(needs.map((r) => r.id), isNot(contains('br4')));
      expect(needs.map((r) => r.id), isNot(contains('br3')));
    },
  );

  test('a visitor without a donor profile cannot answer', () {
    expect(() => n().volunteer('br1'), throwsStateError);
  });

  test('a donor waiting for approval cannot answer yet', () {
    becomeDonor('O-', approve: false);
    expect(() => n().volunteer('br1'), throwsStateError);
  });

  test('an approved compatible donor answers once; the team sees it first', () {
    becomeDonor('O-');
    n().volunteer('br1');
    n().volunteer('br1');
    final r = s().request('br1')!;
    expect(r.volunteerIds.where((id) => id == s().myDonorId), hasLength(1));
    final ranked = matchDonors(r, s().donors);
    expect(ranked.first.id, s().myDonorId);

    n().withdrawVolunteer('br1');
    expect(s().request('br1')!.volunteerIds, isNot(contains(s().myDonorId)));
  });

  test('an incompatible blood type is refused', () {
    becomeDonor('AB+');
    expect(
      () => n().volunteer('br1'),
      throwsArgumentError,
      reason: 'br1 needs O+',
    );
  });

  test('donation places: listed, and managed only by the blood team', () {
    expect(s().activePlaces, isNotEmpty);
    expect(
      () => n().addPlace(name: 'بنك دم', city: 'أطار'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(
      c.read(adminProvider.notifier).login('finance@shifa.mr', 'Finance@2026'),
      LoginResult.success,
    );
    expect(
      () => n().addPlace(name: 'بنك دم', city: 'أطار'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    c.read(adminProvider.notifier).logout();
    expect(
      c.read(adminProvider.notifier).login('medical@shifa.mr', 'Medical@2026'),
      LoginResult.success,
    );
    final before = s().places.length;
    n().addPlace(name: 'بنك الدم الجهوي', city: 'أطار', hours: '8:00 – 14:00');
    expect(s().places.length, before + 1);
    final id = s().places.last.id;
    n().setPlaceActive(id, false);
    expect(s().activePlaces.any((p) => p.id == id), isFalse);
    n().deletePlace(id);
    expect(s().places.length, before);
    final actions = c.read(adminProvider).audit.map((a) => a.action);
    expect(
      actions,
      containsAll(['au_place_added', 'au_place_hidden', 'au_place_deleted']),
    );
  });
}
