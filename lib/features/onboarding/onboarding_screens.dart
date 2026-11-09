import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';

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
    final dark = Theme.of(context).brightness == Brightness.dark;
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
            color: dark ? AppColors.mint : AppColors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          context.tr('association'),
          style: text.bodyMedium?.copyWith(
            color: dark ? Colors.white70 : AppColors.grey,
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
    final text = Theme.of(context).textTheme;
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
        border: const Border(
          bottom: BorderSide(color: AppColors.green, width: 4),
        ),
      ),
      child: Column(
        children: [
          ?top,
          const SizedBox(height: 12),
          const ShifaLockup(),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: BrandRichText(
              context.tr('about_shifa'),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: Colors.white,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Splash
// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ShifaLockup(iconSize: 150, vertical: true),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.teal,
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

  static const _pages = [
    (Icons.volunteer_activism_rounded, 'onb1_title', 'onb1_body'),
    (Icons.document_scanner_rounded, 'onb2_title', 'onb2_body'),
    (Icons.health_and_safety_rounded, 'onb3_title', 'onb3_body'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      context.go('/role');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => ref
                        .read(localeProvider.notifier)
                        .set(Locale(locale.languageCode == 'ar' ? 'fr' : 'ar')),
                    icon: const Icon(Icons.language),
                    label: Text(
                      locale.languageCode == 'ar' ? 'Français' : 'العربية',
                    ),
                  ),
                  const Spacer(),
                  if (_page < _pages.length - 1)
                    TextButton(
                      onPressed: () => context.go('/role'),
                      child: Text(context.tr('skip')),
                    ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (icon, title, body) = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: .5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 110, color: scheme.primary),
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
                            color: scheme.onSurfaceVariant,
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
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? scheme.primary
                            : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _next,
                child: Text(
                  context.tr(_page == _pages.length - 1 ? 'start' : 'next'),
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
// Role selection
// ---------------------------------------------------------------------------

class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    void choose(UserRole role) {
      ref.read(authProvider.notifier).selectRole(role);
      context.push('/login');
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ShifaHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  icon: Icons.personal_injury_outlined,
                  title: context.tr('role_patient'),
                  subtitle: context.tr('role_patient_desc'),
                  color: AppColors.patient,
                  darkColor: AppColors.patientDark,
                  onTap: () => choose(UserRole.patient),
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: Icons.medical_services_outlined,
                  title: context.tr('role_doctor'),
                  subtitle: context.tr('role_doctor_desc'),
                  color: AppColors.doctor,
                  darkColor: AppColors.doctorDark,
                  onTap: () => choose(UserRole.doctor),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.push('/disclaimer'),
                  icon: const Icon(Icons.info_outline),
                  label: Text(context.tr('disclaimer')),
                ),
              ],
            ),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: darkColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 34, color: AppColors.ink),
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
                    Text(subtitle, style: text.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: darkColor),
            ],
          ),
        ),
      ),
    );
  }
}
