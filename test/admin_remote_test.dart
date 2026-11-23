import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/admin_remote.dart';
import 'package:shifa/models/admin.dart';

void main() {
  StaffRow staff(String id, String email, String role) => StaffRow.fromJson({
    'user_id': id,
    'email': email,
    'name': email,
    'role': role,
    'active': true,
    'created_at': '2026-11-23T10:00:00Z',
  });

  test('a server session starts empty, then the saved data comes back', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(adminProvider.notifier);
    final team = [
      staff('u1', 'admin1@chifa.linnas.app', 'superAdmin'),
      staff('u2', 'admin2@chifa.linnas.app', 'superAdmin'),
    ];

    // First sign-in: nothing saved yet, no demo data.
    n.openRemote(RemoteSession('u1', team, null));
    var s = c.read(adminProvider);
    expect(s.remote, isTrue);
    expect(s.me!.email, 'admin1@chifa.linnas.app');
    expect(s.me!.role, AdminRole.superAdmin);
    expect(s.donations, isEmpty);
    expect(s.announcements, isEmpty);

    // Changes, then what would be saved on the server.
    n.addAnnouncement('حملة تبرع', 'السبت القادم');
    n.setSection(AppSection.blood, false);
    final saved = n.serverState();
    final public = n.serverPublic();
    expect(saved.containsKey('admins'), isFalse); // passwords never saved
    expect((public['announcements'] as List).length, 1);

    // Another manager signs in: same data.
    n.logout();
    n.openRemote(RemoteSession('u2', team, saved));
    s = c.read(adminProvider);
    expect(s.me!.email, 'admin2@chifa.linnas.app');
    expect(s.announcements.single.title, 'حملة تبرع');
    expect(s.settings.enabled(AppSection.blood), isFalse);
    expect(s.audit.any((a) => a.action == 'au_login'), isTrue);

    // The users' app applies the public part.
    final users = ProviderContainer();
    addTearDown(users.dispose);
    users.read(adminProvider.notifier).applyPublic(public);
    final u = users.read(adminProvider);
    expect(u.announcements.single.title, 'حملة تبرع');
    expect(u.settings.enabled(AppSection.blood), isFalse);
  });
}
