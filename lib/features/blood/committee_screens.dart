import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/blood_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/search.dart';
import '../../core/theme.dart';
import '../../models/blood.dart';
import '../../widgets/common.dart';
import 'blood_screens.dart';

String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// Dashboard of the blood donation committee: reviews donor registrations,
/// keeps the donor database (search by blood type and city) and follows the
/// blood requests patients make from their profile. Only the committee sees
/// full names and phone numbers.
class CommitteeHomeScreen extends ConsumerStatefulWidget {
  const CommitteeHomeScreen({super.key});
  @override
  ConsumerState<CommitteeHomeScreen> createState() =>
      _CommitteeHomeScreenState();
}

class _CommitteeHomeScreenState extends ConsumerState<CommitteeHomeScreen> {
  // Donors tab
  DonorStatus? _donorStatus = DonorStatus.pending;
  String? _donorType;
  String? _donorCity;
  String _donorQuery = '';
  // Requests tab
  BloodRequestStatus? _status;

  @override
  Widget build(BuildContext context) {
    final blood = ref.watch(bloodProvider);
    final pending = blood.donors
        .where((d) => d.status == DonorStatus.pending)
        .length;
    final approved = blood.donors.where((d) => d.isApproved).length;
    final available = blood.donors.where((d) => d.canBeContacted).length;
    final openRequests = blood.requests.where((r) => r.isOpen).length;

    final cities = {for (final d in blood.donors) d.city.trim()}.toList()
      ..sort();
    final donors =
        blood.donors
            .where((d) => _donorStatus == null || d.status == _donorStatus)
            .where((d) => _donorType == null || d.bloodType == _donorType)
            .where((d) => _donorCity == null || d.city.trim() == _donorCity)
            .where(
              (d) => Search.matches(_donorQuery, [
                d.name,
                d.code,
                d.city,
                d.phone,
              ]),
            )
            .toList()
          ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

    final requests =
        blood.requests
            .where((r) => _status == null || r.status == _status)
            .toList()
          ..sort((a, b) {
            int score(BloodRequest r) =>
                (r.isOpen ? 4 : 0) +
                (r.urgent ? 2 : 0) +
                (r.status == BloodRequestStatus.submitted ? 1 : 0);
            final s = score(b).compareTo(score(a));
            return s != 0 ? s : b.createdAt.compareTo(a.createdAt);
          });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('committee_title')),
          actions: [
            IconButton(
              tooltip: context.tr('logout'),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/role');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: '${context.tr('donors_db')} ($pending)'),
              Tab(text: context.tr('my_blood_requests')),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _Stat(
                    value: pending,
                    label: context.tr('pending_reviews'),
                    color: AppColors.warning,
                  ),
                  _Stat(value: approved, label: context.tr('approved_donors')),
                  _Stat(
                    value: available,
                    label: context.tr('available_donors'),
                  ),
                  _Stat(value: openRequests, label: context.tr('requests')),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // ---------------- Donors database ----------------
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _donorQuery = v),
                        decoration: InputDecoration(
                          hintText: context.tr('search_donors_hint'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _chips([
                        _chip(
                          context.tr('all_statuses'),
                          _donorStatus == null,
                          () => setState(() => _donorStatus = null),
                        ),
                        for (final st in DonorStatus.values)
                          _chip(
                            context.tr(donorStatusKey(st)),
                            _donorStatus == st,
                            () => setState(() => _donorStatus = st),
                          ),
                      ]),
                      _chips([
                        _chip(
                          context.tr('all'),
                          _donorType == null,
                          () => setState(() => _donorType = null),
                        ),
                        for (final t in bloodTypes)
                          _chip(
                            t,
                            _donorType == t,
                            () => setState(() => _donorType = t),
                          ),
                      ]),
                      _chips([
                        _chip(
                          context.tr('all_cities'),
                          _donorCity == null,
                          () => setState(() => _donorCity = null),
                        ),
                        for (final c in cities)
                          _chip(
                            c,
                            _donorCity == c,
                            () => setState(() => _donorCity = c),
                          ),
                      ]),
                      const SizedBox(height: 8),
                      if (donors.isEmpty)
                        EmptyState(
                          icon: Icons.person_search_outlined,
                          message: context.tr('none'),
                        ),
                      for (final d in donors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CommitteeDonorCard(donor: d, showReview: true),
                        ),
                    ],
                  ),

                  // ---------------- Blood requests (from patients) ----------
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _chips([
                        _chip(
                          context.tr('all_statuses'),
                          _status == null,
                          () => setState(() => _status = null),
                        ),
                        for (final st in BloodRequestStatus.values)
                          _chip(
                            context.tr(bloodStatusKey(st)),
                            _status == st,
                            () => setState(() => _status = st),
                          ),
                      ]),
                      const SizedBox(height: 8),
                      if (requests.isEmpty)
                        EmptyState(
                          icon: Icons.inbox_outlined,
                          message: context.tr('no_requests'),
                        ),
                      for (final r in requests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BloodRequestCard(
                            request: r,
                            forCommittee: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(List<Widget> chips) => SizedBox(
    height: 46,
    child: ListView(scrollDirection: Axis.horizontal, children: chips),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});
  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: c, fontWeight: FontWeight.w900),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Donor with full personal data (committee only): review buttons for new
/// registrations, contact buttons for accepted donors.
class CommitteeDonorCard extends ConsumerWidget {
  const CommitteeDonorCard({
    super.key,
    required this.donor,
    this.trailing,
    this.badges = const [],
    this.showReview = false,
  });
  final BloodDonor donor;
  final Widget? trailing;
  final List<Widget> badges;
  final bool showReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = donor;
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(bloodProvider.notifier);

    void review(DonorStatus status, String messageKey) {
      notifier.reviewDonor(d.id, status);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(messageKey))));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BloodTypeBadge(d.bloodType, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.code} • ${d.name}',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${d.city} • ${context.tr('kind_${d.kind.name}')} • ${context.tr('registered_on', args: {'date': _date(d.registeredAt)})}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...badges,
                DonorStatusPill(d.status),
                if (d.isApproved)
                  d.available
                      ? Pill(
                          label: context.tr('available_to_donate'),
                          color: AppColors.success,
                        )
                      : Pill(
                          label: context.tr('unavailable_now'),
                          color: AppColors.grey,
                        ),
              ],
            ),
            const SizedBox(height: 10),
            ContactButtons(phone: d.phone, preferred: d.contact),
            if (showReview) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (d.status != DonorStatus.approved)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () =>
                            review(DonorStatus.approved, 'donor_approved_msg'),
                        icon: const Icon(Icons.check),
                        label: Text(context.tr('approve')),
                      ),
                    ),
                  if (d.status == DonorStatus.pending) const SizedBox(width: 8),
                  if (d.status != DonorStatus.rejected)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: AppColors.grey,
                        ),
                        onPressed: () =>
                            review(DonorStatus.rejected, 'donor_rejected_msg'),
                        icon: const Icon(Icons.close),
                        label: Text(context.tr('reject')),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Committee view of a request: requester contact, status, suggested donors
/// and linking.
class CommitteeRequestScreen extends ConsumerWidget {
  const CommitteeRequestScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blood = ref.watch(bloodProvider);
    final r = blood.request(id);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.search_off,
          message: context.tr('no_requests'),
        ),
      );
    }
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(bloodProvider.notifier);
    final linked = [
      for (final id in r.assignedDonorIds)
        if (blood.donor(id) != null) blood.donor(id)!,
    ];
    final suggested = matchDonors(
      r,
      blood.donors,
    ).where((d) => !r.assignedDonorIds.contains(d.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${context.tr('request_code')} ${r.code}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BloodTypeBadge(r.bloodType, size: 62),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.patientName,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text('${r.hospital} • ${r.city}'),
                            Text(
                              context.timeAgo(r.createdAt),
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (r.isOpen && r.urgent)
                        Pill(
                          label: context.tr('urgency_urgent'),
                          color: AppColors.emergency,
                          icon: Icons.bolt,
                        ),
                      Pill(
                        label: context.tr('units_n', args: {'n': r.units}),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  if (r.note.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(r.note),
                  ],
                  const Divider(height: 28),
                  Text(
                    context.tr('requester'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${r.requesterName} • ${context.tr('relation_${r.relation.name}')}',
                  ),
                  const SizedBox(height: 10),
                  ContactButtons(phone: r.phone, preferred: r.contact),
                ],
              ),
            ),
          ),

          // Status
          SectionHeader(context.tr('request_status')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final st in BloodRequestStatus.values)
                ChoiceChip(
                  label: Text(context.tr(bloodStatusKey(st))),
                  selected: r.status == st,
                  selectedColor: bloodStatusColor(st),
                  labelStyle: TextStyle(
                    color: r.status == st
                        ? AppColors.on(bloodStatusColor(st))
                        : null,
                    fontWeight: FontWeight.w700,
                  ),
                  showCheckmark: false,
                  onSelected: (_) => notifier.setStatus(r.id, st),
                ),
            ],
          ),

          // Linked donors
          SectionHeader('${context.tr('linked_donors')} (${linked.length})'),
          if (linked.isEmpty)
            Text(context.tr('none'))
          else
            for (final d in linked)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommitteeDonorCard(
                  donor: d,
                  badges: [
                    Pill(
                      label: context.tr('linked_n', args: {'n': 1}),
                      color: AppColors.primary,
                      icon: Icons.link,
                    ),
                  ],
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.grey,
                    ),
                    onPressed: () => notifier.unassignDonor(r.id, d.id),
                    child: Text(context.tr('unlink')),
                  ),
                ),
              ),

          // Suggestions
          if (r.isOpen) ...[
            SectionHeader(
              '${context.tr('suggested_donors')} (${suggested.length})',
            ),
            if (suggested.isEmpty)
              Text(context.tr('no_matching_donors'))
            else
              for (final d in suggested)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CommitteeDonorCard(
                    donor: d,
                    badges: [
                      if (d.city.trim().toLowerCase() ==
                          r.city.trim().toLowerCase())
                        Pill(
                          label: context.tr('same_city'),
                          color: AppColors.primary,
                          icon: Icons.place_outlined,
                        ),
                      Pill(
                        label: context.tr(
                          d.bloodType == r.bloodType
                              ? 'exact_type'
                              : 'compatible',
                        ),
                        color: AppColors.info,
                        icon: Icons.check,
                      ),
                    ],
                    trailing: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        notifier.assignDonor(r.id, d.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('donor_linked'))),
                        );
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(context.tr('link')),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppColors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('committee_only'),
                  style: text.bodySmall?.copyWith(color: AppColors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
