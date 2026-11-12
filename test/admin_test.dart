import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_data.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/blood_provider.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/models/blood.dart';
import 'package:shifa/models/registration.dart';
import 'package:shifa/core/member_card_provider.dart';
import 'package:shifa/features/admin/totp.dart';
import 'package:shifa/features/admin/xlsx.dart';
import 'package:shifa/models/admin.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  AdminNotifier n() => c.read(adminProvider.notifier);
  AdminState s() => c.read(adminProvider);

  void signIn(String email, String password) {
    expect(n().login(email, password), LoginResult.needCode);
    expect(n().verifyCode(adminDemoCode), isTrue);
  }

  test('TOTP matches the RFC 6238 test vector', () {
    // ASCII "12345678901234567890" in base32.
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
    final t = DateTime.fromMillisecondsSinceEpoch(59 * 1000, isUtc: true);
    expect(Totp.code(secret, t), '287082');
    expect(Totp.verify(secret, '287082', now: t), isTrue);
    expect(Totp.verify(secret, '000000', now: t), isFalse);
  });

  test('password then second factor; wrong attempts lock the login', () {
    expect(n().login('admin@shifa.mr', 'nope'), LoginResult.wrong);
    expect(s().me, isNull);
    expect(n().login('admin@shifa.mr', 'Admin@2026'), LoginResult.needCode);
    expect(s().me, isNull); // not before the code
    expect(n().verifyCode('999999'), isFalse);
    expect(n().verifyCode(adminDemoCode), isTrue);
    expect(s().me!.email, 'admin@shifa.mr');
    n().logout();
    for (var i = 0; i < 4; i++) {
      n().login('admin@shifa.mr', 'x');
    }
    expect(n().login('admin@shifa.mr', 'x'), LoginResult.locked);
    expect(n().login('admin@shifa.mr', 'Admin@2026'), LoginResult.locked);
    expect(s().audit.where((a) => a.action == 'au_login_failed').length, 6);
  });

  test('authenticator app replaces the demo code', () {
    signIn('admin@shifa.mr', 'Admin@2026');
    final secret = Totp.newSecret();
    expect(n().enableTotp(secret, '000000'), isFalse);
    expect(n().enableTotp(secret, Totp.code(secret, DateTime.now())), isTrue);
    n().logout();
    n().login('admin@shifa.mr', 'Admin@2026');
    expect(n().verifyCode(adminDemoCode), isFalse);
    expect(n().verifyCode(Totp.code(secret, DateTime.now())), isTrue);
  });

  test('no admin goes beyond their permissions, and refusals are logged', () {
    signIn('finance@shifa.mr', 'Finance@2026');
    expect(s().can(AdminPermission.viewFinance), isTrue);
    expect(s().can(AdminPermission.viewMedicalRecords), isFalse);
    expect(
      () => n().openMedicalFile('C-001', 'test'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(
      () => n().suspendAccount('reg13', 'x', 'test'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(s().audit.first.action, 'au_denied');
    n().addDonation(
      Donation(
        id: '',
        donor: 'test',
        amount: 1000,
        method: DonationMethod.cash,
        date: DateTime.now(),
      ),
    );
    expect(s().audit.first.action, 'au_donation_added');
  });

  test('medical files need a reason and are logged as sensitive', () {
    signIn('medical@shifa.mr', 'Medical@2026');
    expect(() => n().openMedicalFile('C-001', ' '), throwsArgumentError);
    n().openMedicalFile('C-001', 'متابعة الحالة');
    expect(s().audit.first.sensitive, isTrue);
    expect(s().audit.first.target, 'C-001');
  });

  test('case decisions change the stage; rejection needs a reason', () {
    signIn('medical@shifa.mr', 'Medical@2026');
    final first = c.read(adminCasesProvider).first;
    expect(
      () => n().decideCase(first.id, first.code, CaseStage.rejected, ''),
      throwsArgumentError,
    );
    n().decideCase(first.id, first.code, CaseStage.rejected, 'خارج الاختصاص');
    final again = c
        .read(adminCasesProvider)
        .firstWhere((x) => x.id == first.id);
    expect(again.stage, CaseStage.rejected);
    expect(again.decision!.note, 'خارج الاختصاص');
  });

  test('suspending an account suspends its card; renewal extends it', () {
    signIn('admin@shifa.mr', 'Admin@2026');
    MemberCard0? card() => c
        .read(memberCardsProvider)
        .where((x) => x.holderId == 'reg13')
        .map((x) => MemberCard0(x.suspended, x.expiresAt))
        .firstOrNull;
    final before = card()!;
    n().suspendAccount('reg13', 'محمد الأمين', 'استعمال غير مشروع');
    expect(card()!.suspended, isTrue);
    n().reactivateAccount('reg13', 'محمد الأمين');
    expect(card()!.suspended, isFalse);
    n().renewCard('reg13', 'SL-P');
    expect(card()!.expiresAt.isAfter(before.expiresAt), isTrue);
  });

  test('admins cannot lock themselves out', () {
    signIn('admin@shifa.mr', 'Admin@2026');
    n().updatePermissions('adm1', AdminRole.custom, {
      AdminPermission.viewAudit,
    });
    expect(s().can(AdminPermission.manageAdmins), isTrue);
    expect(() => n().setAdminActive('adm1', false), throwsArgumentError);
    final id = n().createAdmin(
      name: 'مشرف',
      email: 'new@shifa.mr',
      password: 'Strong#2026',
      role: AdminRole.communications,
    );
    expect(
      s().admins.firstWhere((a) => a.id == id).permissions,
      rolePermissions(AdminRole.communications),
    );
    expect(
      () => n().createAdmin(
        name: 'x',
        email: 'NEW@shifa.mr',
        password: 'Strong#2026',
        role: AdminRole.auditor,
      ),
      throwsArgumentError,
    );
  });

  test('backup and restore bring the data back', () {
    signIn('admin@shifa.mr', 'Admin@2026');
    final backup = n().exportBackup();
    expect(backup, isNot(contains('Admin@2026'))); // hashes only
    final count = s().donations.length;
    n().addDonation(
      Donation(
        id: '',
        donor: 'later',
        amount: 5000,
        method: DonationMethod.cash,
        date: DateTime.now(),
      ),
    );
    n().setSection(AppSection.blood, false);
    expect(s().donations, hasLength(count + 1));
    n().restoreBackup(backup);
    expect(s().donations, hasLength(count));
    expect(s().settings.enabled(AppSection.blood), isTrue);
    expect(s().audit.first.action, 'au_backup_restored');
    expect(() => n().restoreBackup('{"x":1}'), throwsFormatException);
  });

  test('Excel export is a valid workbook', () {
    final bytes = buildXlsx([
      const XlsxSheet('ملخص', [
        ['البند', 'القيمة'],
        ['المرضى', 12],
      ]),
    ]);
    final zip = ZipDecoder().decodeBytes(bytes);
    final sheet = zip.findFile('xl/worksheets/sheet1.xml')!;
    final xml = utf8.decode(sheet.content as List<int>);
    expect(xml, contains('المرضى'));
    expect(xml, contains('<v>12</v>'));
    expect(zip.findFile('[Content_Types].xml'), isNotNull);
  });

  test('follow-up team member: field work only', () {
    signIn('team@shifa.mr', 'Team@2026!');
    expect(s().can(AdminPermission.manageBlood), isTrue);
    expect(s().can(AdminPermission.manageRegistrations), isTrue);
    expect(s().can(AdminPermission.viewFinance), isFalse);
    expect(s().can(AdminPermission.viewMedicalRecords), isFalse);
    expect(s().can(AdminPermission.manageAdmins), isFalse);
  });

  test('team actions on blood and registrations go to the audit log', () {
    // Not signed in to the dashboard: nothing is logged.
    final before = s().audit.length;
    final donor = c.read(bloodProvider).donors.first;
    c.read(bloodProvider.notifier).reviewDonor(donor.id, DonorStatus.approved);
    expect(s().audit.length, before);

    signIn('team@shifa.mr', 'Team@2026!');
    c.read(bloodProvider.notifier).reviewDonor(donor.id, DonorStatus.rejected);
    expect(s().audit.first.action, 'au_donor_rejected');
    expect(s().audit.first.adminName, 'عضو فريق المتابعة');
    final request = c.read(bloodProvider).requests.first;
    c.read(bloodProvider.notifier).assignDonor(request.id, donor.id);
    expect(s().audit.first.action, 'au_donor_assigned');
    c
        .read(registrationsProvider.notifier)
        .review('reg11', ReviewStatus.approved);
    expect(s().audit.first.action, 'au_approve');
  });
}

class MemberCard0 {
  final bool suspended;
  final DateTime expiresAt;
  MemberCard0(this.suspended, this.expiresAt);
}
