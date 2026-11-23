export 'welcome_screen.dart';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../patient/home_tab.dart' show VerseText;

import '../../core/accounts_remote.dart';
import '../../core/admin_provider.dart';
import '../../core/l10n.dart';
import '../../models/admin.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/registration.dart';
import '../../widgets/brand.dart';
import '../../widgets/ui_kit.dart' show FadeSlideIn, Pressable;

/// The heart + cross icon of "شِفاءٌ لِلنّاس".
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: context.tr('app_name'),
    );
  }
}

/// Full logo lockup, as in the brand image: heart icon next to the name,
/// the tagline "تطبيق خيري طبي" and the association name.
class ShifaLockup extends StatelessWidget {
  const ShifaLockup({super.key, this.iconSize = 92, this.vertical = false});
  final double iconSize;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final words = Column(
      crossAxisAlignment: vertical
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: BrandName(fontSize: vertical ? 40 : 34),
        ),
        Text(
          context.tr('app_tagline'),
          style: text.titleMedium?.copyWith(
            color: AppColors.turquoiseText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.tr('association'),
          style: text.bodyMedium?.copyWith(
            color: AppColors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: iconSize),
          const SizedBox(height: 16),
          words,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: iconSize),
        const SizedBox(width: 14),
        Flexible(child: words),
      ],
    );
  }
}

/// Header with the app logo and the introduction of the platform.
/// Used on the role screen and the patient home.
class ShifaHero extends StatelessWidget {
  const ShifaHero({super.key, this.top});

  /// Optional row shown above the logo (greeting, buttons...).
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        children: [
          ?top,
          const SizedBox(height: 12),
          const ShifaLockup(),
          const SizedBox(height: 14),
          const AboutShifaCard(),
        ],
      ),
    );
  }
}

/// The introduction of the app on a mint card: dark grey text, the name in
/// emerald, a small gold heart on top and the logo's pulse line in turquoise.
class AboutShifaCard extends StatelessWidget {
  const AboutShifaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: .10)),
          ),
          child: Column(
            children: [
              BrandRichText(
                context.tr('about_shifa'),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: AppColors.text,
                  height: 1.85,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                height: 18,
                width: 160,
                child: CustomPaint(painter: _MiniPulsePainter()),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.turquoise, width: 2),
            boxShadow: AppColors.shadow,
          ),
          child: Icon(LucideIcons.heart, color: AppColors.turquoise, size: 20),
        ),
      ],
    );
  }
}

class _MiniPulsePainter extends CustomPainter {
  const _MiniPulsePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, y = h / 2;
    final p = Path()
      ..moveTo(0, y)
      ..lineTo(w * .36, y)
      ..lineTo(w * .43, y - h * .45)
      ..lineTo(w * .52, y + h * .5)
      ..lineTo(w * .59, y - h * .2)
      ..lineTo(w * .64, y)
      ..lineTo(w, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = AppColors.turquoise
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Server: a person already signed in on this phone goes straight to
  /// their space; otherwise the introduction.
  Future<void> _start() async {
    final wait = Future.delayed(const Duration(milliseconds: 1800));
    final p = AccountsRemote.enabled
        ? await const AccountsRemote().current()
        : null;
    await wait;
    if (!mounted) return;
    if (p == null || p.status == ReviewStatus.rejected) {
      context.go('/onboarding');
      return;
    }
    ref.read(registrationsProvider.notifier).upsert(p.toRegistration());
    ref
        .read(authProvider.notifier)
        .loginAs(
          role: p.role,
          name: p.name,
          phone: p.phone,
          idNumber: p.nationalId,
          registrationId: p.userId,
          specialtyId: p.specialtyId,
        );
    final auth = ref.read(authProvider);
    context.go(
      auth.isPsychDoctor
          ? '/psych/doctor'
          : auth.isDoctor
          ? '/doctor'
          : '/patient',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShifaLockup(iconSize: 150, vertical: true),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.turquoise,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  /// Page 0 is the platform introduction; the others follow.
  static const _pages = [
    (LucideIcons.handHeart, 'onb1_title', 'onb1_body'),
    (LucideIcons.scanText, 'onb2_title', 'onb2_body'),
    (LucideIcons.shieldPlus, 'onb3_title', 'onb3_body'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _count => _pages.length + 1;

  void _next() {
    if (_page == _count - 1) {
      context.go('/welcome');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      // Same background as the home screen.
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Choose among the languages offered by the association.
                  PopupMenuButton<String>(
                    tooltip: context.tr('language'),
                    initialValue: locale.languageCode,
                    onSelected: (l) =>
                        ref.read(localeProvider.notifier).set(Locale(l)),
                    itemBuilder: (_) => [
                      for (final l in ref.read(appSettingsProvider).languages)
                        PopupMenuItem(
                          value: l,
                          child: Text(AppStrings.languageNames[l]!),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.globe, color: AppColors.turquoise),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.languageNames[locale.languageCode] ??
                                'العربية',
                            style: TextStyle(
                              color: AppColors.turquoiseText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronDown,
                            color: AppColors.turquoise,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_page < _count - 1)
                    TextButton(
                      onPressed: () => context.go('/welcome'),
                      child: Text(context.tr('skip')),
                    ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    if (i == 0) return const _IntroPage();
                    final (icon, title, body) = _pages[i - 1];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 10,
                            ),
                            boxShadow: AppColors.shadow,
                          ),
                          child: Icon(
                            icon,
                            size: 104,
                            color: AppColors.turquoise,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          context.tr(title),
                          textAlign: TextAlign.center,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr(body),
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: AppColors.text,
                            height: 1.7,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.primary
                            : (i < _page
                                  ? AppColors.turquoise
                                  : AppColors.mint),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _next,
                child: Text(context.tr(_page == _count - 1 ? 'start' : 'next')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First onboarding page: logo, name, the verse, a short pulse line and
/// one sentence (the full introduction is on the «about the app» page).
class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    Widget step(int i, Widget child) => FadeSlideIn(
      index: i,
      step: const Duration(milliseconds: 80),
      rise: 12,
      child: child,
    );
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            step(
              0,
              Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const AppLogo(size: 120),
              ),
            ),
            const SizedBox(height: 24),
            step(
              1,
              BrandName(
                fontSize: 34,
                color: AppColors.primary,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            step(
              2,
              VerseText(
                style: TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  color: AppColors.turquoiseText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            step(
              3,
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 16,
                    child: CustomPaint(
                      painter: _ShortPulsePainter(
                        AppColors.turquoise.withValues(alpha: .4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      context.tr('about_short'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortPulsePainter extends CustomPainter {
  const _ShortPulsePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, y = h / 2;
    final p = Path()
      ..moveTo(0, y)
      ..lineTo(w * .32, y)
      ..lineTo(w * .42, y - h * .42)
      ..lineTo(w * .54, y + h * .45)
      ..lineTo(w * .63, y)
      ..lineTo(w, y);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShortPulsePainter o) => o.color != color;
}

// ---------------------------------------------------------------------------
// New account: choose the kind of account
// ---------------------------------------------------------------------------

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(appSettingsProvider);

    void choose(UserRole role) {
      ref.read(authProvider.notifier).selectRole(role);
      context.push('/register');
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('create_account'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            context.tr('who_are_you'),
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('choose_role'),
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
          const SizedBox(height: 20),
          _RoleCard(
            icon: LucideIcons.userRound,
            title: context.tr('role_patient'),
            subtitle: context.tr('role_patient_desc'),
            color: AppColors.patient,
            darkColor: AppColors.patientDark,
            onTap: () => choose(UserRole.patient),
          ),
          const SizedBox(height: 14),
          _RoleCard(
            icon: LucideIcons.briefcaseMedical,
            title: context.tr('role_doctor'),
            subtitle: context.tr('role_doctor_desc'),
            color: AppColors.doctor,
            darkColor: AppColors.doctorDark,
            onTap: () => choose(UserRole.doctor),
          ),
          if (settings.enabled(AppSection.blood)) ...[
            const SizedBox(height: 14),
            _RoleCard(
              icon: LucideIcons.droplet,
              title: context.tr('role_donor'),
              subtitle: context.tr('role_donor_desc'),
              color: AppColors.secondary,
              darkColor: AppColors.primary,
              onTap: () => context.push('/blood/donor'),
            ),
          ],
          if (settings.enabled(AppSection.facilities)) ...[
            const SizedBox(height: 14),
            _RoleCard(
              icon: LucideIcons.hospital,
              title: context.tr('role_facility'),
              subtitle: context.tr('role_facility_desc'),
              color: AppColors.secondary,
              darkColor: AppColors.primary,
              onTap: () => context.push('/facility/register'),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.tr('have_account')),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(context.tr('login')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.darkColor,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color darkColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Same card shape as the home screen: white, 16 corners, light shadow.
    return Pressable(
      haptic: true,
      onTap: onTap,
      semanticLabel: title,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Radii.card),
          boxShadow: AppColors.shadow,
        ),
        child: ConstrainedBox(
          // Same height for every card.
          constraints: const BoxConstraints(minHeight: 92),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 24, color: darkColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        style: text.bodySmall?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRightDir,
                  size: 20,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
