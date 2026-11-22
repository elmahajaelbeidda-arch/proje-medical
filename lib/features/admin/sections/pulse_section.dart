import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/pulse_provider.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/models.dart';
import '../../../models/pulse.dart';
import '../../../widgets/media.dart';
import '../../pulse/pulse_screens.dart'
    show kindKey, topicKey, MediaGrid, liveWhen;
import '../admin_ui.dart';
import 'overview_section.dart' show Pill;

/// «نبض شفاء»: publish, review shared stories, organise live talks and
/// moderate interactions. Every action is permission-checked and audited.
class PulseSection extends ConsumerStatefulWidget {
  const PulseSection({super.key});
  @override
  ConsumerState<PulseSection> createState() => _PulseSectionState();
}

enum _Tab { review, posts, live, interactions }

class _PulseSectionState extends ConsumerState<PulseSection> {
  _Tab _tab = _Tab.review;

  @override
  Widget build(BuildContext context) {
    final can = ref.watch(
      adminProvider.select((s) => s.can(AdminPermission.manageCommunity)),
    );
    if (!can) return const NoAccess();
    final s = ref.watch(pulseProvider);
    final reports = s.reportedPosts.length + s.reportedComments.length;
    final published = s.posts.where((p) => p.isPublic).toList();
    return AdminPage(
      title: context.tr('pl_name'),
      subtitle: context.tr('pl_slogan'),
      children: [
        KpiWrap(
          children: [
            Kpi(
              label: context.tr('pla_published'),
              value: '${published.length}',
              icon: LucideIcons.layers,
            ),
            Kpi(
              label: context.tr('pla_pending'),
              value: '${s.pending.length}',
              icon: LucideIcons.hourglass,
              color: AppColors.turquoise,
              onTap: () => setState(() => _tab = _Tab.review),
            ),
            Kpi(
              label: context.tr('pla_reports'),
              value: '$reports',
              icon: LucideIcons.flag,
              color: AppColors.turquoise,
              onTap: () => setState(() => _tab = _Tab.review),
            ),
            Kpi(
              label: context.tr('pla_likes'),
              value: '${published.fold<int>(0, (n, p) => n + p.likes.length)}',
              icon: LucideIcons.heart,
              color: AppColors.vivid,
            ),
            Kpi(
              label: context.tr('pl_comments'),
              value: '${s.comments.where((c) => !c.hidden).length}',
              icon: LucideIcons.messagesSquare,
            ),
            Kpi(
              label: context.tr('pla_upcoming_lives'),
              value:
                  '${s.lives.where((l) => l.status != LiveStatus.ended).length}',
              icon: LucideIcons.radio,
              onTap: () => setState(() => _tab = _Tab.live),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilterRow<_Tab>(
          values: _Tab.values,
          selected: _tab,
          label: (t) => switch (t!) {
            _Tab.review =>
              '${context.tr('pla_tab_review')} (${s.pending.length + reports})',
            _Tab.posts => context.tr('pla_tab_posts'),
            _Tab.live => context.tr('pla_tab_live'),
            _Tab.interactions => context.tr('pla_tab_interactions'),
          },
          onSelected: (t) => setState(() => _tab = t ?? _Tab.review),
        ),
        const SizedBox(height: 12),
        switch (_tab) {
          _Tab.review => const _ReviewTab(),
          _Tab.posts => const _PostsTab(),
          _Tab.live => const _LiveTab(),
          _Tab.interactions => const _InteractionsTab(),
        },
      ],
    );
  }
}

PulseNotifier _n(WidgetRef ref) => ref.read(pulseProvider.notifier);

Future<bool> _confirm(BuildContext context, String key) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr(key)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('pl_ok')),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  bool required = false,
}) async {
  final c = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label, hintText: 'https://'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (required && c.text.trim().isEmpty) return;
            Navigator.pop(ctx, true);
          },
          child: Text(ctx.tr('pl_ok')),
        ),
      ],
    ),
  );
  final v = c.text;
  c.dispose();
  return ok == true ? v : null;
}

String _statusKey(PulseStatus s) => 'pl_st_${s.name}';
Color _statusColor(PulseStatus s) => switch (s) {
  PulseStatus.pending => AppColors.turquoise,
  PulseStatus.published => AppColors.vivid,
  PulseStatus.rejected => AppColors.error,
  PulseStatus.hidden => AppColors.grey,
};

// ---------------------------------------------------------------------------
// Review: shared stories and reports
// ---------------------------------------------------------------------------

class _ReviewTab extends ConsumerWidget {
  const _ReviewTab();

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    PulsePost p,
  ) async {
    var checked = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('pla_approve')),
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: checked,
            onChanged: (v) => setState(() => checked = v ?? false),
            title: Text(ctx.tr('pla_privacy_reviewed')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: checked ? () => Navigator.pop(ctx, true) : null,
              child: Text(ctx.tr('pla_publish_now')),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      guarded(
        context,
        () => _n(ref).approve(p.id, privacyChecked: true),
        ok: 'pla_approved',
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, PulsePost p) async {
    final r = await askReason(context, title: context.tr('pla_reject'));
    if (r != null && context.mounted) {
      guarded(context, () => _n(ref).reject(p.id, r), ok: 'pla_rejected');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(pulseProvider);
    final pending = s.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: context.tr('pla_pending_stories'),
          child: pending.isEmpty
              ? Text(context.tr('pla_nothing_pending'))
              : Column(
                  children: [
                    for (final p in pending)
                      Card(
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    p.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Pill(
                                    label: p.anonymous
                                        ? '${context.tr('pl_anonymous')} (${p.authorName.isEmpty ? p.authorId : p.authorName})'
                                        : p.authorName,
                                    color: AppColors.secondary,
                                  ),
                                  Text(
                                    fmtDateTime(p.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(p.body, style: const TextStyle(height: 1.6)),
                              if (hasPersonalNumbers(
                                '${p.title} ${p.body}',
                              )) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.shieldAlert,
                                      color: AppColors.turquoise,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        context.tr('pla_numbers_found'),
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (p.media.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 360,
                                  child: MediaGrid(p.media, full: true),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr('pla_check_photos'),
                                  style: const TextStyle(
                                    color: AppColors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _approve(context, ref, p),
                                    icon: const Icon(LucideIcons.check),
                                    label: Text(context.tr('pla_approve')),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _reject(context, ref, p),
                                    icon: const Icon(LucideIcons.x),
                                    label: Text(context.tr('pla_reject')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        Panel(
          title: context.tr('pla_reported'),
          child: s.reportedPosts.isEmpty && s.reportedComments.isEmpty
              ? Text(context.tr('pla_no_reports'))
              : Column(
                  children: [
                    for (final p in s.reportedPosts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.newspaper),
                        title: Text(p.title),
                        subtitle: Text(
                          context.tr(
                            'pla_reports_n',
                            args: {'n': p.reports.length},
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => guarded(
                                context,
                                () => _n(ref).dismissPostReports(p.id),
                                ok: 'pla_done',
                              ),
                              child: Text(context.tr('pla_keep')),
                            ),
                            FilledButton.tonal(
                              onPressed: () => guarded(
                                context,
                                () => _n(ref).setHidden(p.id, true),
                                ok: 'pla_done',
                              ),
                              child: Text(context.tr('pla_hide')),
                            ),
                          ],
                        ),
                      ),
                    for (final c in s.reportedComments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(LucideIcons.messageSquare),
                        title: Text(c.text),
                        subtitle: Text(
                          '${c.authorName} · ${context.tr('pla_reports_n', args: {'n': c.reports.length})}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            TextButton(
                              onPressed: () => guarded(
                                context,
                                () => _n(ref).setCommentHidden(c.id, false),
                                ok: 'pla_done',
                              ),
                              child: Text(context.tr('pla_keep')),
                            ),
                            FilledButton.tonal(
                              onPressed: () => guarded(
                                context,
                                () => _n(ref).setCommentHidden(c.id, true),
                                ok: 'pla_done',
                              ),
                              child: Text(context.tr('pla_hide')),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Posts: publish and organise
// ---------------------------------------------------------------------------

class _PostsTab extends ConsumerStatefulWidget {
  const _PostsTab();
  @override
  ConsumerState<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<_PostsTab> {
  PulseKind _kind = PulseKind.news;
  NewsTopic _topic = NewsTopic.association;
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _video = TextEditingController();
  final _photos = <Attachment>[];
  final _stats = <(TextEditingController, TextEditingController)>[];
  bool _pinned = false;
  PulseStatus? _filter;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _video.dispose();
    for (final (a, b) in _stats) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await pickAttachments(context, PickSource.gallery);
    setState(
      () => _photos.addAll(picked.where((a) => a.kind == AttachmentKind.image)),
    );
  }

  void _publish() {
    final media = [
      for (final a in _photos)
        PulseMedia(type: PulseMediaType.image, attachment: a),
      if (_video.text.trim().isNotEmpty)
        PulseMedia(
          type: PulseMediaType.video,
          url: _video.text.trim(),
          icon: 'video',
          tone: 1,
        ),
    ];
    final stats = [
      for (final (l, v) in _stats)
        if (l.text.trim().isNotEmpty && v.text.trim().isNotEmpty)
          PulseStat(l.text.trim(), v.text.trim()),
    ];
    final ok = guarded(
      context,
      () => _n(ref).publish(
        kind: _kind,
        topic: _topic,
        title: _title.text,
        body: _body.text,
        media: media,
        stats: stats,
        pinned: _pinned,
      ),
      ok: 'pla_published_ok',
    );
    if (ok) {
      setState(() {
        _title.clear();
        _body.clear();
        _video.clear();
        _photos.clear();
        _stats.clear();
        _pinned = false;
      });
    }
  }

  Future<void> _edit(PulsePost p) async {
    final t = TextEditingController(text: p.title);
    final b = TextEditingController(text: p.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('pla_edit')),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: t,
                decoration: InputDecoration(labelText: ctx.tr('pla_title')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: b,
                minLines: 4,
                maxLines: 10,
                decoration: InputDecoration(labelText: ctx.tr('pla_body')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('save')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      guarded(
        context,
        () => _n(ref).editPost(p.id, title: t.text, body: b.text),
        ok: 'pla_done',
      );
    }
    t.dispose();
    b.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pulseProvider);
    final posts =
        s.posts.where((p) => _filter == null || p.status == _filter).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: context.tr('pla_new_post'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in [
                    PulseKind.news,
                    PulseKind.media,
                    PulseKind.achievement,
                  ])
                    ChoiceChip(
                      label: Text(context.tr(kindKey(k))),
                      selected: _kind == k,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
              if (_kind == PulseKind.news) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in NewsTopic.values)
                      FilterChip(
                        label: Text(context.tr(topicKey(t))),
                        selected: _topic == t,
                        onSelected: (_) => setState(() => _topic = t),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: context.tr('pla_title')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: context.tr('pla_body'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final a in _photos) AttachmentThumb(a, size: 64),
                  OutlinedButton.icon(
                    onPressed: _addPhotos,
                    icon: const Icon(LucideIcons.imagePlus),
                    label: Text(context.tr('pl_add_photos')),
                  ),
                  if (_photos.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_photos.clear),
                      child: Text(context.tr('pla_clear_photos')),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _video,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.tr('pla_video_link'),
                  hintText: 'https://youtube.com/…',
                  prefixIcon: const Icon(LucideIcons.monitorPlay),
                ),
              ),
              if (_kind == PulseKind.achievement) ...[
                const SizedBox(height: 10),
                Text(
                  context.tr('pla_figures'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                for (final (l, v) in _stats)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: l,
                            decoration: InputDecoration(
                              labelText: context.tr('pla_figure_label'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: v,
                            decoration: InputDecoration(
                              labelText: context.tr('pla_figure_value'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _stats.add((
                        TextEditingController(),
                        TextEditingController(),
                      )),
                    ),
                    icon: const Icon(LucideIcons.plus),
                    label: Text(context.tr('pla_add_figure')),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
                title: Text(context.tr('pla_pin')),
              ),
              Text(
                context.tr('pla_privacy_note'),
                style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _publish,
                  icon: const Icon(LucideIcons.upload),
                  label: Text(context.tr('pla_publish_now')),
                ),
              ),
            ],
          ),
        ),
        Panel(
          title: context.tr('pla_all_posts'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterRow<PulseStatus>(
                values: [null, ...PulseStatus.values],
                selected: _filter,
                label: (v) => v == null
                    ? context.tr('pla_all')
                    : context.tr(_statusKey(v)),
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 6),
              for (final p in posts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: p.pinned
                      ? const Icon(LucideIcons.pin, color: AppColors.turquoise)
                      : const Icon(
                          LucideIcons.newspaper,
                          color: AppColors.grey,
                        ),
                  title: Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(
                        label: context.tr(_statusKey(p.status)),
                        color: _statusColor(p.status),
                      ),
                      Text(context.tr(kindKey(p.kind))),
                      Text(
                        '♥ ${p.likes.length} · 💬 ${s.visibleComments(p.id).length} · ↗ ${p.shares}',
                      ),
                      if (!p.commentsOpen)
                        Text(context.tr('pla_comments_closed_short')),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'pin':
                          guarded(
                            context,
                            () => _n(ref).setPinned(p.id, !p.pinned),
                            ok: 'pla_done',
                          );
                        case 'comments':
                          guarded(
                            context,
                            () =>
                                _n(ref).setPostComments(p.id, !p.commentsOpen),
                            ok: 'pla_done',
                          );
                        case 'hide':
                          guarded(
                            context,
                            () => _n(ref).setHidden(p.id, p.isPublic),
                            ok: 'pla_done',
                          );
                        case 'edit':
                          await _edit(p);
                        case 'delete':
                          if (await _confirm(context, 'pla_delete_confirm') &&
                              context.mounted) {
                            guarded(
                              context,
                              () => _n(ref).deletePost(p.id),
                              ok: 'pla_done',
                            );
                          }
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(ctx.tr('pla_edit')),
                      ),
                      if (p.isPublic)
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(
                            ctx.tr(p.pinned ? 'pla_unpin' : 'pla_pin'),
                          ),
                        ),
                      if (p.isPublic)
                        PopupMenuItem(
                          value: 'comments',
                          child: Text(
                            ctx.tr(
                              p.commentsOpen
                                  ? 'pla_close_comments'
                                  : 'pla_open_comments',
                            ),
                          ),
                        ),
                      if (p.status == PulseStatus.published ||
                          p.status == PulseStatus.hidden)
                        PopupMenuItem(
                          value: 'hide',
                          child: Text(
                            ctx.tr(p.isPublic ? 'pla_hide' : 'pla_show'),
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(ctx.tr('pla_delete')),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live talks
// ---------------------------------------------------------------------------

class _LiveTab extends ConsumerStatefulWidget {
  const _LiveTab();
  @override
  ConsumerState<_LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends ConsumerState<_LiveTab> {
  final _title = TextEditingController();
  final _speaker = TextEditingController();
  final _desc = TextEditingController();
  final _url = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  int _duration = 60;

  @override
  void dispose() {
    _title.dispose();
    _speaker.dispose();
    _desc.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (t == null) return;
    setState(() => _when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _schedule() {
    final ok = guarded(
      context,
      () => _n(ref).scheduleLive(
        title: _title.text,
        speaker: _speaker.text,
        description: _desc.text,
        startsAt: _when,
        durationMinutes: _duration,
        streamUrl: _url.text,
      ),
      ok: 'pla_live_scheduled',
    );
    if (ok) {
      _title.clear();
      _speaker.clear();
      _desc.clear();
      _url.clear();
    }
  }

  Future<void> _start(LiveSession l) async {
    var url = l.streamUrl;
    if (url.isEmpty) {
      url =
          await _askText(
            context,
            title: context.tr('pla_start_live'),
            label: context.tr('pla_stream_link'),
            required: true,
          ) ??
          '';
      if (url.isEmpty) return;
    }
    if (mounted) {
      guarded(
        context,
        () => _n(ref).startLive(l.id, streamUrl: url),
        ok: 'pla_done',
      );
    }
  }

  Future<void> _end(LiveSession l) async {
    final url = await _askText(
      context,
      title: context.tr('pla_end_live'),
      label: context.tr('pla_recording_link_opt'),
    );
    if (url != null && mounted) {
      guarded(
        context,
        () => _n(ref).endLive(l.id, recordingUrl: url),
        ok: 'pla_done',
      );
    }
  }

  Future<void> _recording(LiveSession l) async {
    final url = await _askText(
      context,
      title: context.tr('pla_recording'),
      label: context.tr('pla_recording_link'),
      initial: l.recordingUrl.startsWith('demo:') ? '' : l.recordingUrl,
      required: true,
    );
    if (url != null && mounted) {
      guarded(context, () => _n(ref).setRecording(l.id, url), ok: 'pla_done');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lives = [...ref.watch(pulseProvider).lives]
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: context.tr('pla_new_live'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: context.tr('pla_title')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _speaker,
                decoration: InputDecoration(
                  labelText: context.tr('pla_speaker'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _desc,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: context.tr('pla_body')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: context.tr('pla_stream_link'),
                  helperText: context.tr('pla_stream_help'),
                  prefixIcon: const Icon(LucideIcons.link),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickWhen,
                    icon: const Icon(LucideIcons.calendar),
                    label: Text(liveWhen(context, _when)),
                  ),
                  DropdownButton<int>(
                    value: _duration,
                    items: [
                      for (final m in [30, 45, 60, 90, 120])
                        DropdownMenuItem(
                          value: m,
                          child: Text(context.tr('pl_minutes', args: {'n': m})),
                        ),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 60),
                  ),
                  FilledButton.icon(
                    onPressed: _schedule,
                    icon: const Icon(LucideIcons.alarmClockPlus),
                    label: Text(context.tr('pla_schedule')),
                  ),
                ],
              ),
            ],
          ),
        ),
        for (final l in lives)
          Panel(
            title: l.title,
            trailing: Pill(
              label: context.tr(switch (l.status) {
                LiveStatus.live => 'pl_live_now',
                LiveStatus.scheduled => 'pl_live_soon',
                LiveStatus.ended => 'pl_recorded',
              }),
              color: switch (l.status) {
                LiveStatus.live => AppColors.turquoise,
                LiveStatus.scheduled => AppColors.turquoise,
                LiveStatus.ended => AppColors.secondary,
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${l.speaker} · ${liveWhen(context, l.startsAt)}'),
                Text(
                  '${context.tr('pla_reminders_n', args: {'n': l.reminders.length})} · ${context.tr('pl_views', args: {'n': l.views})}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (l.status == LiveStatus.scheduled)
                      FilledButton.icon(
                        onPressed: () => _start(l),
                        icon: const Icon(LucideIcons.radio),
                        label: Text(context.tr('pla_start_live')),
                      ),
                    if (l.status == LiveStatus.live)
                      FilledButton.icon(
                        onPressed: () => _end(l),
                        icon: const Icon(LucideIcons.circleStop),
                        label: Text(context.tr('pla_end_live')),
                      ),
                    if (l.status == LiveStatus.ended)
                      OutlinedButton.icon(
                        onPressed: () => _recording(l),
                        icon: const Icon(LucideIcons.clapperboard),
                        label: Text(context.tr('pla_recording')),
                      ),
                    FilterChip(
                      label: Text(context.tr('pl_comments')),
                      selected: l.commentsOpen,
                      onSelected: (v) => guarded(
                        context,
                        () => _n(ref).setLiveInteractions(l.id, comments: v),
                      ),
                    ),
                    FilterChip(
                      label: Text(context.tr('pl_questions')),
                      selected: l.questionsOpen,
                      onSelected: (v) => guarded(
                        context,
                        () => _n(ref).setLiveInteractions(l.id, questions: v),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        if (await _confirm(context, 'pla_delete_confirm') &&
                            context.mounted) {
                          guarded(
                            context,
                            () => _n(ref).deleteLive(l.id),
                            ok: 'pla_done',
                          );
                        }
                      },
                      icon: const Icon(LucideIcons.trash2),
                      label: Text(context.tr('pla_delete')),
                    ),
                  ],
                ),
                if (l.questions.any((q) => !q.hidden)) ...[
                  const Divider(),
                  Text(
                    context.tr('pl_questions'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final q in l.questions.where((q) => !q.hidden))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Text('👍 ${q.votes.length}'),
                      title: Text(q.text),
                      subtitle: Text(q.authorName),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: context.tr('pl_answered'),
                            onPressed: () => guarded(
                              context,
                              () =>
                                  _n(ref).markAnswered(l.id, q.id, !q.answered),
                            ),
                            icon: Icon(
                              q.answered
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.circleCheck,
                              color: AppColors.vivid,
                            ),
                          ),
                          IconButton(
                            tooltip: context.tr('pla_hide'),
                            onPressed: () => guarded(
                              context,
                              () => _n(ref).hideQuestion(l.id, q.id),
                            ),
                            icon: const Icon(LucideIcons.eyeOff),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interactions: switches and latest comments
// ---------------------------------------------------------------------------

class _InteractionsTab extends ConsumerWidget {
  const _InteractionsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(pulseProvider);
    final st = s.settings;
    final latest = [...s.comments]..sort((a, b) => b.at.compareTo(a.at));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: context.tr('pla_settings'),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: st.commentsEnabled,
                onChanged: (v) => guarded(
                  context,
                  () => _n(ref).setSettings(st.copyWith(commentsEnabled: v)),
                  ok: 'pla_done',
                ),
                title: Text(context.tr('pla_allow_comments')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: st.submissionsEnabled,
                onChanged: (v) => guarded(
                  context,
                  () => _n(ref).setSettings(st.copyWith(submissionsEnabled: v)),
                  ok: 'pla_done',
                ),
                title: Text(context.tr('pla_allow_stories')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: st.likesEnabled,
                onChanged: (v) => guarded(
                  context,
                  () => _n(ref).setSettings(st.copyWith(likesEnabled: v)),
                  ok: 'pla_done',
                ),
                title: Text(context.tr('pla_allow_likes')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.globe, color: AppColors.vivid),
                title: Text(context.tr('pla_public_note')),
              ),
            ],
          ),
        ),
        Panel(
          title: context.tr('pla_latest_comments'),
          child: latest.isEmpty
              ? Text(context.tr('pl_first_comment'))
              : Column(
                  children: [
                    for (final c in latest.take(30))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          c.hidden
                              ? LucideIcons.eyeOff
                              : LucideIcons.messageSquare,
                          color: c.hidden
                              ? AppColors.grey
                              : AppColors.turquoise,
                        ),
                        title: Text(c.text),
                        subtitle: Text(
                          '${c.authorName} · ${s.post(c.postId)?.title ?? ''} · ${fmtDateTime(c.at)}',
                        ),
                        trailing: TextButton(
                          onPressed: () => guarded(
                            context,
                            () => _n(ref).setCommentHidden(c.id, !c.hidden),
                            ok: 'pla_done',
                          ),
                          child: Text(
                            context.tr(c.hidden ? 'pla_show' : 'pla_hide'),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
