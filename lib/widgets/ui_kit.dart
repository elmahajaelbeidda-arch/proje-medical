import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

// ---------------------------------------------------------------------------
// «شفاء للناس» UI kit: press feedback, staggered entrance, skeletons,
// illustrations, and the empty / error / success states. Every screen uses
// these so each element has one shape and one behaviour.
// ---------------------------------------------------------------------------

/// Tap feedback: shrinks to 0.97 and darkens slightly while pressed, with an
/// optional light haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = false,
    this.radius = Radii.card,
    this.semanticLabel,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final double radius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onTap != null,
    label: widget.semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? Motion.pressScale : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        // Passthrough: the child keeps the size its parent gives it.
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: Motion.fast,
                  decoration: BoxDecoration(
                    color: _down
                        ? AppColors.text.withValues(alpha: .05)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fades and slides an element in, [index] steps after the screen opens.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.slow);
  Timer? _t;

  @override
  void initState() {
    super.initState();
    final delay = Motion.stagger * math.min(widget.index, 8);
    if (delay == Duration.zero) {
      _c.forward();
    } else {
      _t = Timer(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect "reduce motion".
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final a = CurvedAnimation(parent: _c, curve: Motion.curve);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .04),
          end: Offset.zero,
        ).animate(a),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeletons
// ---------------------------------------------------------------------------

/// Grey shape that gently pulses while content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.border, AppColors.secondary, _c.value),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

/// Card-shaped placeholders for a loading list.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3});
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('state_loading'),
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: Space.s),
            padding: const EdgeInsets.all(Space.m),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: AppColors.shadow,
            ),
            child: const Row(
              children: [
                SkeletonBox(width: 44, height: 44, radius: 12),
                SizedBox(width: Space.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 14),
                      SizedBox(height: Space.xs),
                      SkeletonBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Illustrations (one style, app colours)
// ---------------------------------------------------------------------------

/// Soft illustration: layered mint circles, a few dots, the logo's pulse
/// line and a Lucide icon in the middle.
class Illustration extends StatelessWidget {
  const Illustration({
    super.key,
    required this.icon,
    this.size = 168,
    this.tone,
  });
  final IconData icon;
  final double size;

  /// Icon colour (default: primary).
  final Color? tone;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IllustrationPainter(
          AppColors.secondary,
          AppColors.surface,
          AppColors.turquoise,
          AppColors.primary,
        ),
        child: Center(
          child: Container(
            width: size * .42,
            height: size * .42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppColors.shadow,
            ),
            child: Icon(
              icon,
              size: size * .2,
              color: tone ?? AppColors.primary,
            ),
          ),
        ),
      ),
    ),
  );
}

class _IllustrationPainter extends CustomPainter {
  _IllustrationPainter(this.mint, this.surface, this.accent, this.primary);
  final Color mint, surface, accent, primary;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = mint);
    canvas.drawCircle(c, r * .72, Paint()..color = mint.withValues(alpha: .6));
    // Pulse line across.
    final y = c.dy + r * .05;
    final p = Path()
      ..moveTo(c.dx - r * .95, y)
      ..lineTo(c.dx - r * .55, y)
      ..lineTo(c.dx - r * .45, y - r * .18)
      ..lineTo(c.dx - r * .36, y + r * .16)
      ..lineTo(c.dx - r * .29, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = accent.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Small dots.
    final dot = Paint()..color = accent.withValues(alpha: .5);
    canvas.drawCircle(Offset(c.dx + r * .62, c.dy - r * .58), r * .06, dot);
    canvas.drawCircle(Offset(c.dx + r * .78, c.dy + r * .3), r * .035, dot);
    canvas.drawCircle(
      Offset(c.dx - r * .66, c.dy - r * .52),
      r * .045,
      Paint()..color = primary.withValues(alpha: .35),
    );
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter o) =>
      o.mint != mint || o.accent != accent;
}

// ---------------------------------------------------------------------------
// Empty / error / success states
// ---------------------------------------------------------------------------

/// Friendly empty state: illustration, a sentence and an optional action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Illustration(icon: icon),
          const SizedBox(height: Space.l),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TextSize.title,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: Space.xs),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TextSize.body,
              height: TextSize.lineHeight,
              color: AppColors.grey,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.l),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
              onPressed: onAction,
              icon: const Icon(LucideIcons.plus, size: 20),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

/// True when [error] looks like a missing internet connection.
bool isOfflineError(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('socket') ||
      s.contains('failed host lookup') ||
      s.contains('network') ||
      s.contains('clientexception') ||
      s.contains('connection');
}

/// Error or offline: a clear message and «إعادة المحاولة».
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = isOfflineError(error);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Illustration(
              icon: offline ? LucideIcons.wifiOff : LucideIcons.cloudAlert,
              tone: AppColors.turquoise,
            ),
            const SizedBox(height: Space.l),
            Text(
              context.tr(offline ? 'state_offline_title' : 'state_error_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TextSize.title,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              context.tr(offline ? 'state_offline_body' : 'state_error_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TextSize.body,
                height: TextSize.lineHeight,
                color: AppColors.grey,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: Space.l),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
                label: Text(context.tr('state_retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen confirmation with an animated ✓ (after sending a request).
Future<void> showSuccess(
  BuildContext context, {
  required String title,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  HapticFeedback.mediumImpact();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: Motion.slow,
      pageBuilder: (ctx, _, _) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              children: [
                const Spacer(),
                const AnimatedCheck(),
                const SizedBox(height: Space.l),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TextSize.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TextSize.body,
                    height: TextSize.lineHeight,
                    color: AppColors.grey,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onAction();
                  },
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

/// Green circle that pops in, then a ✓ drawn stroke by stroke.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({super.key, this.size = 112});
  final double size;
  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, .55, curve: Curves.easeOutBack),
    );
    final draw = CurvedAnimation(
      parent: _c,
      curve: const Interval(.45, 1, curve: Curves.easeOut),
    );
    return Semantics(
      label: '✓',
      child: ScaleTransition(
        scale: pop,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.answeredSoft,
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: draw,
            builder: (_, _) => CustomPaint(
              painter: _CheckPainter(draw.value, AppColors.answered),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.color);
  final double t;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * .30, w * .52)
      ..lineTo(w * .45, w * .66)
      ..lineTo(w * .72, w * .38);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .07
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter o) => o.t != t;
}
