import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_provider.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/admin.dart';
import '../blood/committee_screens.dart' show CommitteeHomeScreen;
import '../onboarding/onboarding_screens.dart' show AppLogo;
import 'admin_ui.dart';
import 'sections/cases_section.dart';
import 'sections/doctors_section.dart';
import 'sections/facilities_section.dart';
import 'sections/finance_section.dart';
import 'sections/messages_section.dart';
import 'sections/overview_section.dart';
import 'sections/reports_section.dart';
import 'sections/security_section.dart';
import 'sections/settings_section.dart';
import 'sections/users_section.dart';

/// The ten areas of the dashboard and who may open them.
enum AdminSection {
  overview(Icons.dashboard_outlined, {}),
  users(Icons.manage_accounts_outlined, {
    AdminPermission.manageRegistrations,
    AdminPermission.suspendAccounts,
    AdminPermission.manageCards,
  }),
  cases(Icons.medical_information_outlined, {AdminPermission.viewCases}),
  blood(Icons.bloodtype_outlined, {AdminPermission.manageBlood}),
  doctors(Icons.medical_services_outlined, {AdminPermission.manageDoctors}),
  facilities(Icons.local_hospital_outlined, {AdminPermission.manageFacilities}),
  finance(Icons.volunteer_activism_outlined, {AdminPermission.viewFinance}),
  reports(Icons.insights_outlined, {AdminPermission.exportReports}),
  messages(Icons.campaign_outlined, {AdminPermission.sendNotifications}),
  security(Icons.admin_panel_settings_outlined, {}),
  settings(Icons.tune, {
    AdminPermission.manageSettings,
    AdminPermission.manageContent,
  });

  const AdminSection(this.icon, this.anyOf);
  final IconData icon;

  /// Empty: every admin (overview, own security settings).
  final Set<AdminPermission> anyOf;

  bool allowed(AdminState s) => anyOf.isEmpty || anyOf.any(s.can);

  String get key => 'ads_$name';
}

// ---------------------------------------------------------------------------
// Entry: sign in, or the dashboard
// ---------------------------------------------------------------------------

class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, this.section});
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(adminProvider.select((s) => s.me));
    if (me == null) return const AdminLoginScreen();
    final s =
        AdminSection.values.where((x) => x.name == section).firstOrNull ??
        AdminSection.overview;
    return AdminShell(section: s);
  }
}

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _codeStep = false;
  bool _obscure = true;
  String? _error;

  static const _demo = [
    ('admin@shifa.mr', 'Admin@2026', AdminRole.superAdmin),
    ('reg@shifa.mr', 'Reg@2026!', AdminRole.registrations),
    ('medical@shifa.mr', 'Medical@2026', AdminRole.medical),
    ('finance@shifa.mr', 'Finance@2026', AdminRole.finance),
    ('comm@shifa.mr', 'Comm@2026!', AdminRole.communications),
    ('audit@shifa.mr', 'Audit@2026', AdminRole.auditor),
    ('team@shifa.mr', 'Team@2026!', AdminRole.followUp),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _login() {
    final r = ref
        .read(adminProvider.notifier)
        .login(_email.text, _password.text);
    setState(() {
      _error = switch (r) {
        LoginResult.needCode => null,
        LoginResult.wrong => 'ad_login_wrong',
        LoginResult.locked => 'ad_login_locked',
        LoginResult.disabled => 'ad_login_disabled',
      };
      _codeStep = r == LoginResult.needCode;
    });
  }

  void _verify() {
    if (!ref.read(adminProvider.notifier).verifyCode(_code.text)) {
      setState(() => _error = 'ad_code_wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/role'),
          icon: const BackButtonIcon(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              const Center(child: AppLogo(size: 72)),
              const SizedBox(height: 10),
              Text(
                context.tr('ad_title'),
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              Text(
                context.tr(_codeStep ? 'ad_code_step' : 'ad_login_hint'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              if (!_codeStep) ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ] else
                TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    labelText: context.tr('ad_code'),
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(_error!),
                  style: const TextStyle(
                    color: AppColors.emergency,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                onPressed: _codeStep ? _verify : _login,
                child: Text(context.tr(_codeStep ? 'ad_verify' : 'login')),
              ),
              if (_codeStep)
                TextButton(
                  onPressed: () => setState(() {
                    _codeStep = false;
                    _code.clear();
                    _error = null;
                    ref.read(adminProvider.notifier).logout();
                  }),
                  child: Text(context.tr('back')),
                ),
              const SizedBox(height: 18),
              // Demo accounts (one per role) to try the permissions.
              Card(
                color: AppColors.secondary,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('ad_demo_accounts'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(context.tr('ad_demo_code'), style: text.bodySmall),
                      const SizedBox(height: 6),
                      for (final d in _demo)
                        InkWell(
                          onTap: () => setState(() {
                            _codeStep = false;
                            _error = null;
                            _email.text = d.$1;
                            _password.text = d.$2;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(context.tr('ar_${d.$3.name}')),
                                ),
                                Text(
                                  '${d.$1}  /  ${d.$2}',
                                  textDirection: TextDirection.ltr,
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

// ---------------------------------------------------------------------------
// Shell: navigation + section
// ---------------------------------------------------------------------------

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.section});
  final AdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final me = state.me!;
    final sections = AdminSection.values
        .where((s) => s.allowed(state))
        .toList();
    final wide = MediaQuery.sizeOf(context).width >= 980;

    void open(AdminSection s) => context.go('/admin/${s.name}');

    final content = section.allowed(state)
        ? switch (section) {
            AdminSection.overview => const OverviewSection(),
            AdminSection.users => const UsersSection(),
            AdminSection.cases => const CasesSection(),
            // Donors database, blood requests and donor matching.
            AdminSection.blood => const CommitteeHomeScreen(embedded: true),
            AdminSection.doctors => const DoctorsSection(),
            AdminSection.facilities => const FacilitiesSection(),
            AdminSection.finance => const FinanceSection(),
            AdminSection.reports => const ReportsSection(),
            AdminSection.messages => const MessagesSection(),
            AdminSection.security => const SecuritySection(),
            AdminSection.settings => const SettingsSection(),
          }
        : const NoAccess();
    final body = adminCompact(context, content);

    final appBar = AppBar(
      title: Text(context.tr('ad_title')),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            child: Chip(
              avatar: const Icon(Icons.person, size: 18),
              label: Text(
                wide
                    ? '${me.name} — ${context.tr('ar_${me.role.name}')}'
                    : me.name,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: context.tr('logout'),
          onPressed: () {
            ref.read(adminProvider.notifier).logout();
            context.go('/admin');
          },
          icon: const Icon(Icons.logout),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: sections.contains(section)
                  ? sections.indexOf(section)
                  : null,
              onDestinationSelected: (i) => open(sections[i]),
              labelType: MediaQuery.sizeOf(context).width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final s in sections)
                  NavigationRailDestination(
                    icon: Icon(s.icon),
                    label: Text(context.tr(s.key)),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  me.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(context.tr('ar_${me.role.name}')),
              ),
              const Divider(),
              for (final s in sections)
                ListTile(
                  selected: s == section,
                  leading: Icon(s.icon),
                  title: Text(context.tr(s.key)),
                  onTap: () {
                    Navigator.pop(context);
                    open(s);
                  },
                ),
            ],
          ),
        ),
      ),
      body: body,
    );
  }
}
