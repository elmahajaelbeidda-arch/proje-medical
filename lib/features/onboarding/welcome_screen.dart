import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../../core/pulse_provider.dart';
import '../../core/theme.dart';
import '../../models/pulse.dart';
import '../../widgets/brand.dart';
import '../../widgets/ui_kit.dart' show FadeSlideIn;
import '../../widgets/visit_counter.dart';
import '../patient/home_tab.dart' show VerseText;
import '../pulse/pulse_screens.dart' show PulseEntryCard, kindIcon, kindKey;

/// First screen after the introduction: the brand, the two ways in (sign in
/// / new account), the latest news and activities, and three useful links.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget step(int i, Widget child) => FadeSlideIn(
      index: i,
      step: const Duration(milliseconds: 70),
      rise: 10,
      child: child,
    );
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            Space.l,
            Space.xl,
            Space.l,
            Space.l + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            step(0, const _BrandHeader()),
            const SizedBox(height: Space.xl),
            step(1, const _AuthButtons()),
            const SizedBox(height: Space.xl + Space.xs),
            step(2, const _NewsSection()),
            const SizedBox(height: Space.xl),
            step(3, const _QuickLinks()),
            const VisitorStatsCard(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // White disc with a soft halo: the logo stands out without a heavy
        // coloured block.
        SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0),
                    ],
                    stops: const [.55, 1],
                  ),
                ),
              ),
              Container(
                width: 124,
                height: 124,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.isDark
                      ? const []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  width: 78,
                  height: 78,
                  semanticLabel: context.tr('app_name'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xs),
        BrandName(
          fontSize: 32,
          color: AppColors.primary,
          textAlign: TextAlign.center,
        ),
        VerseText(
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: AppColors.turquoiseText,
          ),
        ),
        const SizedBox(height: Space.xxs),
        Text(
          context.tr('association'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sign in / new account
// ---------------------------------------------------------------------------

class _AuthButtons extends StatelessWidget {
  const _AuthButtons();

  static const _height = 54.0;
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  static const _label = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.isDark
                ? const []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/login');
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(_height),
              shape: _shape,
              textStyle: _label,
            ),
            icon: const Icon(LucideIcons.logIn, size: 20),
            label: Text(context.tr('login')),
          ),
        ),
        const SizedBox(height: Space.s),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.push('/role');
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(_height),
            shape: _shape,
            textStyle: _label,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: .28),
              width: 1.4,
            ),
          ),
          icon: const Icon(LucideIcons.userPlus, size: 20),
          label: Text(context.tr('create_account')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Latest news and activities (several, swipeable)
// ---------------------------------------------------------------------------

/// One card of the carousel: a post or a live talk.
class _NewsItem {
  final String label;
  final IconData icon;
  final Color tone;
  final Color toneSoft;
  final String title;
  final String body;
  final String when;
  final String route;
  const _NewsItem({
    required this.label,
    required this.icon,
    required this.tone,
    required this.toneSoft,
    required this.title,
    required this.body,
    required this.when,
    required this.route,
  });
}

class _NewsSection extends ConsumerStatefulWidget {
  const _NewsSection();
  @override
  ConsumerState<_NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends ConsumerState<_NewsSection> {
  final _controller = PageController(viewportFraction: .88);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_NewsItem> _items(PulseState s) {
    final items = <_NewsItem>[];
    final lives = s.lives.where((l) => l.status != LiveStatus.ended).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    for (final l in lives.take(1)) {
      final now = l.status == LiveStatus.live;
      final d = l.startsAt;
      items.add(
        _NewsItem(
          label: context.tr(now ? 'pl_live_now' : 'pl_live_soon'),
          icon: LucideIcons.radio,
          tone: now ? AppColors.emergencyText : AppColors.turquoiseText,
          toneSoft: now ? AppColors.emergencySoft : AppColors.secondary,
          title: l.title,
          body: l.speaker,
          when:
              '${d.day}/${d.month} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
          route: '/pulse/live/${l.id}',
        ),
      );
    }
    for (final p in s.publicFeed.take(5 - items.length)) {
      final (tone, soft) = switch (p.kind) {
        PulseKind.news => (AppColors.primary, AppColors.secondary),
        PulseKind.achievement => (
          AppColors.reviewingText,
          AppColors.reviewingSoft,
        ),
        PulseKind.media => (AppColors.turquoiseText, AppColors.secondary),
        PulseKind.story => (AppColors.answeredText, AppColors.answeredSoft),
      };
      items.add(
        _NewsItem(
          label: context.tr(kindKey(p.kind)),
          icon: kindIcon(p.kind),
          tone: tone,
          toneSoft: soft,
          title: p.title,
          body: p.body,
          when: context.timeAgo(p.date),
          route: '/pulse/post/${p.id}',
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(ref.watch(pulseProvider));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('pl_name'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    context.tr('pl_slogan'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/pulse'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('see_all')),
                  const SizedBox(width: 2),
                  const Icon(LucideIcons.chevronLeftDir, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s),
        if (items.isEmpty)
          const PulseEntryCard()
        else ...[
          // The cards reach the screen edges, so the next one peeks in.
          SizedBox(
            height: 168,
            child: OverflowBox(
              maxWidth: MediaQuery.sizeOf(context).width,
              child: PageView.builder(
                controller: _controller,
                padEnds: false,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: i == 0 ? Space.l : Space.xs,
                    end: i == items.length - 1 ? Space.l : 0,
                    bottom: Space.xs,
                  ),
                  child: _NewsCard(items[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: Motion.normal,
                  curve: Motion.curve,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard(this.item);
  final _NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      shadowColor: const Color(0x14000000),
      elevation: AppColors.isDark ? 0 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.toneSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 14, color: item.tone),
                        const SizedBox(width: 5),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.tone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.when,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: Space.s),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.grey,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    context.tr('details'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.turquoiseText,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    LucideIcons.chevronLeftDir,
                    size: 16,
                    color: AppColors.turquoiseText,
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

// ---------------------------------------------------------------------------
// Useful links
// ---------------------------------------------------------------------------

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final links = [
      (LucideIcons.users, 'about_association', '/about'),
      (LucideIcons.scanQrCode, 'mc_verify_link', '/verify-card'),
      (LucideIcons.shieldCheck, 'disclaimer', '/disclaimer'),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < links.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.s),
            Expanded(
              child: _QuickLink(
                icon: links[i].$1,
                label: context.tr(links[i].$2),
                onTap: () => context.push(links[i].$3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.xs,
            vertical: Space.s,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(height: Space.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
