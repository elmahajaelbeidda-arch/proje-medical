import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/pulse_provider.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/models/admin.dart';
import 'package:shifa/models/pulse.dart';

void main() {
  late ProviderContainer c;
  const member = PulseActor('p1', 'محمد');
  const other = PulseActor('p2', 'مريم');

  setUp(
    () => c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    ),
  );
  tearDown(() => c.dispose());

  PulseNotifier n() => c.read(pulseProvider.notifier);
  PulseState s() => c.read(pulseProvider);
  void signIn(String email, String password) => expect(
    c.read(adminProvider.notifier).login(email, password),
    LoginResult.success,
  );

  test('visitors only see published posts, pinned first', () {
    final feed = s().publicFeed;
    expect(feed, isNotEmpty);
    expect(feed.every((p) => p.isPublic), isTrue);
    expect(feed.any((p) => p.id == 'ps2'), isFalse, reason: 'pending story');
    expect(feed.first.pinned, isTrue);
  });

  test('a shared story stays private until approved', () {
    final p = n().submitStory(
      who: member,
      title: 'شكراً للأطباء المتطوعين',
      body: 'تجربة جميلة مع التطبيق، وصلني الرد في يوم واحد وكان مفيداً جداً.',
      anonymous: true,
      privacyConfirmed: true,
    );
    expect(p.status, PulseStatus.pending);
    expect(
      p.authorName,
      isEmpty,
      reason: 'anonymous: name not stored for the public',
    );
    expect(s().publicFeed.any((x) => x.id == p.id), isFalse);
    expect(n().mySubmissions('p1').map((x) => x.id), contains(p.id));

    signIn('comm@shifa.mr', 'Comm@2026!');
    expect(() => n().approve(p.id, privacyChecked: false), throwsArgumentError);
    n().approve(p.id, privacyChecked: true);
    expect(s().publicFeed.any((x) => x.id == p.id), isTrue);
    expect(c.read(adminProvider).audit.first.action, 'au_pulse_approved');
  });

  test('a story needs the privacy confirmation', () {
    expect(
      () => n().submitStory(
        who: member,
        title: 'قصة',
        body: 'نص طويل بما يكفي لتجاوز الحد الأدنى المطلوب من الأحرف هنا.',
        anonymous: false,
        privacyConfirmed: false,
      ),
      throwsArgumentError,
    );
  });

  test('phone and ID numbers are masked when a story is published', () {
    signIn('comm@shifa.mr', 'Comm@2026!');
    expect(hasPersonalNumbers(s().post('ps2')!.body), isTrue);
    n().approve('ps2', privacyChecked: true);
    final body = s().post('ps2')!.body;
    expect(body.contains('36 12 34 56'), isFalse);
    expect(body.contains('•• •• •• ••'), isTrue);
  });

  test('rejecting needs a reason, which the author can read', () {
    signIn('comm@shifa.mr', 'Comm@2026!');
    expect(() => n().reject('ps2', ' '), throwsArgumentError);
    n().reject('ps2', 'يحتوي رقم هاتف شخصي');
    final mine = n().mySubmissions('u10').first;
    expect(mine.status, PulseStatus.rejected);
    expect(mine.rejectReason, 'يحتوي رقم هاتف شخصي');
  });

  test('only staff with the permission can publish or moderate', () {
    // Not signed in (the users' app).
    expect(
      () => n().publish(kind: PulseKind.news, title: 'x', body: 'y'),
      throwsA(isA<AdminPermissionDenied>()),
    );
    // Finance has no access to the community space.
    signIn('finance@shifa.mr', 'Finance@2026');
    expect(
      () => n().approve('ps2', privacyChecked: true),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(s().post('ps2')!.status, PulseStatus.pending);
  });

  test('staff publish news, pin, hide and delete; all audited', () {
    signIn('admin@shifa.mr', 'Admin@2026');
    final p = n().publish(
      kind: PulseKind.news,
      topic: NewsTopic.campaign,
      title: 'حملة تبرع بالدم',
      body: 'الأحد القادم بمقر الجمعية.',
      pinned: true,
    );
    expect(s().publicFeed.first.id, p.id);
    n().setHidden(p.id, true);
    expect(s().publicFeed.any((x) => x.id == p.id), isFalse);
    n().deletePost(p.id);
    expect(s().post(p.id), isNull);
    final actions = c.read(adminProvider).audit.map((a) => a.action).toList();
    expect(
      actions,
      containsAll([
        'au_pulse_published',
        'au_pulse_hidden',
        'au_pulse_deleted',
      ]),
    );
  });

  test('likes toggle per member; comments mask numbers and obey switches', () {
    final before = s().post('pn1')!.likes.length;
    n().toggleLike('pn1', member);
    n().toggleLike('pn1', member);
    n().toggleLike('pn1', other);
    expect(s().post('pn1')!.likes.length, before + 1);

    final cm = n().addComment('pn1', member, 'اتصلوا بي على 22334455');
    expect(cm.text.contains('22334455'), isFalse);

    signIn('comm@shifa.mr', 'Comm@2026!');
    n().setPostComments('pn1', false);
    expect(() => n().addComment('pn1', member, 'تعليق'), throwsStateError);
    n().setPostComments('pn1', true);
    n().setSettings(const PulseSettings(commentsEnabled: false));
    expect(() => n().addComment('pn1', member, 'تعليق'), throwsStateError);
  });

  test('reports reach the review queue and can be handled', () {
    final cm = n().addComment('pa1', member, 'تعليق غير لائق');
    n().reportComment(cm.id, other);
    n().reportPost('pn2', other);
    expect(s().reportedComments.map((x) => x.id), contains(cm.id));
    expect(s().reportedPosts.map((x) => x.id), contains('pn2'));

    signIn('comm@shifa.mr', 'Comm@2026!');
    n().setCommentHidden(cm.id, true);
    n().dismissPostReports('pn2');
    expect(s().visibleComments('pa1').any((x) => x.id == cm.id), isFalse);
    expect(s().reportedPosts, isEmpty);
  });

  test('live talk: questions before, chat during, recording after', () {
    n().askQuestion('lv1', member, 'ما هي أفضل أطعمة لمريض السكري؟');
    expect(s().live('lv1')!.questions.length, 2);
    expect(
      () => n().addLiveMessage('lv1', member, 'السلام عليكم'),
      throwsArgumentError,
      reason: 'chat opens when the broadcast starts',
    );

    signIn('comm@shifa.mr', 'Comm@2026!');
    n().startLive('lv1');
    expect(s().live('lv1')!.status, LiveStatus.live);
    n().addLiveMessage('lv1', member, 'السلام عليكم');
    expect(s().liveChat['lv1']!.length, 1);

    n().endLive('lv1', recordingUrl: 'https://youtube.com/watch?v=abc');
    final l = s().live('lv1')!;
    expect(l.hasRecording, isTrue);
    expect(l.questionsOpen, isFalse);
    expect(
      () => n().askQuestion('lv1', member, 'سؤال متأخر جداً'),
      throwsArgumentError,
    );
  });

  test('a live talk cannot start without a stream link', () {
    signIn('comm@shifa.mr', 'Comm@2026!');
    final l = n().scheduleLive(
      title: 'ندوة',
      speaker: 'د. أحمد',
      startsAt: DateTime.now().add(const Duration(days: 1)),
    );
    expect(() => n().startLive(l.id), throwsArgumentError);
    n().startLive(l.id, streamUrl: 'https://youtube.com/live/xyz');
    expect(s().live(l.id)!.status, LiveStatus.live);
  });

  test('communications role holds the community permission', () {
    expect(
      rolePermissions(AdminRole.communications),
      contains(AdminPermission.manageCommunity),
    );
    expect(
      rolePermissions(AdminRole.finance),
      isNot(contains(AdminPermission.manageCommunity)),
    );
  });
}
