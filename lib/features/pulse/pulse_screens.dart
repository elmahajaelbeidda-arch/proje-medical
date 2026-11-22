import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/pulse_provider.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/pulse.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../../widgets/visit_counter.dart';

// ---------------------------------------------------------------------------
// «نبض شفاء» — open to everyone. Reading needs no account; liking,
// commenting, asking and sharing a story need to be signed in.
// ---------------------------------------------------------------------------

const _publicSite = 'https://elmahajaelbeidda-arch.github.io/proje-medical/';

/// The signed-in member, or null for a visitor.
final pulseActorProvider = Provider<PulseActor?>((ref) {
  final a = ref.watch(authProvider);
  if (!a.loggedIn) return null;
  return PulseActor(a.userId, a.displayName);
});

/// Runs [action] for a member, or invites a visitor to sign in.
void asMember(
  BuildContext context,
  WidgetRef ref,
  void Function(PulseActor who) action,
) {
  final who = ref.read(pulseActorProvider);
  if (who != null) return action(who);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.mint,
              child: Icon(
                Icons.favorite_outline,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctx.tr('pl_join_title'),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(ctx.tr('pl_join_body'), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/role');
              },
              icon: const Icon(Icons.login),
              label: Text(ctx.tr('pl_join_btn')),
            ),
          ],
        ),
      ),
    ),
  );
}

String postLink(String id) {
  final base = Uri.base;
  final site = (base.scheme == 'http' || base.scheme == 'https')
      ? '${base.origin}${base.path}'
      : _publicSite;
  return '$site#/pulse/post/$id';
}

Future<void> sharePost(BuildContext context, WidgetRef ref, PulsePost p) async {
  await Clipboard.setData(ClipboardData(text: '${p.title}\n${postLink(p.id)}'));
  ref.read(pulseProvider.notifier).countShare(p.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('pl_link_copied'))));
  }
}

/// Opens a video, stream or recording link. Demo links ("demo:") explain
/// where the video will play once the association's channel is linked.
Future<void> openPulseLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  if (url.isEmpty || url.startsWith('demo:')) {
    messenger.showSnackBar(SnackBar(content: Text(context.tr('pl_demo_link'))));
    return;
  }
  final failed = context.tr('pl_link_failed');
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}

IconData pulseIcon(String key) => switch (key) {
  'campaign' => Icons.campaign_outlined,
  'group' => Icons.groups_2_outlined,
  'medication' => Icons.medication_outlined,
  'video' => Icons.smart_display_outlined,
  'school' => Icons.school_outlined,
  'map' => Icons.map_outlined,
  'heart' => Icons.volunteer_activism_outlined,
  'event' => Icons.event_outlined,
  _ => Icons.photo_outlined,
};

const _tones = [
  [AppColors.primary, AppColors.vivid],
  [AppColors.turquoise, AppColors.emeraldTeal],
  [AppColors.emeraldTeal, AppColors.primary],
  [AppColors.emeraldTeal, AppColors.turquoise],
];

String kindKey(PulseKind k) => 'pl_kind_${k.name}';
String topicKey(NewsTopic t) => 'pl_topic_${t.name}';

IconData kindIcon(PulseKind k) => switch (k) {
  PulseKind.news => Icons.newspaper_outlined,
  PulseKind.story => Icons.auto_stories_outlined,
  PulseKind.media => Icons.photo_library_outlined,
  PulseKind.achievement => Icons.emoji_events_outlined,
};

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

enum PulseTab { all, news, stories, media, live, achievements }

class PulseHomeScreen extends ConsumerStatefulWidget {
  const PulseHomeScreen({super.key});
  @override
  ConsumerState<PulseHomeScreen> createState() => _PulseHomeScreenState();
}

class _PulseHomeScreenState extends ConsumerState<PulseHomeScreen> {
  PulseTab _tab = PulseTab.all;

  bool _matches(PulsePost p) => switch (_tab) {
    PulseTab.all => true,
    PulseTab.news => p.kind == PulseKind.news,
    PulseTab.stories => p.kind == PulseKind.story,
    PulseTab.media => p.kind == PulseKind.media || p.media.isNotEmpty,
    PulseTab.achievements => p.kind == PulseKind.achievement,
    PulseTab.live => false,
  };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pulseProvider);
    final who = ref.watch(pulseActorProvider);
    final feed = s.publicFeed.where(_matches).toList();
    final liveNow = s.lives.where((l) => l.status == LiveStatus.live).toList();
    final upcoming =
        s.lives.where((l) => l.status == LiveStatus.scheduled).toList()
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final impact = s.publicFeed
        .where((p) => p.kind == PulseKind.achievement && p.stats.isNotEmpty)
        .firstOrNull;

    return Scaffold(
      floatingActionButton: s.settings.submissionsEnabled
          ? FloatingActionButton.extended(
              onPressed: () =>
                  asMember(context, ref, (_) => context.push('/pulse/new')),
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.tr('pl_share_story')),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 228,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.primary,
            title: Text(context.tr('pl_title')),
            actions: [
              const Center(child: VisitorLivePill(onDark: true)),
              const SizedBox(width: 4),
              if (who != null)
                IconButton(
                  tooltip: context.tr('pl_my_posts'),
                  onPressed: () => context.push('/pulse/mine'),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _PulseHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (who == null) const _GuestBanner(),
                  for (final l in liveNow) _LiveBanner(l),
                  if (liveNow.isEmpty && upcoming.isNotEmpty)
                    _LiveBanner(upcoming.first),
                  if (impact != null) _ImpactStrip(impact),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(
              selected: _tab,
              onSelected: (t) => setState(() => _tab = t),
            ),
          ),
          if (_tab == PulseTab.live)
            const SliverToBoxAdapter(child: _LiveList())
          else if (feed.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.forum_outlined,
                message: context.tr('pl_empty'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList.separated(
                itemCount: feed.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => PostCard(post: feed[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseHeader extends StatelessWidget {
  const _PulseHeader();
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [AppColors.primary, AppColors.emeraldTeal, AppColors.turquoise],
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _PulseLinePainter())),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  context.tr('pl_name'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('pl_slogan'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Faint heartbeat line behind the header (the logo's pulse).
class _PulseLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.42;
    final w = size.width;
    final p = Path()
      ..moveTo(0, y)
      ..lineTo(w * 0.34, y)
      ..lineTo(w * 0.39, y - 34)
      ..lineTo(w * 0.45, y + 40)
      ..lineTo(w * 0.5, y - 18)
      ..lineTo(w * 0.54, y)
      ..lineTo(w, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(w * 0.88, size.height * 0.2), 70, dot);
    canvas.drawCircle(Offset(w * 0.08, size.height * 0.85), 50, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuestBanner extends ConsumerWidget {
  const _GuestBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    color: AppColors.secondary,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('pl_guest_note'))),
          TextButton(
            onPressed: () => context.push('/role'),
            child: Text(context.tr('pl_join_btn')),
          ),
        ],
      ),
    ),
  );
}

class _LiveBanner extends ConsumerWidget {
  const _LiveBanner(this.live);
  final LiveSession live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = live.status == LiveStatus.live;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/pulse/live/${live.id}'),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLive
                  ? const [AppColors.turquoise, AppColors.emeraldTeal]
                  : const [Colors.white, AppColors.secondary],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isLive ? Colors.white : AppColors.turquoise,
                child: Icon(
                  isLive ? Icons.sensors : Icons.event_available_outlined,
                  color: isLive ? AppColors.turquoise : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LiveBadge(live),
                    const SizedBox(height: 4),
                    Text(
                      live.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: isLive ? Colors.white : AppColors.primary,
                      ),
                    ),
                    Text(
                      isLive ? live.speaker : liveWhen(context, live.startsAt),
                      style: TextStyle(
                        color: isLive ? Colors.white : AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isLive ? Colors.white : AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String liveWhen(BuildContext context, DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
}

class LiveBadge extends StatelessWidget {
  const LiveBadge(this.live, {super.key});
  final LiveSession live;
  @override
  Widget build(BuildContext context) {
    final (key, color) = switch (live.status) {
      LiveStatus.live => ('pl_live_now', Colors.white),
      LiveStatus.scheduled => ('pl_live_soon', AppColors.turquoise),
      LiveStatus.ended => ('pl_recorded', AppColors.vivid),
    };
    final onLive = live.status == LiveStatus.live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: onLive ? Colors.white24 : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            onLive
                ? Icons.circle
                : (live.status == LiveStatus.ended
                      ? Icons.play_circle_outline
                      : Icons.schedule),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            context.tr(key),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStrip extends StatelessWidget {
  const _ImpactStrip(this.post);
  final PulsePost post;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.turquoise,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              context.tr('pl_impact'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: post.stats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _StatTile(post.stats[i], width: 132),
          ),
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.stat, {this.width});
  final PulseStat stat;
  final double? width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          stat.value,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.vivid,
          ),
        ),
        Text(
          stat.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: AppColors.grey),
        ),
      ],
    ),
  );
}

class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.selected, required this.onSelected});
  final PulseTab selected;
  final ValueChanged<PulseTab> onSelected;

  @override
  double get minExtent => 58;
  @override
  double get maxExtent => 58;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    IconData icon(PulseTab t) => switch (t) {
      PulseTab.all => Icons.dynamic_feed_outlined,
      PulseTab.news => Icons.newspaper_outlined,
      PulseTab.stories => Icons.auto_stories_outlined,
      PulseTab.media => Icons.photo_library_outlined,
      PulseTab.live => Icons.sensors,
      PulseTab.achievements => Icons.emoji_events_outlined,
    };
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final t in PulseTab.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: ChoiceChip(
                avatar: Icon(icon(t), size: 18),
                label: Text(context.tr('pl_tab_${t.name}')),
                selected: selected == t,
                onSelected: (_) => onSelected(t),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeader old) => old.selected != selected;
}

// ---------------------------------------------------------------------------
// Post card and details
// ---------------------------------------------------------------------------

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post, this.full = false});
  final PulsePost post;
  final bool full;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(pulseProvider);
    final who = ref.watch(pulseActorProvider);
    final p = s.post(post.id) ?? post;
    final liked = who != null && p.likes.contains(who.id);
    final comments = s.visibleComments(p.id).length;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: full ? null : () => context.push('/pulse/post/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostHeader(p),
              const SizedBox(height: 10),
              Text(
                p.title,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              if (p.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  p.body,
                  maxLines: full ? null : 4,
                  overflow: full ? null : TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
              if (p.stats.isNotEmpty) ...[
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.1,
                  children: [for (final st in p.stats) _StatTile(st)],
                ),
              ],
              if (p.media.isNotEmpty) ...[
                const SizedBox(height: 10),
                MediaGrid(p.media, full: full),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  if (s.settings.likesEnabled)
                    _Action(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? AppColors.vivid : null,
                      label: '${p.likes.length}',
                      tooltip: context.tr('pl_like'),
                      onTap: () => asMember(
                        context,
                        ref,
                        (w) => ref
                            .read(pulseProvider.notifier)
                            .toggleLike(p.id, w),
                      ),
                    ),
                  _Action(
                    icon: Icons.mode_comment_outlined,
                    label: '$comments',
                    tooltip: context.tr('pl_comments'),
                    onTap: full
                        ? null
                        : () => context.push('/pulse/post/${p.id}'),
                  ),
                  _Action(
                    icon: Icons.share_outlined,
                    label: '${p.shares}',
                    tooltip: context.tr('pl_share'),
                    onTap: () => sharePost(context, ref, p),
                  ),
                  const Spacer(),
                  if (full)
                    IconButton(
                      tooltip: context.tr('pl_report'),
                      onPressed: () => asMember(context, ref, (w) {
                        ref.read(pulseProvider.notifier).reportPost(p.id, w);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('pl_reported'))),
                        );
                      }),
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader(this.p);
  final PulsePost p;
  @override
  Widget build(BuildContext context) {
    final name = p.fromTeam
        ? context.tr('association')
        : (p.anonymous || p.authorName.isEmpty)
        ? context.tr('pl_anonymous')
        : p.authorName;
    final label = p.kind == PulseKind.news && p.topic != null
        ? context.tr(topicKey(p.topic!))
        : context.tr(kindKey(p.kind));
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: p.fromTeam ? AppColors.secondary : AppColors.patient,
          child: p.fromTeam
              ? Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset('assets/images/logo_icon.png'),
                )
              : Icon(
                  p.anonymous
                      ? Icons.person_off_outlined
                      : Icons.person_outline,
                  color: AppColors.turquoise,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                context.timeAgo(p.date),
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        if (p.pinned)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 6),
            child: Icon(Icons.push_pin, size: 18, color: AppColors.turquoise),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(kindIcon(p.kind), size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.tooltip,
    this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color ?? AppColors.grey),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color ?? AppColors.grey)),
          ],
        ),
      ),
    ),
  );
}

class MediaGrid extends StatelessWidget {
  const MediaGrid(this.media, {super.key, this.full = false});
  final List<PulseMedia> media;
  final bool full;

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return AspectRatio(aspectRatio: 16 / 9, child: MediaTile(media.first));
    }
    final shown = full ? media : media.take(4).toList();
    final more = media.length - shown.length;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (var i = 0; i < shown.length; i++)
          MediaTile(shown[i], more: i == shown.length - 1 ? more : 0),
      ],
    );
  }
}

class MediaTile extends StatelessWidget {
  const MediaTile(this.m, {super.key, this.more = 0});
  final PulseMedia m;
  final int more;

  @override
  Widget build(BuildContext context) {
    final bytes = m.attachment?.bytes;
    final tone = _tones[m.tone % _tones.length];
    final Widget base = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover)
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: tone,
              ),
            ),
            child: Center(
              child: Icon(
                pulseIcon(m.icon),
                color: Color(0xB3FFFFFF),
                size: 46,
              ),
            ),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showMediaViewer(context, m),
          child: Stack(
            fit: StackFit.expand,
            children: [
              base,
              if (m.type == PulseMediaType.video)
                const Center(
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                ),
              if (m.caption.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99263B36)],
                      ),
                    ),
                    child: Text(
                      m.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              if (more > 0)
                Container(
                  color: Color(0x73263B36),
                  alignment: Alignment.center,
                  child: Text(
                    '+$more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showMediaViewer(BuildContext context, PulseMedia m) {
  if (m.type == PulseMediaType.video) {
    openPulseLink(context, m.url);
    return;
  }
  final bytes = m.attachment?.bytes;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(m.caption.isEmpty ? ctx.tr('pl_photo') : m.caption),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Flexible(
            child: bytes != null
                ? InteractiveViewer(maxScale: 5, child: Image.memory(bytes))
                : AspectRatio(aspectRatio: 4 / 3, child: MediaTile(m)),
          ),
        ],
      ),
    ),
  );
}

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() => asMember(context, ref, (who) {
    try {
      ref.read(pulseProvider.notifier).addComment(widget.id, who, _ctrl.text);
      _ctrl.clear();
      FocusScope.of(context).unfocus();
    } on StateError {
      _snack('pl_comments_closed');
    } on ArgumentError {
      _snack('pl_comment_invalid');
    }
  });

  void _snack(String key) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(key))));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pulseProvider);
    final p = s.post(widget.id);
    if (p == null || !p.isPublic) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('pl_name'))),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('pl_not_found'),
        ),
      );
    }
    final comments = s.visibleComments(p.id);
    final open = s.settings.commentsEnabled && p.commentsOpen;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(kindKey(p.kind)))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PostCard(post: p, full: true),
                const SizedBox(height: 16),
                Text(
                  '${context.tr('pl_comments')} (${comments.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      context.tr(
                        open ? 'pl_first_comment' : 'pl_comments_closed',
                      ),
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  ),
                for (final c in comments) CommentTile(c),
              ],
            ),
          ),
          if (open)
            _Composer(
              controller: _ctrl,
              hint: context.tr('pl_write_comment'),
              onSend: _send,
              maxLength: 500,
            ),
        ],
      ),
    );
  }
}

class CommentTile extends ConsumerWidget {
  const CommentTile(this.c, {super.key});
  final PulseComment c;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.secondary,
          child: Text(
            c.authorName.isEmpty ? '؟' : c.authorName.characters.first,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      context.timeAgo(c.at),
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                    InkWell(
                      onTap: () => asMember(context, ref, (w) {
                        ref.read(pulseProvider.notifier).reportComment(c.id, w);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('pl_reported'))),
                        );
                      }),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Icon(
                          Icons.flag_outlined,
                          size: 16,
                          semanticLabel: context.tr('pl_report'),
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(c.text, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.maxLength,
  });
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final int maxLength;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: context.tr('send'),
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Live and recorded talks
// ---------------------------------------------------------------------------

class _LiveList extends ConsumerWidget {
  const _LiveList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lives = ref.watch(pulseProvider).lives;
    final current = lives.where((l) => l.status != LiveStatus.ended).toList()
      ..sort((a, b) {
        if (a.status != b.status) return a.status == LiveStatus.live ? -1 : 1;
        return a.startsAt.compareTo(b.startsAt);
      });
    final recorded = lives.where((l) => l.hasRecording).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    Widget title(String k) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        context.tr(k),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title('pl_live_upcoming'),
          if (current.isEmpty)
            Text(
              context.tr('pl_no_live'),
              style: const TextStyle(color: AppColors.grey),
            ),
          for (final l in current) _LiveBanner(l),
          title('pl_recordings'),
          if (recorded.isEmpty)
            Text(
              context.tr('pl_no_recording'),
              style: const TextStyle(color: AppColors.grey),
            ),
          for (final l in recorded) _RecordingTile(l),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile(this.live);
  final LiveSession live;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/pulse/live/${live.id}'),
      child: Row(
        children: [
          Container(
            width: 108,
            height: 84,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.turquoise],
              ),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    live.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${live.speaker}\n${context.tr('pl_views', args: {'n': live.views})} · ${context.tr('pl_minutes', args: {'n': live.durationMinutes})}',
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
}

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final _chat = TextEditingController();
  final _question = TextEditingController();
  int _tab = 0; // 0 comments, 1 questions

  @override
  void dispose() {
    _chat.dispose();
    _question.dispose();
    super.dispose();
  }

  void _snack(String key) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(key))));

  void _watch(LiveSession l) {
    ref.read(pulseProvider.notifier).watchLive(l.id);
    openPulseLink(
      context,
      l.status == LiveStatus.ended ? l.recordingUrl : l.streamUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(pulseProvider);
    final who = ref.watch(pulseActorProvider);
    final l = s.live(widget.id);
    if (l == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('pl_not_found'),
        ),
      );
    }
    final chat = (s.liveChat[l.id] ?? const <PulseComment>[])
        .where((c) => !c.hidden)
        .toList();
    final questions = l.questions.where((q) => !q.hidden).toList()
      ..sort((a, b) => b.votes.length.compareTo(a.votes.length));
    final reminded = who != null && l.reminders.contains(who.id);
    final chatOpen =
        s.settings.commentsEnabled &&
        l.commentsOpen &&
        l.status == LiveStatus.live;
    final askOpen = l.questionsOpen && l.status != LiveStatus.ended;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pl_tab_live'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Player area: the video plays on the streaming service.
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Material(
                      child: InkWell(
                        onTap: l.status == LiveStatus.scheduled
                            ? null
                            : () => _watch(l),
                        child: Ink(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.vivid,
                                AppColors.turquoise,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PulseLinePainter(),
                                ),
                              ),
                              PositionedDirectional(
                                top: 12,
                                start: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: l.status == LiveStatus.live
                                        ? Colors.transparent
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: LiveBadge(l),
                                ),
                              ),
                              Center(
                                child: l.status == LiveStatus.scheduled
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            color: Colors.white,
                                            size: 42,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            liveWhen(context, l.startsAt),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const CircleAvatar(
                                        radius: 34,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: AppColors.primary,
                                          size: 46,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_outlined,
                      size: 18,
                      color: AppColors.turquoise,
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l.speaker)),
                  ],
                ),
                if (l.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(l.description, style: const TextStyle(height: 1.6)),
                ],
                const SizedBox(height: 12),
                if (l.status == LiveStatus.scheduled)
                  OutlinedButton.icon(
                    onPressed: () => asMember(
                      context,
                      ref,
                      (w) => ref
                          .read(pulseProvider.notifier)
                          .toggleReminder(l.id, w),
                    ),
                    icon: Icon(
                      reminded
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                    ),
                    label: Text(
                      context.tr(reminded ? 'pl_reminder_on' : 'pl_remind_me'),
                    ),
                  )
                else if (l.status == LiveStatus.live || l.hasRecording)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () => _watch(l),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      context.tr(
                        l.status == LiveStatus.live
                            ? 'pl_watch_live'
                            : 'pl_watch_recording',
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(
                      value: 0,
                      icon: const Icon(Icons.forum_outlined),
                      label: Text(
                        '${context.tr('pl_comments')} (${chat.length})',
                      ),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: const Icon(Icons.help_outline),
                      label: Text(
                        '${context.tr('pl_questions')} (${questions.length})',
                      ),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (v) => setState(() => _tab = v.first),
                ),
                const SizedBox(height: 12),
                if (_tab == 0) ...[
                  if (chat.isEmpty)
                    Text(
                      context.tr(
                        l.status == LiveStatus.scheduled
                            ? 'pl_chat_when_live'
                            : 'pl_first_comment',
                      ),
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  for (final c in chat) CommentTile(c),
                ] else ...[
                  if (questions.isEmpty)
                    Text(
                      context.tr('pl_no_questions'),
                      style: const TextStyle(color: AppColors.grey),
                    ),
                  for (final q in questions)
                    _QuestionTile(liveId: l.id, q: q, mine: who),
                ],
              ],
            ),
          ),
          if (_tab == 0 && chatOpen)
            _Composer(
              controller: _chat,
              hint: context.tr('pl_write_comment'),
              maxLength: 300,
              onSend: () => asMember(context, ref, (w) {
                try {
                  ref
                      .read(pulseProvider.notifier)
                      .addLiveMessage(l.id, w, _chat.text);
                  _chat.clear();
                } on StateError {
                  _snack('pl_comments_closed');
                } on ArgumentError {
                  _snack('pl_comment_invalid');
                }
              }),
            ),
          if (_tab == 1 && askOpen)
            _Composer(
              controller: _question,
              hint: context.tr('pl_ask_hint'),
              maxLength: 300,
              onSend: () => asMember(context, ref, (w) {
                try {
                  ref
                      .read(pulseProvider.notifier)
                      .askQuestion(l.id, w, _question.text);
                  _question.clear();
                  _snack('pl_question_sent');
                } on StateError {
                  _snack('pl_questions_closed');
                } on ArgumentError {
                  _snack('pl_question_invalid');
                }
              }),
            ),
        ],
      ),
    );
  }
}

class _QuestionTile extends ConsumerWidget {
  const _QuestionTile({
    required this.liveId,
    required this.q,
    required this.mine,
  });
  final String liveId;
  final LiveQuestion q;
  final PulseActor? mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voted = mine != null && q.votes.contains(mine!.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: q.answered
            ? const Icon(Icons.check_circle, color: AppColors.vivid)
            : const Icon(Icons.help_outline, color: AppColors.turquoise),
        title: Text(q.text),
        subtitle: Text(
          q.answered
              ? '${q.authorName} · ${context.tr('pl_answered')}'
              : q.authorName,
        ),
        trailing: TextButton.icon(
          onPressed: () => asMember(
            context,
            ref,
            (w) =>
                ref.read(pulseProvider.notifier).voteQuestion(liveId, q.id, w),
          ),
          icon: Icon(
            voted ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 18,
          ),
          label: Text('${q.votes.length}'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share a story (reviewed before publication)
// ---------------------------------------------------------------------------

class SubmitStoryScreen extends ConsumerStatefulWidget {
  const SubmitStoryScreen({super.key});
  @override
  ConsumerState<SubmitStoryScreen> createState() => _SubmitStoryScreenState();
}

class _SubmitStoryScreenState extends ConsumerState<SubmitStoryScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _photos = <Attachment>[];
  bool _anonymous = false;
  bool _noPatientData = false;
  bool _photoConsent = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await pickAttachments(context, PickSource.gallery);
    final images = picked.where((a) => a.kind == AttachmentKind.image);
    setState(
      () => _photos.addAll(images.take(math.max(0, 4 - _photos.length))),
    );
  }

  void _submit(PulseActor who) {
    if (!_form.currentState!.validate()) return;
    if (!_noPatientData || (_photos.isNotEmpty && !_photoConsent)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('pl_confirm_privacy'))));
      return;
    }
    ref
        .read(pulseProvider.notifier)
        .submitStory(
          who: who,
          title: _title.text,
          body: _body.text,
          anonymous: _anonymous,
          privacyConfirmed: true,
          media: [
            for (final a in _photos)
              PulseMedia(type: PulseMediaType.image, attachment: a),
          ],
        );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.hourglass_top,
          color: AppColors.turquoise,
          size: 40,
        ),
        title: Text(ctx.tr('pl_sent_title')),
        content: Text(ctx.tr('pl_sent_body'), textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text(ctx.tr('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final who = ref.watch(pulseActorProvider);
    final enabled = ref.watch(
      pulseProvider.select((s) => s.settings.submissionsEnabled),
    );
    if (who == null || !enabled) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('pl_share_story'))),
        body: EmptyState(
          icon: Icons.lock_outline,
          message: context.tr(
            who == null ? 'pl_join_body' : 'pl_submissions_off',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pl_share_story'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InfoCard(
              title: context.tr('pl_rules_title'),
              icon: Icons.shield_outlined,
              child: Text(
                context.tr('pl_rules_body'),
                style: const TextStyle(height: 1.7),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              maxLength: 90,
              decoration: InputDecoration(
                labelText: context.tr('pl_story_title'),
              ),
              validator: (v) => (v ?? '').trim().length < 4
                  ? context.tr('pl_title_short')
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _body,
              maxLength: 3000,
              minLines: 6,
              maxLines: 14,
              decoration: InputDecoration(
                labelText: context.tr('pl_story_body'),
                alignLabelWithHint: true,
              ),
              validator: (v) => (v ?? '').trim().length < 30
                  ? context.tr('pl_body_short')
                  : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _photos)
                  Stack(
                    children: [
                      AttachmentThumb(a, size: 84),
                      PositionedDirectional(
                        top: 0,
                        end: 0,
                        child: InkWell(
                          onTap: () => setState(() => _photos.remove(a)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0x99263B36),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_photos.length < 4)
                  OutlinedButton.icon(
                    onPressed: _addPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(context.tr('pl_add_photos')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text(context.tr('pl_post_anonymously')),
              subtitle: Text(context.tr('pl_post_anonymously_desc')),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _noPatientData,
              onChanged: (v) => setState(() => _noPatientData = v ?? false),
              title: Text(context.tr('pl_privacy_check')),
            ),
            if (_photos.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _photoConsent,
                onChanged: (v) => setState(() => _photoConsent = v ?? false),
                title: Text(context.tr('pl_photo_consent')),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () => _submit(who),
              icon: const Icon(Icons.send_rounded),
              label: Text(context.tr('pl_send_review')),
            ),
          ],
        ),
      ),
    );
  }
}

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pulseProvider);
    final who = ref.watch(pulseActorProvider);
    final mine = who == null
        ? const <PulsePost>[]
        : ref.read(pulseProvider.notifier).mySubmissions(who.id);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pl_my_posts'))),
      body: mine.isEmpty
          ? EmptyState(
              icon: Icons.auto_stories_outlined,
              message: context.tr('pl_no_posts'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: mine.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = mine[i];
                final (key, color, icon) = switch (p.status) {
                  PulseStatus.pending => (
                    'pl_st_pending',
                    AppColors.turquoise,
                    Icons.hourglass_top,
                  ),
                  PulseStatus.published => (
                    'pl_st_published',
                    AppColors.vivid,
                    Icons.check_circle_outline,
                  ),
                  PulseStatus.rejected => (
                    'pl_st_rejected',
                    AppColors.error,
                    Icons.info_outline,
                  ),
                  PulseStatus.hidden => (
                    'pl_st_hidden',
                    AppColors.grey,
                    Icons.visibility_off_outlined,
                  ),
                };
                return Card(
                  child: ListTile(
                    onTap: p.isPublic
                        ? () => context.push('/pulse/post/${p.id}')
                        : null,
                    leading: Icon(icon, color: color),
                    title: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      p.status == PulseStatus.rejected &&
                              p.rejectReason.isNotEmpty
                          ? '${context.tr(key)} — ${p.rejectReason}'
                          : context.tr(key),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Entry card shown on home screens and to visitors.
class PulseEntryCard extends StatelessWidget {
  const PulseEntryCard({super.key});
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: () => context.push('/pulse'),
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [
              AppColors.primary,
              AppColors.emeraldTeal,
              AppColors.turquoise,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PulseLinePainter())),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.diversity_1_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('pl_name'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('pl_slogan'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
