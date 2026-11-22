import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';

// ---------------------------------------------------------------------------
// «شفاء للناس» design kit: bottom bar with a raised centre action, curved
// header with the heartbeat line of the logo, soft menu rows, status dots.
// ---------------------------------------------------------------------------

class ShifaNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const ShifaNavItem(this.icon, this.selectedIcon, this.label);
}

/// Bottom bar: white, 64 high (+ safe area), a light top shadow, an even
/// number of [items] and a round main button raised in the middle.
class ShifaBottomBar extends StatelessWidget {
  const ShifaBottomBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.centerIcon,
    required this.centerLabel,
    required this.onCenter,
  }) : assert(items.length % 2 == 0);

  final List<ShifaNavItem> items;
  final int selected;
  final ValueChanged<int> onSelected;
  final IconData centerIcon;
  final String centerLabel;
  final VoidCallback onCenter;

  /// Inactive tabs: secondary text colour (readable, AA).
  static const _inactive = AppColors.grey;

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    Widget item(int i) {
      final it = items[i];
      final on = i == selected;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          label: it.label,
          child: InkResponse(
            onTap: () => onSelected(i),
            radius: 32,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: on ? AppColors.secondary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      on ? it.selectedIcon : it.icon,
                      size: 24,
                      color: on ? AppColors.primary : _inactive,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? AppColors.primary : _inactive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  for (var i = 0; i < half; i++) item(i),
                  const SizedBox(width: 72),
                  for (var i = half; i < items.length; i++) item(i),
                ],
              ),
              Positioned(
                top: -18,
                child: CircleActionButton(
                  icon: centerIcon,
                  label: centerLabel,
                  onTap: onCenter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round main action (56), raised above the bottom bar.
class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.surface, width: 4),
        ),
        elevation: 3,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Curved header with the logo's heartbeat line
// ---------------------------------------------------------------------------

class WaveHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.72)
      ..cubicTo(w * 0.78, h * 0.98, w * 0.6, h * 0.62, w * 0.42, h * 0.8)
      ..cubicTo(w * 0.26, h * 0.96, w * 0.12, h * 0.9, 0, h * 0.78)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.primary);
    // Heartbeat line (from the logo), very light.
    final y = h * 0.38;
    final pulse = Path()
      ..moveTo(0, y)
      ..lineTo(w * 0.30, y)
      ..lineTo(w * 0.35, y - 26)
      ..lineTo(w * 0.41, y + 30)
      ..lineTo(w * 0.46, y - 12)
      ..lineTo(w * 0.50, y)
      ..lineTo(w, y);
    canvas.drawPath(
      pulse,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.07);
    canvas.drawCircle(Offset(w * 0.9, h * 0.12), 56, dot);
    canvas.drawCircle(Offset(w * 0.12, h * 0.2), 30, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Profile top: curved emerald header, title, and an avatar half over the
/// curve. [below] goes under the avatar (name, badges...).
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.title,
    required this.avatar,
    required this.below,
    this.actions = const [],
  });
  final String title;
  final Widget avatar;
  final Widget below;
  final List<Widget> actions;

  static const _headerHeight = 210.0;
  static const _avatarSize = 108.0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: _headerHeight + _avatarSize / 2 - 10,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              bottom: _avatarSize / 2 - 10,
              child: CustomPaint(painter: WaveHeaderPainter()),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26126B50),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(child: avatar),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      below,
    ],
  );
}

/// Soft green panel holding white rounded menu rows.
class MenuPanel extends StatelessWidget {
  const MenuPanel({super.key, required this.children, this.title});
  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 10),
            child: Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ...children,
      ],
    ),
  );
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRightDir, color: AppColors.grey),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tab-shaped sign-out button at the bottom of the profile.
class LogoutTab extends StatelessWidget {
  const LogoutTab({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Availability dot on an avatar: green = available, grey = not now.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.on, this.size = 13});
  final bool on;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: on ? AppColors.vivid : AppColors.offline,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}
