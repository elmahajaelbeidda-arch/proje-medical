import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/facility_provider.dart';
import 'package:shifa/core/member_card_provider.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/models/facility.dart';
import 'package:shifa/models/member_card.dart';
import 'package:shifa/models/models.dart';
import 'package:shifa/models/registration.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  List<MemberCard> cards() => c.read(memberCardsProvider);
  MemberCard? cardOf(String holder) =>
      cards().where((x) => x.holderId == holder).firstOrNull;

  test('approved patients, doctors and facilities have cards', () {
    expect(cardOf('reg13')!.kind, MemberKind.patient);
    expect(cardOf('reg23')!.kind, MemberKind.doctor);
    expect(cardOf('f1')!.kind, MemberKind.facility);
    expect(cardOf('reg11'), isNull); // pending
    expect(cardOf('f5'), isNull); // facility under review
    final numbers = cards().map((x) => x.number).toList();
    expect(numbers.toSet(), hasLength(numbers.length));
  });

  test('approval issues the card; suspension is shown by verification', () {
    c
        .read(registrationsProvider.notifier)
        .review('reg11', ReviewStatus.approved);
    final card = cardOf('reg11')!;
    expect(card.number, startsWith('SL-P-'));
    expect(
      checkCard(cards(), card.number, card.verificationCode).$1,
      CardCheck.valid,
    );
    c.read(suspendedCardsProvider.notifier).suspend(card.number);
    expect(
      checkCard(cards(), card.number, card.verificationCode).$1,
      CardCheck.suspended,
    );
  });

  test('forged, unknown and expired cards are detected', () {
    final card = cardOf('reg13')!;
    expect(checkCard(cards(), card.number, 'AAAAAA').$1, CardCheck.wrongCode);
    expect(
      checkCard(cards(), 'SL-P-2020-9999', 'AAAAAA').$1,
      CardCheck.unknown,
    );
    expect(
      checkCard(
        cards(),
        card.number,
        card.verificationCode,
        now: card.expiresAt.add(const Duration(days: 1)),
      ).$1,
      CardCheck.expired,
    );
  });

  test('QR links and typed codes are understood', () {
    expect(
      parseCardInput(
        'https://x.github.io/proje-medical/#/verify-card?n=SL-P-2026-0013&c=ABC234',
      ),
      ('SL-P-2026-0013', 'ABC234'),
    );
    expect(parseCardInput('sl-d-2026-0023  6r4zfm'), (
      'SL-D-2026-0023',
      '6R4ZFM',
    ));
    expect(parseCardInput('hello'), isNull);
  });

  test('the same ID number or phone cannot register twice', () {
    final n = c.read(registrationsProvider.notifier);
    // Demo patient (reg13) already uses this ID number and phone.
    expect(
      () => n.add(
        role: UserRole.patient,
        name: 'x',
        phone: '33 33 33 33',
        idNumber: '1098705123',
      ),
      throwsA(isA<DuplicateRegistrationException>()),
    );
    expect(
      () => n.add(
        role: UserRole.patient,
        name: 'x',
        phone: '+222 22 12 34 56',
        idNumber: '1111111111',
      ),
      throwsA(
        isA<DuplicateRegistrationException>().having(
          (e) => e.field,
          'field',
          'phone',
        ),
      ),
    );
    // A rejected sign-up can be redone.
    n.review('reg12', ReviewStatus.rejected);
    expect(
      n.add(
        role: UserRole.patient,
        name: 'عبد القادر',
        phone: '26 11 22 33',
        idNumber: '1087654321',
      ),
      isNotEmpty,
    );
    final regs = c.read(registrationsProvider);
    final again = regs.first;
    expect(possibleDuplicates(again, regs).map((r) => r.id), contains('reg12'));
  });

  test('a facility licence cannot register twice', () {
    expect(
      () => c
          .read(facilityProvider.notifier)
          .register(
            type: FacilityType.hospital,
            name: 'نسخة',
            managerName: 'x',
            licenseNumber: 'ms-nkc-2019-114',
            city: 'نواكشوط',
            address: 'x',
            phone: '41 41 41 41',
            cooperation: const {CooperationType.free},
          ),
      throwsA(isA<DuplicateRegistrationException>()),
    );
  });

  test('signed-in demo accounts find their own card', () {
    final auth = c.read(authProvider.notifier);
    auth.selectRole(UserRole.patient);
    auth.login();
    expect(c.read(myMemberCardProvider)?.holderId, 'reg13');
    auth.selectRole(UserRole.doctor);
    auth.login(specialtyId: 'psych');
    expect(c.read(myMemberCardProvider)?.holderId, 'reg24');
    auth.logout();
    c.read(facilitySessionProvider.notifier).signIn('f1');
    expect(c.read(myMemberCardProvider)?.holderId, 'f1');
  });

  test('printed cards keep the same number and code', () {
    final other = ProviderContainer();
    addTearDown(other.dispose);
    for (final holder in ['reg13', 'reg23', 'f1']) {
      final a = cardOf(holder)!;
      final b = other
          .read(memberCardsProvider)
          .firstWhere((x) => x.holderId == holder);
      expect(b.number, a.number);
      expect(b.verificationCode, a.verificationCode);
    }
    expect(cardOf('reg13')!.issuedAt, DateTime(2026, 10, 13));
  });
}
