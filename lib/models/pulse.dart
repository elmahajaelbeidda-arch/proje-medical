import 'package:flutter/foundation.dart';

import 'models.dart' show Attachment;

// ---------------------------------------------------------------------------
// «أخبار وأنشطة شفاء» — the community space of the app: news, shared stories,
// photos and videos, live and recorded talks, and achievements.
// Readable by everyone, including visitors who have no account.
// ---------------------------------------------------------------------------

/// What a post is.
enum PulseKind {
  /// Association / app news, initiatives and charity campaigns.
  news,

  /// Experiences and human stories shared by users (reviewed first).
  story,

  /// Photo and video albums of activities and events.
  media,

  /// Projects, aid delivered, results and figures.
  achievement,
}

/// Sub-type of a news post.
enum NewsTopic { association, app, initiative, campaign }

/// Moderation state. Only [published] posts are visible to the public.
enum PulseStatus { pending, published, rejected, hidden }

enum PulseMediaType { image, video }

/// One photo or video of a post. [attachment] holds an uploaded photo;
/// [url] a video link (YouTube, Facebook…). Demo items have neither and are
/// drawn as an illustrated tile ([icon] + [tone]).
@immutable
class PulseMedia {
  final PulseMediaType type;
  final String caption;
  final Attachment? attachment;
  final String url;

  /// Illustration of the tile (see pulseIcon) and its colour index.
  final String icon;
  final int tone;

  const PulseMedia({
    required this.type,
    this.caption = '',
    this.attachment,
    this.url = '',
    this.icon = 'photo',
    this.tone = 0,
  });
}

/// A figure shown on an achievement post or the impact strip.
@immutable
class PulseStat {
  final String label;
  final String value;
  const PulseStat(this.label, this.value);
}

@immutable
class PulseComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime at;
  final bool hidden;

  /// User ids who reported this comment.
  final Set<String> reports;

  const PulseComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.at,
    this.hidden = false,
    this.reports = const {},
  });

  PulseComment copyWith({bool? hidden, Set<String>? reports}) => PulseComment(
    id: id,
    postId: postId,
    authorId: authorId,
    authorName: authorName,
    text: text,
    at: at,
    hidden: hidden ?? this.hidden,
    reports: reports ?? this.reports,
  );
}

@immutable
class PulsePost {
  final String id;
  final PulseKind kind;
  final NewsTopic? topic;
  final String title;
  final String body;

  /// Name shown on the post: the association, the author, or an alias.
  final String authorName;

  /// Account that sent a shared story (null: published by the team).
  final String? authorId;
  final bool anonymous;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final PulseStatus status;
  final String rejectReason;
  final List<PulseMedia> media;
  final List<PulseStat> stats;
  final bool pinned;
  final bool commentsOpen;
  final Set<String> likes;
  final int shares;
  final Set<String> reports;

  /// The author confirmed the post shows no patient's data or photo
  /// without their consent (required for shared stories).
  final bool privacyConfirmed;

  const PulsePost({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.topic,
    this.authorId,
    this.anonymous = false,
    this.publishedAt,
    this.status = PulseStatus.published,
    this.rejectReason = '',
    this.media = const [],
    this.stats = const [],
    this.pinned = false,
    this.commentsOpen = true,
    this.likes = const {},
    this.shares = 0,
    this.reports = const {},
    this.privacyConfirmed = true,
  });

  bool get isPublic => status == PulseStatus.published;
  bool get fromTeam => authorId == null;
  DateTime get date => publishedAt ?? createdAt;

  PulsePost copyWith({
    String? title,
    String? body,
    PulseStatus? status,
    String? rejectReason,
    DateTime? publishedAt,
    bool? pinned,
    bool? commentsOpen,
    Set<String>? likes,
    int? shares,
    Set<String>? reports,
    List<PulseMedia>? media,
  }) => PulsePost(
    id: id,
    kind: kind,
    topic: topic,
    title: title ?? this.title,
    body: body ?? this.body,
    authorName: authorName,
    authorId: authorId,
    anonymous: anonymous,
    createdAt: createdAt,
    publishedAt: publishedAt ?? this.publishedAt,
    status: status ?? this.status,
    rejectReason: rejectReason ?? this.rejectReason,
    media: media ?? this.media,
    stats: stats,
    pinned: pinned ?? this.pinned,
    commentsOpen: commentsOpen ?? this.commentsOpen,
    likes: likes ?? this.likes,
    shares: shares ?? this.shares,
    reports: reports ?? this.reports,
    privacyConfirmed: privacyConfirmed,
  );
}

// ---------------------------------------------------------------------------
// Live and recorded talks
// ---------------------------------------------------------------------------

enum LiveStatus { scheduled, live, ended }

@immutable
class LiveQuestion {
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime at;
  final bool answered;
  final bool hidden;
  final Set<String> votes;

  const LiveQuestion({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.at,
    this.answered = false,
    this.hidden = false,
    this.votes = const {},
  });

  LiveQuestion copyWith({bool? answered, bool? hidden, Set<String>? votes}) =>
      LiveQuestion(
        id: id,
        authorId: authorId,
        authorName: authorName,
        text: text,
        at: at,
        answered: answered ?? this.answered,
        hidden: hidden ?? this.hidden,
        votes: votes ?? this.votes,
      );
}

/// A lecture, seminar or medical / awareness meeting. The video itself is
/// broadcast on a streaming service (YouTube Live, Facebook Live…): the app
/// announces it, opens it, and hosts the comments and questions.
@immutable
class LiveSession {
  final String id;
  final String title;
  final String speaker;
  final String description;
  final DateTime startsAt;
  final int durationMinutes;
  final LiveStatus status;
  final String streamUrl;

  /// Link of the recording, once the broadcast has ended.
  final String recordingUrl;
  final bool commentsOpen;
  final bool questionsOpen;
  final List<LiveQuestion> questions;
  final int views;

  /// Members who asked to be reminded.
  final Set<String> reminders;

  const LiveSession({
    required this.id,
    required this.title,
    required this.speaker,
    required this.startsAt,
    this.description = '',
    this.durationMinutes = 60,
    this.status = LiveStatus.scheduled,
    this.streamUrl = '',
    this.recordingUrl = '',
    this.commentsOpen = true,
    this.questionsOpen = true,
    this.questions = const [],
    this.views = 0,
    this.reminders = const {},
  });

  bool get hasRecording =>
      status == LiveStatus.ended && recordingUrl.isNotEmpty;

  LiveSession copyWith({
    LiveStatus? status,
    String? streamUrl,
    String? recordingUrl,
    bool? commentsOpen,
    bool? questionsOpen,
    List<LiveQuestion>? questions,
    int? views,
    Set<String>? reminders,
  }) => LiveSession(
    id: id,
    title: title,
    speaker: speaker,
    description: description,
    startsAt: startsAt,
    durationMinutes: durationMinutes,
    status: status ?? this.status,
    streamUrl: streamUrl ?? this.streamUrl,
    recordingUrl: recordingUrl ?? this.recordingUrl,
    commentsOpen: commentsOpen ?? this.commentsOpen,
    questionsOpen: questionsOpen ?? this.questionsOpen,
    questions: questions ?? this.questions,
    views: views ?? this.views,
    reminders: reminders ?? this.reminders,
  );
}

/// Switches of the whole space, set by the administration.
@immutable
class PulseSettings {
  final bool commentsEnabled;
  final bool submissionsEnabled;
  final bool likesEnabled;

  const PulseSettings({
    this.commentsEnabled = true,
    this.submissionsEnabled = true,
    this.likesEnabled = true,
  });

  PulseSettings copyWith({
    bool? commentsEnabled,
    bool? submissionsEnabled,
    bool? likesEnabled,
  }) => PulseSettings(
    commentsEnabled: commentsEnabled ?? this.commentsEnabled,
    submissionsEnabled: submissionsEnabled ?? this.submissionsEnabled,
    likesEnabled: likesEnabled ?? this.likesEnabled,
  );
}

// ---------------------------------------------------------------------------
// Privacy helpers
// ---------------------------------------------------------------------------

final _phoneLike = RegExp(r'(?:\+?222[\s-]?)?(?:\d[\s-]?){8,}');

/// Hides phone and ID numbers in public text: "36 12 34 56" → "•••• ••".
String maskPersonalNumbers(String text) => text.replaceAllMapped(
  _phoneLike,
  (m) => m.group(0)!.replaceAll(RegExp(r'\d'), '•'),
);

/// True when a text seems to hold a phone or ID number (shown to reviewers).
bool hasPersonalNumbers(String text) => _phoneLike.hasMatch(text);
