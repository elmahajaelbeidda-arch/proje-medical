import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../core/search.dart';
import '../../core/blood_provider.dart';
import '../../widgets/common.dart';
import '../blood/blood_screens.dart';
import '../../widgets/voice_search.dart';
import '../onboarding/onboarding_screens.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({super.key});
  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          PatientHomeTab(
            onSeeConsultations: () => setState(() => _index = 1),
            onOpenBlood: () => setState(() => _index = 3),
          ),
          const MyConsultationsTab(),
          const DoctorsTab(),
          const BloodHomeScreen(),
          const PatientProfileTab(),
        ],
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/patient/new'),
              icon: const Icon(Icons.add),
              label: Text(context.tr('new_consultation')),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: context.tr('nav_consultations'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medical_services_outlined),
            selectedIcon: const Icon(Icons.medical_services),
            label: context.tr('nav_doctors'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bloodtype_outlined),
            selectedIcon: const Icon(Icons.bloodtype),
            label: context.tr('nav_blood'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.tr('nav_profile'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

class PatientHomeTab extends ConsumerWidget {
  const PatientHomeTab({
    super.key,
    required this.onSeeConsultations,
    required this.onOpenBlood,
  });
  final VoidCallback onSeeConsultations;
  final VoidCallback onOpenBlood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final mine = ref
        .watch(consultationsProvider)
        .where((c) => c.patientId == MockData.currentPatientId)
        .toList();
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ShifaHero(
          top: Row(
            children: [
              Expanded(
                child: Text(
                  '${context.tr('hello')} ${auth.displayName.split(' ').first} 👋',
                  style: text.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.push('/notifications'),
                icon: const Badge(
                  smallSize: 8,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AccountReviewBanner(),
              const SizedBox(height: 4),

              // Main CTA
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('request_consultation'),
                            style: text.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('request_consultation_desc'),
                            style: text.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(0, 46),
                            ),
                            onPressed: () => context.push('/patient/new'),
                            icon: const Icon(Icons.add_comment_outlined),
                            label: Text(context.tr('start')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.secondary,
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Emergency
              Card(
                color: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.emergency_outlined,
                    color: Colors.white,
                  ),
                  title: Text(
                    context.tr('emergency_title'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('emergency_body'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () {},
                    child: Text(context.tr('call')),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Blood donation entry (urgent requests count)
              _BloodBanner(onTap: onOpenBlood),
              const SizedBox(height: 8),

              // Quick services
              SectionHeader(context.tr('quick_services')),
              Row(
                children: [
                  for (final t in ConsultationType.values) ...[
                    Expanded(
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push('/patient/new', extra: t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.ink,
                                  child: Icon(
                                    typeIcon(t),
                                    color: AppColors.mint,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.tr(typeKey(t)),
                                  textAlign: TextAlign.center,
                                  style: text.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (t != ConsultationType.values.last)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.groups_outlined,
                      value: '${MockData.doctors.length * 16}',
                      label: context.tr('volunteer_doctors'),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: _AnsweredStat()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      icon: Icons.timer_outlined,
                      value: '6h',
                      label: context.tr('avg_response'),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),

              if (mine.isNotEmpty) ...[
                const SizedBox(height: 8),
                SectionHeader(
                  context.tr('last_consultation'),
                  action: context.tr('see_all'),
                  onAction: onSeeConsultations,
                ),
                ConsultationCard(
                  consultation: mine.first,
                  onTap: () =>
                      context.push('/patient/consultation/${mine.first.id}'),
                ),
              ],

              const SizedBox(height: 8),
              SectionHeader(context.tr('health_tips')),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final (icon, key, color) = _tips[i];
                    return Container(
                      width: 170,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: AppColors.on(color), size: 28),
                          const Spacer(),
                          Text(
                            context.tr(key),
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.on(color),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _tips = [
    (Icons.water_drop_outlined, 'tip1', AppColors.info),
    (Icons.directions_walk, 'tip2', AppColors.success),
    (Icons.medication_outlined, 'tip3', AppColors.primary),
    (Icons.monitor_heart_outlined, 'tip4', AppColors.ink),
  ];
}

class _AnsweredStat extends StatelessWidget {
  const _AnsweredStat();
  @override
  Widget build(BuildContext context) => StatCard(
    icon: Icons.task_alt,
    value: '1.4K',
    label: context.tr('answered_consultations'),
    color: AppColors.success,
  );
}

// ---------------------------------------------------------------------------
// My consultations
// ---------------------------------------------------------------------------

class MyConsultationsTab extends ConsumerWidget {
  const MyConsultationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref
        .watch(consultationsProvider)
        .where((c) => c.patientId == MockData.currentPatientId)
        .toList();
    final active = mine.where((c) => c.isActive).toList();
    final done = mine.where((c) => !c.isActive).toList();

    Widget list(List<Consultation> items) {
      if (items.isEmpty) {
        return EmptyState(
          icon: Icons.assignment_outlined,
          message: context.tr('no_consultations'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => ConsultationCard(
          consultation: items[i],
          onTap: () => context.push('/patient/consultation/${items[i].id}'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('nav_consultations')),
          bottom: TabBar(
            tabs: [
              Tab(text: '${context.tr('active')} (${active.length})'),
              Tab(text: '${context.tr('completed')} (${done.length})'),
            ],
          ),
        ),
        body: TabBarView(children: [list(active), list(done)]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Doctors
// ---------------------------------------------------------------------------

class DoctorsTab extends StatefulWidget {
  const DoctorsTab({super.key});
  @override
  State<DoctorsTab> createState() => _DoctorsTabState();
}

class _DoctorsTabState extends State<DoctorsTab> {
  String? _specialty;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final doctors = MockData.doctors.where((d) {
      final okSpecialty = _specialty == null || d.specialtyId == _specialty;
      final sp = Specialty.byId(d.specialtyId).key;
      final okQuery = Search.matches(_query, [
        d.name,
        AppStrings.of('ar', sp),
        AppStrings.of('fr', sp),
        d.city,
        d.cityFr,
        d.bio,
      ]);
      return okSpecialty && okQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('our_doctors'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: VoiceSearchField(
              hintKey: 'search_doctors',
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(context.tr('all')),
                    selected: _specialty == null,
                    onSelected: (_) => setState(() => _specialty = null),
                  ),
                ),
                for (final s in Specialty.all)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(context.tr(s.key)),
                      selected: _specialty == s.id,
                      onSelected: (_) => setState(() => _specialty = s.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: doctors.isEmpty
                ? EmptyState(
                    icon: Icons.person_search_outlined,
                    message: _query.isEmpty
                        ? context.tr('none')
                        : context.tr('no_results', args: {'q': _query}),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: doctors.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == doctors.length) return const _JoinBanner();
                      return DoctorCard(
                        doctor: doctors[i],
                        onTap: () => showDoctorSheet(context, doctors[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _JoinBanner extends StatelessWidget {
  const _JoinBanner();
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.doctorDark,
      child: ListTile(
        textColor: Colors.white,
        contentPadding: const EdgeInsets.all(14),
        leading: const Icon(Icons.volunteer_activism, color: Colors.white),
        title: Text(
          context.tr('join_as_doctor'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(context.tr('onb3_body')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class PatientProfileTab extends ConsumerWidget {
  const PatientProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(healthProfileProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.person, size: 52, color: scheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            auth.displayName,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              Pill(
                label: '${profile.age} ${context.tr('years')}',
                color: scheme.primary,
              ),
              Pill(
                label: profile.bloodType,
                color: AppColors.primary,
                icon: Icons.bloodtype,
              ),
            ],
          ),
          if (auth.idNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(child: IdVerifiedBadge(auth: auth)),
          ],
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                MenuTile(
                  icon: Icons.folder_shared_outlined,
                  title: context.tr('health_profile'),
                  onTap: () => context.push('/patient/health-profile'),
                ),
                // Blood requests live only in the patient's profile.
                MenuTile(
                  icon: Icons.bloodtype_outlined,
                  title: context.tr('my_blood_requests'),
                  onTap: () => context.push('/patient/blood'),
                ),
                MenuTile(
                  icon: Icons.notifications_outlined,
                  title: context.tr('notifications'),
                  onTap: () => context.push('/notifications'),
                ),
                MenuTile(
                  icon: Icons.settings_outlined,
                  title: context.tr('settings'),
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                MenuTile(
                  icon: Icons.gavel_outlined,
                  title: context.tr('disclaimer'),
                  onTap: () => context.push('/disclaimer'),
                ),
                MenuTile(
                  icon: Icons.support_agent_outlined,
                  title: context.tr('contact_us'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: MenuTile(
              icon: Icons.logout,
              title: context.tr('logout'),
              color: AppColors.text,
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/role');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodBanner extends ConsumerWidget {
  const _BloodBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(bloodProvider).myDonor;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.bloodtype, color: Colors.white),
        ),
        title: Text(
          context.tr(me == null ? 'become_donor_title' : 'my_donor_card'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        subtitle: me == null
            ? Text(
                context.tr('donor_section_intro'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : Align(
                alignment: AlignmentDirectional.centerStart,
                child: DonorStatusPill(me.status),
              ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
