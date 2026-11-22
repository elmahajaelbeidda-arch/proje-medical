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
import '../../widgets/shifa_ui.dart';
import '../../widgets/voice_search.dart';

Doctor get _me => MockData.doctorById(MockData.currentDoctorId)!;

class DoctorShell extends StatefulWidget {
  const DoctorShell({super.key});
  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DoctorHomeTab(onSeeRequests: () => setState(() => _index = 1)),
          const OpenRequestsTab(),
          const MyCasesTab(),
          const DoctorProfileTab(),
        ],
      ),
      // Main action in the middle: the open requests waiting for a doctor.
      bottomNavigationBar: ShifaBottomBar(
        selected: switch (_index) {
          0 => 0,
          2 => 1,
          3 => 3,
          _ => -1,
        },
        onSelected: (i) {
          if (i == 2) {
            context.push('/notifications');
            return;
          }
          setState(() => _index = const [0, 2, -1, 3][i]);
        },
        centerIcon: LucideIcons.inbox,
        centerLabel: context.tr('nav_requests'),
        onCenter: () => setState(() => _index = 1),
        items: [
          ShifaNavItem(
            LucideIcons.layoutDashboard,
            LucideIcons.layoutDashboard,
            context.tr('nav_dashboard'),
          ),
          ShifaNavItem(
            LucideIcons.folderOpen,
            LucideIcons.folderOpen,
            context.tr('nav_cases'),
          ),
          ShifaNavItem(
            LucideIcons.bell,
            LucideIcons.bell,
            context.tr('notifications'),
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
// Dashboard
// ---------------------------------------------------------------------------

class DoctorHomeTab extends ConsumerWidget {
  const DoctorHomeTab({super.key, required this.onSeeRequests});
  final VoidCallback onSeeRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(consultationsProvider);
    final available = ref.watch(doctorAvailableProvider);
    final auth = ref.watch(authProvider);
    final pendingMine = all
        .where(
          (c) =>
              c.status == ConsultationStatus.pending &&
              c.specialtyId == _me.specialtyId,
        )
        .toList();
    final urgent =
        all.where((c) => c.status == ConsultationStatus.pending).toList()
          ..sort((a, b) => b.urgency.index.compareTo(a.urgency.index));
    final helped = all
        .where(
          (c) =>
              c.doctorId == MockData.currentDoctorId &&
              c.status == ConsultationStatus.answered,
        )
        .length;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              DoctorAvatar(_me, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.displayName,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.tr(Specialty.byId(_me.specialtyId).key),
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => context.push('/notifications'),
                icon: Badge(
                  smallSize: 8,
                  backgroundColor: AppColors.accent,
                  child: Icon(LucideIcons.bell),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AccountReviewBanner(),
          Card(
            child: SwitchListTile(
              value: available,
              onChanged: (v) =>
                  ref.read(doctorAvailableProvider.notifier).set(v),
              secondary: Icon(
                LucideIcons.circle,
                size: 14,
                color: available ? AppColors.success : AppColors.grey,
              ),
              title: Text(
                context.tr('available_for_cases'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.handHeart,
                  color: AppColors.onPrimary,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('thank_you_doctor', args: {'n': 23 + helped}),
                    style: text.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: LucideIcons.heart,
                  value: '${_me.consultationsCount + helped}',
                  label: context.tr('helped_patients'),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.star,
                  value: '${_me.rating}',
                  label: context.tr('rating'),
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  icon: LucideIcons.inbox,
                  value: '${pendingMine.length}',
                  label: context.tr('waiting_in_specialty'),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              onTap: () => context.push('/blood'),
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(LucideIcons.droplet, color: AppColors.turquoise),
              ),
              title: Text(
                context.tr('blood_donation'),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              subtitle: Text(context.tr('donor_section_intro'), maxLines: 2),
              trailing: const Icon(LucideIcons.chevronRightDir),
            ),
          ),
          const SizedBox(height: 8),
          SectionHeader(
            context.tr('urgent_requests'),
            action: context.tr('see_all'),
            onAction: onSeeRequests,
          ),
          if (urgent.isEmpty)
            EmptyState(
              icon: LucideIcons.inbox,
              message: context.tr('no_requests'),
            )
          else
            for (final c in urgent.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ConsultationCard(
                  consultation: c,
                  showPatient: true,
                  onTap: () => context.push('/doctor/request/${c.id}'),
                ),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Open requests
// ---------------------------------------------------------------------------

class OpenRequestsTab extends ConsumerStatefulWidget {
  const OpenRequestsTab({super.key});
  @override
  ConsumerState<OpenRequestsTab> createState() => _OpenRequestsTabState();
}

class _OpenRequestsTabState extends ConsumerState<OpenRequestsTab> {
  String? _specialty = _me.specialtyId;
  bool _urgentOnly = false;
  String _query = '';

  bool _matchesQuery(Consultation c) {
    final sp = Specialty.byId(c.specialtyId).key;
    return Search.matches(_query, [
      c.symptoms,
      c.displayPatientName,
      AppStrings.of('ar', sp),
      AppStrings.of('fr', sp),
      AppStrings.of('en', sp),
      AppStrings.of('ar', typeKey(c.type)),
      AppStrings.of('fr', typeKey(c.type)),
      AppStrings.of('en', typeKey(c.type)),
      AppStrings.of('ar', urgencyKey(c.urgency)),
      AppStrings.of('fr', urgencyKey(c.urgency)),
      AppStrings.of('en', urgencyKey(c.urgency)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref
            .watch(consultationsProvider)
            .where((c) => c.status == ConsultationStatus.pending)
            // A search looks through every specialty.
            .where(
              (c) =>
                  _query.isNotEmpty ||
                  _specialty == null ||
                  c.specialtyId == _specialty,
            )
            .where((c) => !_urgentOnly || c.urgency == Urgency.urgent)
            .where(_matchesQuery)
            .toList()
          ..sort((a, b) {
            final u = b.urgency.index.compareTo(a.urgency.index);
            return u != 0 ? u : b.createdAt.compareTo(a.createdAt);
          });

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nav_requests'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: VoiceSearchField(
              hintKey: 'search_requests',
              exampleKey: 'voice_search_example_request',
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
                  child: FilterChip(
                    avatar: const Icon(LucideIcons.zap, size: 18),
                    label: Text(context.tr('urgency_urgent')),
                    selected: _urgentOnly,
                    onSelected: (v) => setState(() => _urgentOnly = v),
                  ),
                ),
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
            child: items.isEmpty
                ? EmptyState(
                    icon: LucideIcons.inbox,
                    message: _query.isEmpty
                        ? context.tr('no_requests')
                        : context.tr('no_results', args: {'q': _query}),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ConsultationCard(
                      consultation: items[i],
                      showPatient: true,
                      onTap: () =>
                          context.push('/doctor/request/${items[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My cases
// ---------------------------------------------------------------------------

class MyCasesTab extends ConsumerWidget {
  const MyCasesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref
        .watch(consultationsProvider)
        .where((c) => c.doctorId == MockData.currentDoctorId)
        .toList();
    final progress = mine
        .where((c) => c.status == ConsultationStatus.accepted)
        .toList();
    final answered = mine
        .where((c) => c.status != ConsultationStatus.accepted)
        .toList();

    Widget list(List<Consultation> items) {
      if (items.isEmpty) {
        return EmptyState(
          icon: LucideIcons.folderOpen,
          message: context.tr('no_requests'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => ConsultationCard(
          consultation: items[i],
          showPatient: true,
          onTap: () => context.push('/doctor/request/${items[i].id}'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('nav_cases')),
          bottom: TabBar(
            tabs: [
              Tab(text: '${context.tr('in_progress')} (${progress.length})'),
              Tab(text: '${context.tr('answered')} (${answered.length})'),
            ],
          ),
        ),
        body: TabBarView(children: [list(progress), list(answered)]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------

class DoctorProfileTab extends ConsumerWidget {
  const DoctorProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
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
              _me.initials,
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
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
              Text(
                '${context.tr(Specialty.byId(_me.specialtyId).key)} • ${_me.cityFor(Localizations.localeOf(context).languageCode)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.turquoise,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Pill(
                label: context.tr('verified_doctor'),
                color: AppColors.info,
                icon: LucideIcons.badgeCheck,
              ),
              if (auth.idNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
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
                title: context.tr('professional_profile'),
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_me.bio, style: const TextStyle(height: 1.6)),
                        const SizedBox(height: 8),
                        Text(
                          '${context.tr('experience')}: ${_me.yearsOfExperience} ${context.tr('years')}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('availability_hours'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in _me.availability)
                              Chip(label: Text(a)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              MenuPanel(
                title: context.tr('settings'),
                children: [
                  const MyCardRow(),
                  MenuRow(
                    icon: LucideIcons.bell,
                    title: context.tr('notifications'),
                    onTap: () => context.push('/notifications'),
                  ),
                  MenuRow(
                    icon: LucideIcons.slidersHorizontal,
                    title: context.tr('settings'),
                    onTap: () => context.push('/settings'),
                  ),
                  MenuRow(
                    icon: LucideIcons.heartHandshake,
                    title: context.tr('pl_name'),
                    onTap: () => context.push('/pulse'),
                  ),
                  MenuRow(
                    icon: LucideIcons.users,
                    title: context.tr('about_association'),
                    onTap: () => context.push('/about'),
                  ),
                  MenuRow(
                    icon: LucideIcons.gavel,
                    title: context.tr('disclaimer'),
                    onTap: () => context.push('/disclaimer'),
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
