import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/features/care_map/care_map.dart';
import 'package:shifa/models/facility.dart';

void main() {
  late ProviderContainer c;
  setUp(
    () => c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    ),
  );
  tearDown(() => c.dispose());

  Set<String> ids() => {for (final p in c.read(carePlacesProvider)) p.id};

  test('only approved facilities and verified doctors are on the map', () {
    final shown = ids();
    expect(shown, containsAll(['f1', 'f2', 'f3', 'f4', 'd1', 'd9']));
    expect(shown, isNot(contains('f5'))); // under review
    expect(shown, isNot(contains('f6'))); // documents requested
  });

  test('the map follows approvals and suspensions live', () {
    final n = c.read(facilityProvider.notifier);
    for (final v in VerificationCheck.values) {
      if (!c.read(facilityProvider).facility('f5')!.checks.contains(v)) {
        n.toggleCheck('f5', v);
      }
    }
    n.review('f5', FacilityStatus.approved);
    expect(ids(), contains('f5'));

    final admin = c.read(adminProvider.notifier);
    admin.login('admin@shifa.mr', 'Admin@2026');
    admin.suspendAccount('f5', 'عيادة السلام', 'تحقق');
    expect(ids(), isNot(contains('f5')));
  });

  test('nearest places are sorted by distance', () {
    // Tevragh Zeina, Nouakchott.
    const me = LatLng(18.1000, -15.9750);
    final list = nearest(c.read(carePlacesProvider), me);
    expect(list.first.$2, lessThan(1.5));
    for (var i = 1; i < list.length; i++) {
      expect(list[i].$2, greaterThanOrEqualTo(list[i - 1].$2));
    }
    expect(list.last.$1.city, isNot('نواكشوط'));
    expect(formatKm(0.45), '450 m');
    expect(formatKm(3.21), '3.2 km');
  });
}
