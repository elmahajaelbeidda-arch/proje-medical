import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : AppColors.primary,
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: size * .62,
            color: light ? AppColors.primary : Colors.white,
          ),
          Icon(
            Icons.add_rounded,
            size: size * .34,
            color: light ? Colors.white : AppColors.primary,
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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 110, light: true),
              const SizedBox(height: 24),
              Text(
                context.tr('app_name'),
                style: text.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('app_slogan'),
                style: text.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
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
                    onPressed: () => ref.read(localeProvider.notifier).set(
                          Locale(locale.languageCode == 'ar' ? 'fr' : 'ar'),
                        ),
                    icon: const Icon(Icons.language),
                    label: Text(locale.languageCode == 'ar' ? 'Français' : 'العربية'),
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
                            color: scheme.primaryContainer.withValues(alpha: .5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 110, color: scheme.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          context.tr(title),
                          textAlign: TextAlign.center,
                          style: text.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr(body),
                          textAlign: TextAlign.center,
                          style: text.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: AppLogo(size: 80)),
              const SizedBox(height: 28),
              Text(
                context.tr('who_are_you'),
                textAlign: TextAlign.center,
                style:
                    text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('choose_role'),
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.personal_injury_outlined,
                title: context.tr('role_patient'),
                subtitle: context.tr('role_patient_desc'),
                color: AppColors.primary,
                onTap: () => choose(UserRole.patient),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.medical_services_outlined,
                title: context.tr('role_doctor'),
                subtitle: context.tr('role_doctor_desc'),
                color: AppColors.info,
                onTap: () => choose(UserRole.doctor),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/disclaimer'),
                icon: const Icon(Icons.info_outline),
                label: Text(context.tr('disclaimer')),
              ),
            ],
          ),
        ),
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
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
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
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 34, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: text.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
