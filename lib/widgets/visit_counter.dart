import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../core/admin_provider.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/visit_counter.dart';

/// 46169 → "46,169" (kept left-to-right inside Arabic text).
String countText(int n) => NumberFormat('#,###', 'en').format(n);

/// Number that rolls to its new value when the figures refresh.
class RollingCount extends StatelessWidget {
  const RollingCount(this.value, {super.key, this.style});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text(
      countText(v.round()),
      textDirection: TextDirection.ltr,
      style: style,
    ),
  );
}

/// Small pulsing dot ("live").
/// Pulses a few times when it appears and each time [pulseKey] changes
/// (new figures), then rests: no endless animation.
class LiveDot extends StatefulWidget {
  const LiveDot({
    super.key,
    this.color = AppColors.vivid,
    this.size = 10,
    this.pulseKey,
  });
  final Color color;
  final double size;
  final Object? pulseKey;
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  void _pulse() => _c
    ..reset()
    ..repeat(count: 3);

  @override
  void initState() {
    super.initState();
    _pulse();
  }

  @override
  void didUpdateWidget(LiveDot old) {
    super.didUpdateWidget(old);
    if (old.pulseKey != widget.pulseKey) _pulse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size * 2.2,
    height: widget.size * 2.2,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: widget.size * (1 + 1.2 * _c.value),
            height: widget.size * (1 + 1.2 * _c.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    ),
  );
}

/// "● متصل الآن 46" — compact pill; opens the full figures.
class VisitorLivePill extends ConsumerWidget {
  const VisitorLivePill({super.key, this.onDark = false});

  /// On a coloured header: white pill.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appSettingsProvider).showVisitorCounter) {
      return const SizedBox.shrink();
    }
    final s = ref.watch(visitCounterProvider);
    final fg = onDark ? AppColors.primary : Colors.white;
    return Semantics(
      button: true,
      label: context.tr('vc_title'),
      child: Material(
        color: onDark ? Colors.white : AppColors.turquoise,
        shape: const StadiumBorder(),
        elevation: onDark ? 0 : 1,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showVisitorStats(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 14, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiveDot(
                  color: onDark ? AppColors.vivid : AppColors.secondary,
                  size: 9,
                  pulseKey: s?.updatedAt,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('vc_online'),
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                if (s == null)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else
                  RollingCount(
                    s.onlineNow,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showVisitorStats(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: VisitorStatsCard(flat: true),
    ),
  ),
);

/// The public figures: visits since launch, visitors today, and (when the
/// association shows them) registered users and beneficiaries.
class VisitorStatsCard extends ConsumerWidget {
  const VisitorStatsCard({super.key, this.flat = false});

  /// Inside a sheet: no card frame.
  final bool flat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    if (!settings.showVisitorCounter) return const SizedBox.shrink();
    final s = ref.watch(visitCounterProvider);
    String two(int n) => n.toString().padLeft(2, '0');

    final tiles = <Widget>[
      _Tile(LucideIcons.eye, 'vc_total', s?.totalVisits, AppColors.primary),
      _Tile(
        LucideIcons.calendarDays,
        'vc_today',
        s?.todayVisitors,
        AppColors.turquoise,
      ),
      if (settings.showRegisteredCount && (s == null || s.registered != null))
        _Tile(
          LucideIcons.userCheck,
          'vc_registered',
          s?.registered,
          AppColors.vivid,
        ),
      if (settings.showBeneficiariesCount &&
          (s == null || s.beneficiaries != null))
        _Tile(
          LucideIcons.handHeart,
          'vc_beneficiaries',
          s?.beneficiaries,
          AppColors.turquoise,
        ),
    ];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.chartLine, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('vc_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
            const VisitorLivePill(),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (_, c) {
            final perRow = c.maxWidth > 560 ? tiles.length : 2;
            final w = (c.maxWidth - 8 * (perRow - 1)) / perRow;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final t in tiles) SizedBox(width: w, child: t)],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(LucideIcons.refreshCw, size: 15, color: AppColors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                s == null
                    ? context.tr('vc_loading')
                    : context.tr(
                        'vc_auto',
                        args: {
                          't':
                              '${two(s.updatedAt.hour)}:${two(s.updatedAt.minute)}',
                        },
                      ),
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
            ),
            if (s?.demo ?? false)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.turquoise.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('vc_demo'),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
    if (flat) return body;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(14), child: body),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              value == null
                  ? const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : RollingCount(
                      value!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
              Text(
                context.tr(label),
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
