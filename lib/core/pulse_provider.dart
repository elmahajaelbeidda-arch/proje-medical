import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin.dart';
import '../models/pulse.dart';
import 'admin_provider.dart';

/// Who does an action in «نبض شفاء» (a signed-in member of the app).
class PulseActor {
  final String id;
  final String name;
  const PulseActor(this.id, this.name);
}

class PulseState {
  final List<PulsePost> posts;
  final List<PulseComment> comments;
  final List<LiveSession> lives;

  /// Live chat of each broadcast: session id → messages.
  final Map<String, List<PulseComment>> liveChat;
  final PulseSettings settings;

  const PulseState({
    this.posts = const [],
    this.comments = const [],
    this.lives = const [],
    this.liveChat = const {},
    this.settings = const PulseSettings(),
  });

  PulseState copyWith({
    List<PulsePost>? posts,
    List<PulseComment>? comments,
    List<LiveSession>? lives,
    Map<String, List<PulseComment>>? liveChat,
    PulseSettings? settings,
  }) => PulseState(
    posts: posts ?? this.posts,
    comments: comments ?? this.comments,
    lives: lives ?? this.lives,
    liveChat: liveChat ?? this.liveChat,
    settings: settings ?? this.settings,
  );

  PulsePost? post(String id) => posts.where((p) => p.id == id).firstOrNull;
  LiveSession? live(String id) => lives.where((l) => l.id == id).firstOrNull;

  /// What visitors and members see: published posts, pinned first, newest.
  List<PulsePost> get publicFeed {
    final l = posts.where((p) => p.isPublic).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    return l;
  }

  List<PulseComment> visibleComments(String postId) =>
      comments.where((c) => c.postId == postId && !c.hidden).toList()
        ..sort((a, b) => a.at.compareTo(b.at));

  /// Shared stories waiting for review, oldest first.
  List<PulsePost> get pending =>
      posts.where((p) => p.status == PulseStatus.pending).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Reported posts and comments that are still visible.
  List<PulsePost> get reportedPosts =>
      posts.where((p) => p.isPublic && p.reports.isNotEmpty).toList();
  List<PulseComment> get reportedComments => [
    ...comments,
    for (final l in liveChat.values) ...l,
  ].where((c) => !c.hidden && c.reports.isNotEmpty).toList();
}

class PulseNotifier extends Notifier<PulseState> {
  int _seq = 0;
  String _id(String p) => '$p${DateTime.now().microsecondsSinceEpoch}${_seq++}';

  @override
  PulseState build() => seedPulse(DateTime.now());

  // -------------------------------------------------------------------------
  // Members (signed-in users of the app)
  // -------------------------------------------------------------------------

  void toggleLike(String postId, PulseActor who) {
    if (!state.settings.likesEnabled) return;
    _updatePost(postId, (p) {
      if (!p.isPublic) return p;
      final likes = {...p.likes};
      if (!likes.remove(who.id)) likes.add(who.id);
      return p.copyWith(likes: likes);
    });
  }

  /// Sharing is open to everyone, visitors included.
  void countShare(String postId) =>
      _updatePost(postId, (p) => p.copyWith(shares: p.shares + 1));

  /// Comments are published at once; phone and ID numbers are masked, and
  /// the team can hide any comment afterwards.
  PulseComment addComment(String postId, PulseActor who, String text) {
    final p = state.post(postId);
    final t = text.trim();
    if (p == null || !p.isPublic) throw ArgumentError('post');
    if (!state.settings.commentsEnabled || !p.commentsOpen) {
      throw StateError('comments_closed');
    }
    if (t.isEmpty || t.length > 500) throw ArgumentError('text');
    final c = PulseComment(
      id: _id('pc'),
      postId: postId,
      authorId: who.id,
      authorName: who.name,
      text: maskPersonalNumbers(t),
      at: DateTime.now(),
    );
    state = state.copyWith(comments: [...state.comments, c]);
    return c;
  }

  void reportPost(String postId, PulseActor who) =>
      _updatePost(postId, (p) => p.copyWith(reports: {...p.reports, who.id}));

  void reportComment(String commentId, PulseActor who) => _updateComment(
    commentId,
    (c) => c.copyWith(reports: {...c.reports, who.id}),
  );

  /// A member shares an experience or a human story. It stays private until
  /// the team approves it.
  PulsePost submitStory({
    required PulseActor who,
    required String title,
    required String body,
    required bool anonymous,
    required bool privacyConfirmed,
    List<PulseMedia> media = const [],
  }) {
    if (!state.settings.submissionsEnabled) throw StateError('submissions_off');
    final t = title.trim(), b = body.trim();
    if (t.length < 4 || t.length > 90) throw ArgumentError('title');
    if (b.length < 30 || b.length > 3000) throw ArgumentError('body');
    if (!privacyConfirmed) throw ArgumentError('privacy');
    final p = PulsePost(
      id: _id('ps'),
      kind: PulseKind.story,
      title: t,
      body: b,
      authorId: who.id,
      authorName: anonymous ? '' : who.name,
      anonymous: anonymous,
      createdAt: DateTime.now(),
      status: PulseStatus.pending,
      media: media,
      privacyConfirmed: true,
    );
    state = state.copyWith(posts: [p, ...state.posts]);
    return p;
  }

  List<PulsePost> mySubmissions(String userId) =>
      state.posts.where((p) => p.authorId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void watchLive(String liveId) =>
      _updateLive(liveId, (l) => l.copyWith(views: l.views + 1));

  void toggleReminder(String liveId, PulseActor who) =>
      _updateLive(liveId, (l) {
        final r = {...l.reminders};
        if (!r.remove(who.id)) r.add(who.id);
        return l.copyWith(reminders: r);
      });

  void addLiveMessage(String liveId, PulseActor who, String text) {
    final l = state.live(liveId);
    final t = text.trim();
    if (l == null || l.status == LiveStatus.scheduled) {
      throw ArgumentError('live');
    }
    if (!state.settings.commentsEnabled || !l.commentsOpen) {
      throw StateError('comments_closed');
    }
    if (t.isEmpty || t.length > 300) throw ArgumentError('text');
    final c = PulseComment(
      id: _id('lc'),
      postId: liveId,
      authorId: who.id,
      authorName: who.name,
      text: maskPersonalNumbers(t),
      at: DateTime.now(),
    );
    state = state.copyWith(
      liveChat: {
        ...state.liveChat,
        liveId: [...?state.liveChat[liveId], c],
      },
    );
  }

  /// Questions can be sent before and during the talk.
  void askQuestion(String liveId, PulseActor who, String text) {
    final l = state.live(liveId);
    final t = text.trim();
    if (l == null || l.status == LiveStatus.ended) throw ArgumentError('live');
    if (!l.questionsOpen) throw StateError('questions_closed');
    if (t.length < 5 || t.length > 300) throw ArgumentError('text');
    final q = LiveQuestion(
      id: _id('lq'),
      authorId: who.id,
      authorName: who.name,
      text: maskPersonalNumbers(t),
      at: DateTime.now(),
    );
    _updateLive(liveId, (x) => x.copyWith(questions: [...x.questions, q]));
  }

  void voteQuestion(String liveId, String questionId, PulseActor who) =>
      _updateQuestion(liveId, questionId, (q) {
        final v = {...q.votes};
        if (!v.remove(who.id)) v.add(who.id);
        return q.copyWith(votes: v);
      });

  // -------------------------------------------------------------------------
  // Administration (dashboard): permission checked and audited
  // -------------------------------------------------------------------------

  AdminNotifier get _admin => ref.read(adminProvider.notifier);
  void _require() => _admin.authorize(AdminPermission.manageCommunity);
  void _log(String action, String target, [String details = '']) =>
      _admin.record(action, target: target, details: details);

  PulsePost publish({
    required PulseKind kind,
    required String title,
    required String body,
    NewsTopic? topic,
    List<PulseMedia> media = const [],
    List<PulseStat> stats = const [],
    bool pinned = false,
  }) {
    _require();
    final t = title.trim(), b = body.trim();
    if (t.isEmpty) throw ArgumentError('title');
    if (b.isEmpty && media.isEmpty) throw ArgumentError('body');
    final now = DateTime.now();
    final p = PulsePost(
      id: _id('pp'),
      kind: kind,
      topic: kind == PulseKind.news ? (topic ?? NewsTopic.association) : null,
      title: t,
      body: b,
      authorName: 'جمعية عون وسند الخيرية',
      createdAt: now,
      publishedAt: now,
      media: media,
      stats: stats,
      pinned: pinned,
    );
    state = state.copyWith(posts: [p, ...state.posts]);
    _log('au_pulse_published', t, kind.name);
    return p;
  }

  void editPost(String id, {required String title, required String body}) {
    _require();
    if (title.trim().isEmpty) throw ArgumentError('title');
    _updatePost(id, (p) => p.copyWith(title: title.trim(), body: body.trim()));
    _log('au_pulse_edited', title.trim());
  }

  /// Approves a shared story. The reviewer confirms that it respects the
  /// privacy of patients (no data or photo published without consent).
  void approve(String id, {required bool privacyChecked}) {
    _require();
    if (!privacyChecked) throw ArgumentError('privacy');
    final p = state.post(id)!;
    _updatePost(
      id,
      (x) => x.copyWith(
        status: PulseStatus.published,
        publishedAt: DateTime.now(),
        body: maskPersonalNumbers(x.body),
        title: maskPersonalNumbers(x.title),
      ),
    );
    _log('au_pulse_approved', p.title);
  }

  void reject(String id, String reason) {
    _require();
    if (reason.trim().isEmpty) throw ArgumentError('reason');
    final p = state.post(id)!;
    _updatePost(
      id,
      (x) =>
          x.copyWith(status: PulseStatus.rejected, rejectReason: reason.trim()),
    );
    _log('au_pulse_rejected', p.title, reason.trim());
  }

  void setHidden(String id, bool hidden) {
    _require();
    final p = state.post(id)!;
    _updatePost(
      id,
      (x) => x.copyWith(
        status: hidden ? PulseStatus.hidden : PulseStatus.published,
        reports: hidden ? x.reports : const {},
      ),
    );
    _log(hidden ? 'au_pulse_hidden' : 'au_pulse_shown', p.title);
  }

  void deletePost(String id) {
    _require();
    final p = state.post(id)!;
    state = state.copyWith(
      posts: [
        for (final x in state.posts)
          if (x.id != id) x,
      ],
      comments: [
        for (final c in state.comments)
          if (c.postId != id) c,
      ],
    );
    _log('au_pulse_deleted', p.title);
  }

  void setPinned(String id, bool pinned) {
    _require();
    final p = state.post(id)!;
    _updatePost(id, (x) => x.copyWith(pinned: pinned));
    _log(pinned ? 'au_pulse_pinned' : 'au_pulse_unpinned', p.title);
  }

  void setPostComments(String id, bool open) {
    _require();
    final p = state.post(id)!;
    _updatePost(id, (x) => x.copyWith(commentsOpen: open));
    _log(open ? 'au_pulse_comments_on' : 'au_pulse_comments_off', p.title);
  }

  /// Clears the reports of a post judged acceptable.
  void dismissPostReports(String id) {
    _require();
    final p = state.post(id)!;
    _updatePost(id, (x) => x.copyWith(reports: const {}));
    _log('au_pulse_reports_dismissed', p.title);
  }

  void setCommentHidden(String commentId, bool hidden) {
    _require();
    _updateComment(
      commentId,
      (c) => c.copyWith(hidden: hidden, reports: hidden ? c.reports : const {}),
    );
    _log(
      hidden ? 'au_pulse_comment_hidden' : 'au_pulse_comment_shown',
      commentId,
    );
  }

  void setSettings(PulseSettings s) {
    _require();
    state = state.copyWith(settings: s);
    _log(
      'au_pulse_settings',
      '',
      'comments=${s.commentsEnabled} stories=${s.submissionsEnabled} likes=${s.likesEnabled}',
    );
  }

  LiveSession scheduleLive({
    required String title,
    required String speaker,
    required DateTime startsAt,
    String description = '',
    int durationMinutes = 60,
    String streamUrl = '',
  }) {
    _require();
    if (title.trim().isEmpty || speaker.trim().isEmpty) {
      throw ArgumentError('title');
    }
    final l = LiveSession(
      id: _id('lv'),
      title: title.trim(),
      speaker: speaker.trim(),
      description: description.trim(),
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      streamUrl: streamUrl.trim(),
    );
    state = state.copyWith(lives: [...state.lives, l]);
    _log('au_live_scheduled', l.title);
    return l;
  }

  void startLive(String id, {String? streamUrl}) {
    _require();
    final l = state.live(id)!;
    final url = (streamUrl ?? l.streamUrl).trim();
    if (url.isEmpty) throw ArgumentError('url');
    _updateLive(id, (x) => x.copyWith(status: LiveStatus.live, streamUrl: url));
    _log('au_live_started', l.title);
  }

  /// Ends the broadcast; with a recording link it joins the recorded talks.
  void endLive(String id, {String recordingUrl = ''}) {
    _require();
    final l = state.live(id)!;
    _updateLive(
      id,
      (x) => x.copyWith(
        status: LiveStatus.ended,
        recordingUrl: recordingUrl.trim().isEmpty
            ? x.recordingUrl
            : recordingUrl.trim(),
        questionsOpen: false,
      ),
    );
    _log('au_live_ended', l.title);
  }

  void setRecording(String id, String url) {
    _require();
    final l = state.live(id)!;
    _updateLive(id, (x) => x.copyWith(recordingUrl: url.trim()));
    _log('au_live_recording', l.title);
  }

  void deleteLive(String id) {
    _require();
    final l = state.live(id)!;
    state = state.copyWith(
      lives: [
        for (final x in state.lives)
          if (x.id != id) x,
      ],
      liveChat: {...state.liveChat}..remove(id),
    );
    _log('au_live_deleted', l.title);
  }

  void setLiveInteractions(String id, {bool? comments, bool? questions}) {
    _require();
    final l = state.live(id)!;
    _updateLive(
      id,
      (x) => x.copyWith(commentsOpen: comments, questionsOpen: questions),
    );
    _log(
      'au_live_interactions',
      l.title,
      'comments=$comments questions=$questions',
    );
  }

  void markAnswered(String liveId, String questionId, bool answered) {
    _require();
    _updateQuestion(liveId, questionId, (q) => q.copyWith(answered: answered));
  }

  void hideQuestion(String liveId, String questionId) {
    _require();
    _updateQuestion(liveId, questionId, (q) => q.copyWith(hidden: true));
    _log('au_live_question_hidden', state.live(liveId)!.title);
  }

  // -------------------------------------------------------------------------

  void _updatePost(String id, PulsePost Function(PulsePost) f) => state = state
      .copyWith(posts: [for (final p in state.posts) p.id == id ? f(p) : p]);

  void _updateComment(String id, PulseComment Function(PulseComment) f) {
    state = state.copyWith(
      comments: [for (final c in state.comments) c.id == id ? f(c) : c],
      liveChat: {
        for (final e in state.liveChat.entries)
          e.key: [for (final c in e.value) c.id == id ? f(c) : c],
      },
    );
  }

  void _updateLive(String id, LiveSession Function(LiveSession) f) =>
      state = state.copyWith(
        lives: [for (final l in state.lives) l.id == id ? f(l) : l],
      );

  void _updateQuestion(
    String liveId,
    String qId,
    LiveQuestion Function(LiveQuestion) f,
  ) => _updateLive(
    liveId,
    (l) => l.copyWith(
      questions: [for (final q in l.questions) q.id == qId ? f(q) : q],
    ),
  );
}

final pulseProvider = NotifierProvider<PulseNotifier, PulseState>(
  PulseNotifier.new,
);

// ---------------------------------------------------------------------------
// Demo content
// ---------------------------------------------------------------------------

PulseState seedPulse(DateTime now) {
  DateTime ago(int days, [int hours = 0]) =>
      now.subtract(Duration(days: days, hours: hours));
  const team = 'جمعية عون وسند الخيرية';
  return PulseState(
    posts: [
      PulsePost(
        id: 'pa1',
        kind: PulseKind.achievement,
        title: 'حصاد الأشهر الستة الأولى',
        body: 'بفضل الله ثم بفضل أطبائنا المتطوعين وشركائنا والمتبرعين، هذه بعض ثمار «شفاء للناس» منذ انطلاقه. شكراً لكل من كان سبباً في هذا الأثر.',
        authorName: team,
        createdAt: ago(2),
        publishedAt: ago(2),
        pinned: true,
        stats: const [
          PulseStat('استشارة طبية', '1 240'),
          PulseStat('طبيب متطوع', '48'),
          PulseStat('متبرع بالدم', '310'),
          PulseStat('جهة طبية شريكة', '17'),
        ],
        likes: const {'u1', 'u2', 'u3', 'u4', 'u5', 'u6', 'u7'},
        shares: 23,
      ),
      PulsePost(
        id: 'pn1',
        kind: PulseKind.news,
        topic: NewsTopic.campaign,
        title: 'حملة الكشف المجاني عن السكري — السبت القادم',
        body: 'تنظّم الجمعية بالتعاون مع مختبر الشفاء حملة كشف مجاني عن السكري وضغط الدم، يوم السبت من الساعة 9 صباحاً حتى 1 ظهراً بمقر الجمعية في نواكشوط. الحضور مفتوح للجميع، ويُرجى إحضار بطاقة التعريف.',
        authorName: team,
        createdAt: ago(0, 5),
        publishedAt: ago(0, 5),
        media: const [
          PulseMedia(
            type: PulseMediaType.image,
            caption: 'ملصق الحملة',
            icon: 'campaign',
            tone: 1,
          ),
        ],
        likes: const {'u1', 'u2', 'u3'},
        shares: 11,
      ),
      PulsePost(
        id: 'pm1',
        kind: PulseKind.media,
        title: 'صور من قافلة «صحتك أمانة» في روصو',
        body: 'قافلة طبية ليومين: كشف عام، توزيع أدوية، وتوعية صحية. الصور منشورة بموافقة الظاهرين فيها، ودون إظهار وجوه المرضى.',
        authorName: team,
        createdAt: ago(4),
        publishedAt: ago(4),
        media: const [
          PulseMedia(
            type: PulseMediaType.image,
            caption: 'فريق المتطوعين قبل الانطلاق',
            icon: 'group',
            tone: 0,
          ),
          PulseMedia(
            type: PulseMediaType.image,
            caption: 'توزيع الأدوية',
            icon: 'medication',
            tone: 2,
          ),
          PulseMedia(
            type: PulseMediaType.video,
            caption: 'دقيقة من القافلة',
            icon: 'video',
            tone: 1,
            url: 'demo:video',
          ),
          PulseMedia(
            type: PulseMediaType.image,
            caption: 'جلسة توعية للأمهات',
            icon: 'school',
            tone: 3,
          ),
        ],
        likes: const {'u2', 'u4', 'u5', 'u8'},
        shares: 9,
      ),
      PulsePost(
        id: 'ps1',
        kind: PulseKind.story,
        title: 'استشارة غيّرت قرار عائلتنا',
        body: 'كانت والدتي تعاني من آلام متكررة ولم نكن نعرف إلى أين نتجه. أرسلنا تحاليلها عبر التطبيق، وردّ علينا طبيب متطوع في اليوم نفسه، ووجّهنا إلى الفحص المناسب. اليوم حالتها مستقرة، والحمد لله. شكراً لكل من يقف خلف هذه المبادرة.',
        authorId: 'u9',
        authorName: '',
        anonymous: true,
        createdAt: ago(6),
        publishedAt: ago(5),
        likes: const {'u1', 'u3', 'u6', 'u7', 'u8'},
        shares: 4,
      ),
      PulsePost(
        id: 'pn2',
        kind: PulseKind.news,
        topic: NewsTopic.app,
        title: 'جديد التطبيق: الخريطة الطبية',
        body: 'أصبح بإمكانكم الآن العثور على أقرب طبيب أو عيادة معتمدة من الجمعية، والوصول إليها بلمسة عبر «الخريطة الطبية» في الصفحة الرئيسية.',
        authorName: team,
        createdAt: ago(7),
        publishedAt: ago(7),
        media: const [
          PulseMedia(
            type: PulseMediaType.image,
            caption: 'الخريطة الطبية',
            icon: 'map',
            tone: 2,
          ),
        ],
        likes: const {'u1', 'u5'},
        shares: 6,
      ),
      PulsePost(
        id: 'pn3',
        kind: PulseKind.news,
        topic: NewsTopic.initiative,
        title: 'مبادرة «دواء لكل مريض»',
        body: 'نطلق مبادرة لتوفير الأدوية المزمنة للمرضى غير القادرين، بالتعاون مع صيدليات شريكة. يمكنكم دعم المبادرة عبر رقم التبرع للجمعية.',
        authorName: team,
        createdAt: ago(10),
        publishedAt: ago(10),
        likes: const {'u2'},
        shares: 3,
      ),
      // A story waiting for review (seen only by its author and the team).
      PulsePost(
        id: 'ps2',
        kind: PulseKind.story,
        title: 'تجربتي كمتبرع بالدم لأول مرة',
        body: 'سجّلت فصيلتي في التطبيق، وبعد أسبوع اتصل بي فريق المتابعة لحالة عاجلة في مستشفى الصداقة. كانت تجربة لا تُنسى، وأنصح الجميع بالتسجيل. للتواصل معي 36 12 34 56.',
        authorId: 'u10',
        authorName: 'سيدي محمد',
        createdAt: ago(0, 3),
        status: PulseStatus.pending,
      ),
    ],
    comments: [
      PulseComment(
        id: 'c1',
        postId: 'pa1',
        authorId: 'u3',
        authorName: 'مريم',
        text: 'ما شاء الله، جهد مبارك. جزاكم الله خيراً.',
        at: ago(1, 20),
      ),
      PulseComment(
        id: 'c2',
        postId: 'pn1',
        authorId: 'u4',
        authorName: 'أحمد',
        text: 'هل الكشف متاح للأطفال أيضاً؟',
        at: ago(0, 4),
      ),
      PulseComment(
        id: 'c3',
        postId: 'ps1',
        authorId: 'u6',
        authorName: 'فاطمة',
        text: 'الحمد لله على سلامتها، قصة ملهمة.',
        at: ago(4),
      ),
    ],
    lives: [
      LiveSession(
        id: 'lv1',
        title: 'السكري: كيف نتعايش معه ونتجنب مضاعفاته؟',
        speaker: 'د. أحمد ولد محمد — طب باطني',
        description: 'محاضرة توعوية مباشرة، يجيب فيها الطبيب عن أسئلتكم. أرسلوا أسئلتكم من الآن.',
        startsAt: DateTime(now.year, now.month, now.day + 2, 20),
        streamUrl: 'demo:live',
        questions: [
          LiveQuestion(
            id: 'q1',
            authorId: 'u2',
            authorName: 'خديجة',
            text: 'هل يمكن لمريض السكري الصيام دون خطر؟',
            at: ago(0, 2),
            votes: const {'u1', 'u3'},
          ),
        ],
        reminders: const {'u1', 'u2', 'u3', 'u5'},
      ),
      LiveSession(
        id: 'lv2',
        title: 'الصحة النفسية للشباب: متى نطلب المساعدة؟',
        speaker: 'د. مريم بنت سيدي — طب نفسي',
        description: 'ندوة حوارية مسجلة مع أسئلة الحضور.',
        startsAt: ago(9),
        durationMinutes: 75,
        status: LiveStatus.ended,
        recordingUrl: 'demo:recording',
        questionsOpen: false,
        views: 640,
      ),
      LiveSession(
        id: 'lv3',
        title: 'الإسعافات الأولية في البيت',
        speaker: 'فريق المسعفين المتطوعين',
        description: 'لقاء تدريبي: الحروق، الاختناق، النزيف.',
        startsAt: ago(21),
        durationMinutes: 50,
        status: LiveStatus.ended,
        recordingUrl: 'demo:recording',
        questionsOpen: false,
        views: 1130,
      ),
    ],
  );
}
