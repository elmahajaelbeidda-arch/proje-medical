import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_provider.dart';
import '../../core/blood_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/admin.dart';
import '../../models/models.dart';
import '../../widgets/common.dart' show AccountReviewBanner;
import '../../widgets/ui_kit.dart';
import '../../widgets/visit_counter.dart';
import '../summons/summons_screens.dart' show SummonsBanner;

// ---------------------------------------------------------------------------
// Patient home: clean iOS / Material 3 style, right to left.
//   1. greeting + bell   2. about card   3. ask for a consultation
//   4. quick services    5. announcements   6. latest consultations
//   then the other services, in the same card style.
// ---------------------------------------------------------------------------

const _side = 16.0; // page margin
const _gap = 20.0; // between sections

/// The Quranic verse shown on the about card, with full diacritics.
const shifaVerse = '﴿وَمَنْ أَحْيَاهَا فَكَأَنَّمَا أَحْيَا النَّاسَ جَمِيعًا﴾';

/// "Forward" chevron / arrow for the reading direction.
IconData forwardChevron(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? LucideIcons.chevronLeft
    : LucideIcons.chevronRight;
IconData forwardArrow(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? LucideIcons.arrowLeft
    : LucideIcons.arrowRight;

class PatientHomeTab extends ConsumerWidget {
  const PatientHomeTab({
    super.key,
    required this.onSeeConsultations,
    required this.onOpenBlood,
    this.onOpenDoctors,
  });
  final VoidCallback onSeeConsultations;
  final VoidCallback onOpenBlood;
  final VoidCallback? onOpenDoctors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final mine = ref
        .watch(consultationsProvider)
        .where((c) => c.patientId == MockData.currentPatientId)
        .toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(_side, 0, _side, 28),
        children: _stagger([
          const _TopBar(),
          const SizedBox(height: 8),
          const AccountReviewBanner(),
          const AboutAppCard(),
          if (settings.enabled(AppSection.consultations)) ...[
            const SizedBox(height: 16),
            const _ConsultCard(),
          ],
          const SizedBox(height: _gap),
          _SectionTitle(context.tr('quick_services')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickService(
                  icon: LucideIcons.siren,
                  label: context.tr('qs_emergency'),
                  color: AppColors.emergency,
                  background: AppColors.emergencySoft,
                  onTap: () => showEmergencySheet(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickService(
                  icon: LucideIcons.stethoscope,
                  label: context.tr('nav_doctors'),
                  color: AppColors.turquoise,
                  background: AppColors.secondary,
                  onTap: onOpenDoctors ?? () => context.push('/care-map'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickService(
                  icon: LucideIcons.clipboardList,
                  label: context.tr('nav_consultations'),
                  color: AppColors.primary,
                  background: AppColors.secondary,
                  onTap: onSeeConsultations,
                ),
              ),
            ],
          ),
          const _Announcements(),
          if (settings.enabled(AppSection.summons)) const SummonsBanner(),
          if (mine.isNotEmpty) ...[
            const SizedBox(height: _gap),
            Row(
              children: [
                Expanded(
                  child: _SectionTitle(context.tr('home_last_consults')),
                ),
                TextButton(
                  onPressed: onSeeConsultations,
                  child: Text(context.tr('see_all')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final c in mine.take(2)) ...[
              _ConsultationRow(c),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: _gap - 10),
          _SectionTitle(context.tr('home_more_services')),
          const SizedBox(height: 10),
          ServiceTile(
            icon: LucideIcons.heartHandshake,
            title: context.tr('pl_name'),
            subtitle: context.tr('pl_slogan'),
            onTap: () => context.push('/pulse'),
          ),
          ServiceTile(
            icon: LucideIcons.mapPin,
            title: context.tr('cm_title'),
            subtitle: context.tr('cm_card_desc'),
            onTap: () => context.push('/care-map'),
          ),
          if (settings.enabled(AppSection.psych))
            ServiceTile(
              icon: LucideIcons.brain,
              title: context.tr('psych_title'),
              subtitle: context.tr('psych_card_desc'),
              onTap: () => context.push('/patient/psych'),
            ),
          if (settings.enabled(AppSection.blood)) ...[
            _BloodRequestsTile(),
            ServiceTile(
              icon: LucideIcons.handHeart,
              title: context.tr('blood_donation'),
              subtitle: context.tr('become_donor_desc'),
              onTap: onOpenBlood,
            ),
          ],
          if (settings.enabled(AppSection.aid))
            ServiceTile(
              icon: LucideIcons.mapPinPlus,
              title: context.tr('aid_title'),
              subtitle: context.tr('aid_home_desc'),
              onTap: () => context.push('/aid'),
            ),
          const VisitorStatsCard(),
          const SizedBox(height: _gap - 10),
          _SectionTitle(context.tr('health_tips')),
          const SizedBox(height: 10),
          const _Tips(),
        ]),
      ),
    );
  }
}

/// Sections appear one after the other when the screen opens.
List<Widget> _stagger(List<Widget> items) => [
  for (var i = 0; i < items.length; i++) FadeSlideIn(index: i, child: items[i]),
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.4,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 1. Top bar
// ---------------------------------------------------------------------------

class _TopBar extends ConsumerWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final hasNews =
        MockData.notifications(auth.isDoctor).isNotEmpty ||
        ref.watch(adminProvider.select((s) => s.messages.isNotEmpty));
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('hello')} ${auth.displayName.split(' ').first} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                ),
                Text(
                  context.tr('how_feel'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: context.tr('notifications'),
            child: InkResponse(
              onTap: () => context.push('/notifications'),
              radius: 26,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.shadow,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(LucideIcons.bell, size: 22, color: AppColors.text),
                      if (hasNews)
                        PositionedDirectional(
                          top: 9,
                          end: 10,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: AppColors.emergency,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. About card (short; the full text is on the «about the app» page)
// ---------------------------------------------------------------------------

class AboutAppCard extends StatelessWidget {
  const AboutAppCard({super.key});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PulseBackdrop())),
          // Thin green line on the start side (right in Arabic).
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_icon.png',
                      width: 48,
                      height: 48,
                      semanticLabel: context.tr('app_name'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('app_name'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.5,
                            ),
                          ),
                          Text(
                            shifaVerse,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.turquoiseText,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('about_short'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.6,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.push('/about-app'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('learn_more'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          rtl ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Very light heartbeat line behind the about card (8 %).
class _PulseBackdrop extends CustomPainter {
  const _PulseBackdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, y = h * .55;
    final p = Path()
      ..moveTo(0, y)
      ..lineTo(w * .30, y)
      ..lineTo(w * .36, y - h * .28)
      ..lineTo(w * .43, y + h * .30)
      ..lineTo(w * .49, y - h * .12)
      ..lineTo(w * .53, y)
      ..lineTo(w, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = AppColors.primary.withValues(alpha: .08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 3. Ask for a consultation
// ---------------------------------------------------------------------------

class _ConsultCard extends StatelessWidget {
  const _ConsultCard();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 160),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('request_consultation'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('request_consultation_desc'),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: .85),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/patient/new');
                },
                icon: const Icon(LucideIcons.plus, size: 20),
                label: Text(context.tr('start')),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.shieldPlus,
            color: AppColors.onPrimary,
            size: 34,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 4. Quick services
// ---------------------------------------------------------------------------

class _QuickService extends StatelessWidget {
  const _QuickService({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    child: Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(Radii.button),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: Space.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xxs),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: TextSize.small,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Emergency: what to do, and a call button when the association has set
/// the emergency number in the dashboard.
void showEmergencySheet(BuildContext context, WidgetRef ref) {
  final number = ref.read(appSettingsProvider).info.emergencyNumber.trim();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.emergencySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                LucideIcons.siren,
                color: AppColors.emergency,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctx.tr('qs_emergency'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.emergencyText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ctx.tr('emergency_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            if (number.isNotEmpty)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: number)),
                icon: const Icon(LucideIcons.phone),
                label: Text('${ctx.tr('call')} $number'),
              )
            else
              Text(
                ctx.tr('emergency_no_number'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 5. Announcements (swipe when there are several)
// ---------------------------------------------------------------------------

class _Announcements extends ConsumerStatefulWidget {
  const _Announcements();
  @override
  ConsumerState<_Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends ConsumerState<_Announcements> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(activeAnnouncementsProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: _gap),
      child: Column(
        children: [
          SizedBox(
            height: 76,
            child: PageView.builder(
              itemCount: list.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.megaphone,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            list[i].body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (list.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < list.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 6,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Latest consultations
// ---------------------------------------------------------------------------

class _ConsultationRow extends StatelessWidget {
  const _ConsultationRow(this.c);
  final Consultation c;

  @override
  Widget build(BuildContext context) {
    final answered =
        c.status == ConsultationStatus.answered ||
        c.status == ConsultationStatus.closed;
    String two(int n) => n.toString().padLeft(2, '0');
    final d = c.createdAt;
    return HomeCard(
      onTap: () => context.push('/patient/consultation/${c.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.fileText,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(Specialty.byId(c.specialtyId).key),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
                Text(
                  '${two(d.day)}/${two(d.month)}/${d.year}',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(answered: answered),
        ],
      ),
    );
  }
}

/// «تم الرد» / «قيد المراجعة».
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.answered});
  final bool answered;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: answered ? AppColors.answeredSoft : AppColors.reviewingSoft,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 3.5,
          backgroundColor: answered ? AppColors.answered : AppColors.reviewing,
        ),
        const SizedBox(width: 6),
        Text(
          context.tr(answered ? 'st_answered' : 'st_reviewing'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: answered ? AppColors.answeredText : AppColors.reviewingText,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Shared card shapes
// ---------------------------------------------------------------------------

/// White card: 16 corners, padding 16, very light shadow, no border.
class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        boxShadow: AppColors.shadow,
      ),
      child: child,
    ),
  );
}

/// One service: icon in a 44 mint square, title, one-line description.
class ServiceTile extends StatelessWidget {
  ServiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    Color? color,
  }) : color = color ?? AppColors.primary;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: HomeCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(forwardChevron(context), color: AppColors.grey, size: 20),
        ],
      ),
    ),
  );
}

class _BloodRequestsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref
        .watch(bloodProvider)
        .requests
        .where((r) => r.requesterId == MockData.currentPatientId && r.isOpen)
        .length;
    return ServiceTile(
      icon: LucideIcons.droplet,
      title: context.tr('request_blood'),
      subtitle: open > 0
          ? context.tr('blood_requests_open', args: {'n': open})
          : context.tr('request_blood_desc'),
      onTap: () => context.push('/patient/blood'),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();
  static const _tips = [
    (LucideIcons.droplets, 'tip1'),
    (LucideIcons.footprints, 'tip2'),
    (LucideIcons.pill, 'tip3'),
    (LucideIcons.heartPulse, 'tip4'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _tips.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => SizedBox(
        width: 160,
        child: HomeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_tips[i].$1, color: AppColors.turquoise, size: 24),
              const Spacer(),
              Text(
                context.tr(_tips[i].$2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
