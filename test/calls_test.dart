import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/calls.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/models/admin.dart';

void main() {
  late ProviderContainer c;
  setUp(
    () => c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    ),
  );
  tearDown(() => c.dispose());
  CallsNotifier n() => c.read(callsProvider.notifier);

  test('each consultation has its own private, hard-to-guess room', () {
    final a = n().roomFor('c1');
    expect(n().roomFor('c1'), a, reason: 'stable for both parties');
    final b = n().roomFor('c2');
    expect(b, isNot(a));
    expect(a, startsWith('shifa-'));
    expect(a.length, greaterThanOrEqualTo(6 + 24));
  });

  test('the patient joins only a call the doctor started in the last hour', () {
    expect(n().patientCanJoin('c1'), isFalse);
    n().start('c1', CallKind.voice, byDoctor: false);
    expect(
      n().patientCanJoin('c1'),
      isFalse,
      reason: 'patients cannot open calls',
    );
    n().start('c1', CallKind.video, byDoctor: true);
    expect(n().patientCanJoin('c1'), isTrue);
    expect(
      n().patientCanJoin(
        'c1',
        now: DateTime.now().add(const Duration(minutes: 61)),
      ),
      isFalse,
    );
    expect(
      n().patientCanJoin('c2'),
      isFalse,
      reason: 'other consultations stay closed',
    );
  });

  test(
    'call links open the room directly; voice calls start without camera',
    () {
      final voice = callUri(
        server: 'https://meet.example.org/',
        room: 'shifa-abc',
        kind: CallKind.voice,
        displayName: 'د. "أحمد"',
      ).toString();
      expect(voice, startsWith('https://meet.example.org/shifa-abc#'));
      expect(voice, contains('config.startWithVideoMuted=true'));
      expect(voice, contains('config.prejoinPageEnabled=false'));
      expect(voice, isNot(contains('"أحمد"')), reason: 'name is encoded');
      final video = callUri(
        server: 'https://meet.jit.si',
        room: 'shifa-abc',
        kind: CallKind.video,
        displayName: 'x',
      ).toString();
      expect(video, contains('config.startWithVideoMuted=false'));
    },
  );

  test('only settings managers choose the call server, https only', () {
    final admin = c.read(adminProvider.notifier);
    expect(c.read(callServerProvider), defaultCallServer);
    expect(
      () => admin.setCallServer('https://meet.aoun.mr'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(admin.login('admin@shifa.mr', 'Admin@2026'), LoginResult.success);
    expect(
      () => admin.setCallServer('http://meet.aoun.mr'),
      throwsArgumentError,
    );
    expect(() => admin.setCallServer('not a url'), throwsArgumentError);
    admin.setCallServer('https://meet.aoun.mr');
    expect(c.read(callServerProvider), 'https://meet.aoun.mr');
    expect(c.read(adminProvider).audit.first.action, 'au_call_server');
    admin.setCallServer('');
    expect(c.read(callServerProvider), defaultCallServer);
  });
}
