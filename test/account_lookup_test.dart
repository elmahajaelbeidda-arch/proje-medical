import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/account_lookup.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final regs = MockData.registrations();
  final facilities = ProviderContainer().read(facilityProvider).facilities;

  FoundAccount? find(String s) => findAccount(regs, facilities, s);

  test('one sign-in finds the account by code, phone or NNI', () {
    final p = find('p-013')!;
    expect(p.kind, AccountKind.patient);
    expect(p.name, 'محمد الأمين');
    expect(find('22 12 34 56')!.registrationId, 'reg13');
    expect(find('+222 22123456')!.registrationId, 'reg13');
    expect(find('1098705123')!.registrationId, 'reg13');

    final d = find('M-023')!;
    expect(d.kind, AccountKind.doctor);
    expect(d.specialtyId, 'internal');
    expect(find('M-024')!.specialtyId, 'psych');

    final f = find('H-001')!;
    expect(f.kind, AccountKind.facility);
    expect(f.facilityId, isNotNull);

    expect(find('P-999'), isNull);
    expect(find(''), isNull);
  });
}
