import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/l10n.dart';
import '../cards/member_card_screens.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../core/search.dart';
import '../../widgets/common.dart';
import 'home_tab.dart';

export 'home_tab.dart' show PatientHomeTab;
import '../../widgets/shifa_ui.dart';
import '../blood/blood_screens.dart';
import '../../widgets/voice_search.dart';

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
            onOpenDoctors: () => setState(() => _index = 2),
          ),
          const MyConsultationsTab(),
          const DoctorsTab(),
          const BloodHomeScreen(),
          const PatientProfileTab(),
        ],
      ),
      // Main action in the middle: ask for a consultation. Blood donation
      // stays reachable from its home card and from the profile.
      bottomNavigationBar: ShifaBottomBar(
        selected: switch (_index) {
          0 => 0,
          1 => 1,
          2 => 2,
          4 => 3,
          _ => -1,
        },
        onSelected: (i) => setState(() => _index = const [0, 1, 2, 4][i]),
        centerIcon: LucideIcons.plus,
        centerLabel: context.tr('new_consultation'),
        onCenter: () => context.push('/patient/new'),
        items: [
          ShifaNavItem(
            LucideIcons.house,
            LucideIcons.house,
            context.tr('nav_home'),
          ),
          ShifaNavItem(
            LucideIcons.clipboardList,
            LucideIcons.clipboardList,
            context.tr('nav_consultations'),
          ),
          ShifaNavItem(
            LucideIcons.stethoscope,
            LucideIcons.stethoscope,
            context.tr('nav_doctors'),
          ),
          ShifaNavItem(
            LucideIcons.user,
            LucideIcons.user,
            context.tr('nav_profile'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------

// Home: see home_tab.dart

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
        AppStrings.of('en', sp),
        d.city,
        d.cityFr,
        d.bio,
      ]);
      return okSpecialty && okQuery;
    }).toList();
    final available = doctors.where((d) => d.available).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('our_doctors')),
        actions: [
          IconButton(
            tooltip: context.tr('cm_title'),
            onPressed: () => context.push('/care-map'),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      if (available.isNotEmpty) ...[
                        Text(
                          context.tr('available_now'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 96,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: available.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 6),
                            itemBuilder: (_, i) => DoctorBubble(
                              doctor: available[i],
                              onTap: () =>
                                  context.push('/doctors/${available[i].id}'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      for (final d in doctors) ...[
                        DoctorCard(
                          doctor: d,
                          onTap: () => context.push('/doctors/${d.id}'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const _JoinBanner(),
                    ],
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

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ProfileHero(
          title: context.tr('nav_profile'),
          avatar: Container(
            color: AppColors.secondary,
            alignment: Alignment.center,
            child: Text(
              auth.displayName.characters.first,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: context.tr('notifications'),
              onPressed: () => context.push('/notifications'),
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
            ),
          ],
          below: Column(
            children: [
              Text(
                auth.displayName,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Pill(
                    label: '${profile.age} ${context.tr('years')}',
                    color: AppColors.turquoise,
                  ),
                  Pill(
                    label: '\u202A${profile.bloodType}\u202C',
                    color: AppColors.primary,
                    icon: Icons.bloodtype,
                  ),
                ],
              ),
              if (auth.idNumber.isNotEmpty) ...[
                const SizedBox(height: 10),
                IdVerifiedBadge(auth: auth),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MenuPanel(
                title: context.tr('pr_my_health'),
                children: [
                  MenuRow(
                    icon: Icons.folder_shared_outlined,
                    title: context.tr('health_profile'),
                    onTap: () => context.push('/patient/health-profile'),
                  ),
                  const MyCardRow(),
                  MenuRow(
                    icon: Icons.event_note_outlined,
                    title: context.tr('summons_cards'),
                    onTap: () => context.push('/patient/summons'),
                  ),
                ],
              ),
              MenuPanel(
                title: context.tr('blood_donation'),
                children: [
                  MenuRow(
                    icon: Icons.volunteer_activism_outlined,
                    title: context.tr('pr_donate_blood'),
                    onTap: () => context.push('/blood'),
                  ),
                  // Blood requests live only in the patient's profile.
                  MenuRow(
                    icon: Icons.bloodtype_outlined,
                    title: context.tr('my_blood_requests'),
                    onTap: () => context.push('/patient/blood'),
                  ),
                ],
              ),
              MenuPanel(
                title: context.tr('settings'),
                children: [
                  MenuRow(
                    icon: Icons.notifications_outlined,
                    title: context.tr('notifications'),
                    onTap: () => context.push('/notifications'),
                  ),
                  MenuRow(
                    icon: Icons.tune,
                    title: context.tr('settings'),
                    onTap: () => context.push('/settings'),
                  ),
                  MenuRow(
                    icon: Icons.groups_outlined,
                    title: context.tr('about_association'),
                    onTap: () => context.push('/about'),
                  ),
                  MenuRow(
                    icon: Icons.gavel_outlined,
                    title: context.tr('disclaimer'),
                    onTap: () => context.push('/disclaimer'),
                  ),
                  MenuRow(
                    icon: Icons.support_agent_outlined,
                    title: context.tr('contact_us'),
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LogoutTab(
                label: context.tr('logout'),
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/role');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
