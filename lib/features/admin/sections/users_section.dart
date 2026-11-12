import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_provider.dart';
import '../../../core/facility_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/member_card_provider.dart';
import '../../../core/providers.dart';
import '../../../core/search.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/blood.dart' show maskPhone;
import '../../../models/facility.dart';
import '../../../models/member_card.dart';
import '../../../models/models.dart';
import '../../../models/registration.dart';
import '../../../widgets/media.dart';
import '../../cards/member_card_screens.dart';
import '../../facility/facility_screens.dart'
    show
        FacilityHistory,
        FacilityReviewPanel,
        CooperationChips,
        facilityTypeKey;
import '../admin_ui.dart';
import 'overview_section.dart' show Pill;

/// Patients, volunteer doctors, medical facilities and their cards.
class UsersSection extends ConsumerStatefulWidget {
  const UsersSection({super.key});
  @override
  ConsumerState<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<UsersSection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final regs = ref.watch(registrationsProvider);
    final facilities = ref.watch(facilityProvider).facilities;
    final cards = ref.watch(memberCardsProvider);
    int pending(bool doctor) => regs
        .where((r) => r.isDoctor == doctor && r.status == ReviewStatus.pending)
        .length;
    final tabs = [
      '${context.tr('patients')} (${pending(false)})',
      '${context.tr('doctors')} (${pending(true)})',
      '${context.tr('facilities')} (${facilities.where((f) => f.status == FacilityStatus.pending).length})',
      '${context.tr('mc_title')} (${cards.length})',
    ];
    return AdminPage(
      title: context.tr('ads_users'),
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < tabs.length; i++)
              ButtonSegment(value: i, label: Text(tabs[i])),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 12),
        switch (_tab) {
          0 => const _PeopleList(doctors: false),
          1 => const _PeopleList(doctors: true),
          2 => const _FacilityList(),
          _ => const _CardsList(),
        },
      ],
    );
  }
}

enum _UserFilter { pending, approved, rejected, suspended }

class _PeopleList extends ConsumerStatefulWidget {
  const _PeopleList({required this.doctors});
  final bool doctors;
  @override
  ConsumerState<_PeopleList> createState() => _PeopleListState();
}

class _PeopleListState extends ConsumerState<_PeopleList> {
  _UserFilter? _filter = _UserFilter.pending;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final all = ref.watch(registrationsProvider);
    final list = all
        .where((r) => r.isDoctor == widget.doctors)
        .where((r) {
          final suspended = admin.suspendedAccounts.containsKey(r.id);
          return switch (_filter) {
            null => true,
            _UserFilter.suspended => suspended,
            _UserFilter.pending => r.status == ReviewStatus.pending,
            _UserFilter.approved =>
              r.status == ReviewStatus.approved && !suspended,
            _UserFilter.rejected => r.status == ReviewStatus.rejected,
          };
        })
        .where(
          (r) => Search.matches(_q, [
            r.name,
            r.code,
            r.phone,
            r.idNumber,
            if (r.specialtyId != null) context.tr('sp_${r.specialtyId}'),
          ]),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<_UserFilter>(
          values: [null, ..._UserFilter.values],
          selected: _filter,
          label: (v) => context.tr(v == null ? 'all' : 'uf_${v.name}'),
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty) Text(context.tr('ad_empty')),
        for (final r in list) _PersonCard(registration: r, all: all),
      ],
    );
  }
}

class _PersonCard extends ConsumerWidget {
  const _PersonCard({required this.registration, required this.all});
  final Registration registration;
  final List<Registration> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = registration;
    final admin = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);
    final canReview = admin.can(AdminPermission.manageRegistrations);
    final canSuspend = admin.can(AdminPermission.suspendAccounts);
    final suspended = admin.suspendedAccounts[r.id];
    final duplicates = possibleDuplicates(r, all);
    final files = [?r.idFront, ?r.idBack, ?r.certificate];

    void review(ReviewStatus status) {
      guarded(
        context,
        () {
          notifier.authorize(AdminPermission.manageRegistrations);
          ref.read(registrationsProvider.notifier).review(r.id, status);
          notifier.record(
            status == ReviewStatus.approved ? 'au_approve' : 'au_reject',
            target: '${r.code} ${r.name}',
          );
        },
        ok: status == ReviewStatus.approved
            ? 'account_approved_msg'
            : 'account_rejected_msg',
      );
    }

    Future<void> suspend() async {
      final reason = await askReason(
        context,
        title: context.tr('ad_suspend_account'),
      );
      if (reason == null || !context.mounted) return;
      guarded(
        context,
        () => notifier.suspendAccount(r.id, '${r.code} ${r.name}', reason),
        ok: 'ad_done',
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  r.isDoctor
                      ? Icons.medical_services_outlined
                      : Icons.person_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r.code} • ${r.name}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      [
                        if (r.specialtyId != null)
                          context.tr('sp_${r.specialtyId}'),
                        if (r.licenseNumber != null) r.licenseNumber!,
                        // Contact details only for registration officers.
                        canReview ? r.phone : maskPhone(r.phone),
                        fmtDate(r.createdAt),
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Pill(
                label: context.tr('review_${r.status.name}'),
                color: switch (r.status) {
                  ReviewStatus.pending => AppColors.warning,
                  ReviewStatus.approved => AppColors.success,
                  ReviewStatus.rejected => AppColors.grey,
                },
              ),
              if (suspended != null)
                Pill(
                  label: context.tr('uf_suspended'),
                  color: AppColors.emergency,
                ),
              if (!r.phoneVerified)
                Pill(
                  label: context.tr('phone_not_verified'),
                  color: AppColors.warning,
                ),
              if (duplicates.isNotEmpty)
                Pill(
                  label:
                      '${context.tr('dup_warning')}: ${duplicates.map((d) => d.code).join('، ')}',
                  color: AppColors.emergency,
                ),
            ],
          ),
          if (suspended != null) ...[
            const SizedBox(height: 6),
            Text(
              '${context.tr('ad_reason')}: $suspended',
              style: const TextStyle(color: AppColors.emergency),
            ),
          ],
          if (canReview && files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in files)
                  InkWell(
                    onTap: () {
                      notifier.record(
                        'au_document_viewed',
                        target: '${r.code} ${f.name}',
                        sensitive: true,
                      );
                      showAttachmentPreview(context, f);
                    },
                    child: AttachmentThumb(f, size: 56),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (canReview && r.status != ReviewStatus.approved)
                FilledButton.icon(
                  onPressed: () => review(ReviewStatus.approved),
                  icon: const Icon(Icons.check),
                  label: Text(context.tr('approve')),
                ),
              if (canReview && r.status == ReviewStatus.pending)
                OutlinedButton.icon(
                  onPressed: () => review(ReviewStatus.rejected),
                  icon: const Icon(Icons.close),
                  label: Text(context.tr('reject')),
                ),
              if (canSuspend && r.status == ReviewStatus.approved)
                suspended == null
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emergency,
                        ),
                        onPressed: suspend,
                        icon: const Icon(Icons.block),
                        label: Text(context.tr('ad_suspend_account')),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: () => guarded(
                          context,
                          () => notifier.reactivateAccount(
                            r.id,
                            '${r.code} ${r.name}',
                          ),
                          ok: 'ad_done',
                        ),
                        icon: const Icon(Icons.lock_open),
                        label: Text(context.tr('ad_reactivate_account')),
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Facilities (approval with the verification checklist)
// ---------------------------------------------------------------------------

class _FacilityList extends ConsumerStatefulWidget {
  const _FacilityList();
  @override
  ConsumerState<_FacilityList> createState() => _FacilityListState();
}

class _FacilityListState extends ConsumerState<_FacilityList> {
  FacilityStatus? _filter = FacilityStatus.pending;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final list = ref
        .watch(facilityProvider)
        .facilities
        .where((f) => _filter == null || f.status == _filter)
        .where(
          (f) => Search.matches(_q, [f.name, f.city, f.code, f.licenseNumber]),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<FacilityStatus>(
          values: [null, ...FacilityStatus.values],
          selected: _filter,
          label: (v) => context.tr(v == null ? 'all' : 'fs_${v.name}'),
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty) Text(context.tr('ad_empty')),
        for (final f in list)
          Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.local_hospital_outlined, color: Colors.white),
              ),
              title: Text(
                '${f.code} • ${f.name}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr(facilityTypeKey(f.type))} • ${f.city} • ${f.licenseNumber}',
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Pill(
                        label: context.tr('fs_${f.status.name}'),
                        color: switch (f.status) {
                          FacilityStatus.pending => AppColors.warning,
                          FacilityStatus.needsInfo => AppColors.info,
                          FacilityStatus.approved => AppColors.success,
                          FacilityStatus.rejected => AppColors.grey,
                        },
                      ),
                      if (admin.suspendedAccounts.containsKey(f.id))
                        Pill(
                          label: context.tr('uf_suspended'),
                          color: AppColors.emergency,
                        ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminFacilityPage(facilityId: f.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AdminFacilityPage extends ConsumerWidget {
  const AdminFacilityPage({super.key, required this.facilityId});
  final String facilityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminProvider);
    final f = ref.watch(facilityProvider).facility(facilityId);
    if (f == null || admin.me == null) return const Scaffold(body: NoAccess());
    final notifier = ref.read(adminProvider.notifier);
    final canReview =
        admin.can(AdminPermission.manageRegistrations) ||
        admin.can(AdminPermission.manageFacilities);
    final suspended = admin.suspendedAccounts[f.id];
    return Scaffold(
      appBar: AppBar(title: Text(f.name)),
      body: adminCompact(
        context,
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${f.code} • ${context.tr(facilityTypeKey(f.type))}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text('${context.tr('facility_manager')}: ${f.managerName}'),
                  Text('${context.tr('facility_license')}: ${f.licenseNumber}'),
                  Text('${context.tr('address')}: ${f.city} — ${f.address}'),
                  Text('${context.tr('phone')}: ${f.phone}'),
                  if (f.services.isNotEmpty)
                    Text(
                      '${context.tr('facility_services')}: ${f.services.join('، ')}',
                    ),
                  const SizedBox(height: 8),
                  CooperationChips(facility: f),
                  if (canReview &&
                      (f.licenseDocument != null ||
                          f.documents.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final d in [?f.licenseDocument, ...f.documents])
                          InkWell(
                            onTap: () {
                              notifier.record(
                                'au_document_viewed',
                                target: '${f.code} ${d.name}',
                                sensitive: true,
                              );
                              showAttachmentPreview(context, d);
                            },
                            child: AttachmentThumb(d, size: 56),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (canReview)
              FacilityReviewPanel(
                facility: f,
                onDecided: (decision, note) => notifier.record(
                  'au_facility_${decision.name}',
                  target: '${f.code} ${f.name}',
                  details: note,
                ),
              ),
            const SizedBox(height: 10),
            FacilityHistory(facility: f),
            if (f.isApproved && admin.can(AdminPermission.suspendAccounts)) ...[
              const SizedBox(height: 10),
              suspended == null
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emergency,
                      ),
                      onPressed: () async {
                        final reason = await askReason(
                          context,
                          title: context.tr('ad_suspend_account'),
                        );
                        if (reason == null || !context.mounted) return;
                        guarded(
                          context,
                          () => notifier.suspendAccount(
                            f.id,
                            '${f.code} ${f.name}',
                            reason,
                          ),
                          ok: 'ad_done',
                        );
                      },
                      icon: const Icon(Icons.block),
                      label: Text(context.tr('ad_suspend_account')),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: () => guarded(
                        context,
                        () => notifier.reactivateAccount(
                          f.id,
                          '${f.code} ${f.name}',
                        ),
                        ok: 'ad_done',
                      ),
                      icon: const Icon(Icons.lock_open),
                      label: Text(
                        '${context.tr('ad_reactivate_account')} ($suspended)',
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Registration cards: follow-up, renewal, suspension
// ---------------------------------------------------------------------------

enum _CardFilter { valid, expiring, expired, suspended }

class _CardsList extends ConsumerStatefulWidget {
  const _CardsList();
  @override
  ConsumerState<_CardsList> createState() => _CardsListState();
}

class _CardsListState extends ConsumerState<_CardsList> {
  _CardFilter? _filter;
  MemberKind? _kind;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final now = DateTime.now();
    final list = ref
        .watch(memberCardsProvider)
        .where((c) => _kind == null || c.kind == _kind)
        .where(
          (c) => switch (_filter) {
            null => true,
            _CardFilter.suspended => c.suspended,
            _CardFilter.expired => c.isExpired(now),
            _CardFilter.expiring =>
              !c.isExpired(now) && c.expiresAt.difference(now).inDays <= 30,
            _CardFilter.valid => !c.suspended && !c.isExpired(now),
          },
        )
        .where((c) => Search.matches(_q, [c.name, c.number, c.city]))
        .toList();
    final canManage = admin.can(AdminPermission.manageCards);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<MemberKind>(
          values: [null, ...MemberKind.values],
          selected: _kind,
          label: (v) => context.tr(v == null ? 'all' : 'mc_kind_${v.name}'),
          onSelected: (v) => setState(() => _kind = v),
        ),
        FilterRow<_CardFilter>(
          values: [null, ..._CardFilter.values],
          selected: _filter,
          label: (v) => context.tr(v == null ? 'all' : 'cf_${v.name}'),
          onSelected: (v) => setState(() => _filter = v),
        ),
        const SizedBox(height: 8),
        if (list.isEmpty) Text(context.tr('ad_empty')),
        for (final c in list)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${c.number} • ${c.name}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Pill(
                      label: context.tr(
                        c.suspended
                            ? 'cc_suspended'
                            : c.isExpired(now)
                            ? 'cc_expired'
                            : 'cc_valid',
                      ),
                      color: c.suspended
                          ? AppColors.emergency
                          : c.isExpired(now)
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
                Text(
                  '${context.tr('mc_kind_${c.kind.name}')} • ${context.tr('mc_expires')}: ${fmtDate(c.expiresAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _AdminCardPage(holderId: c.holderId),
                        ),
                      ),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(context.tr('mc_view')),
                    ),
                    if (canManage)
                      TextButton.icon(
                        onPressed: () => guarded(
                          context,
                          () => ref
                              .read(adminProvider.notifier)
                              .renewCard(c.holderId, c.number),
                          ok: 'ad_card_renewed',
                        ),
                        icon: const Icon(Icons.autorenew),
                        label: Text(context.tr('ad_renew')),
                      ),
                    if (canManage)
                      TextButton.icon(
                        onPressed: () => guarded(context, () {
                          final n = ref.read(adminProvider.notifier);
                          n.authorize(AdminPermission.manageCards);
                          final s = ref.read(suspendedCardsProvider.notifier);
                          if (ref
                              .read(suspendedCardsProvider)
                              .contains(c.number)) {
                            s.reactivate(c.number);
                            n.record('au_card_reactivated', target: c.number);
                          } else {
                            s.suspend(c.number);
                            n.record('au_card_suspended', target: c.number);
                          }
                        }, ok: 'ad_done'),
                        icon: const Icon(Icons.block),
                        label: Text(
                          context.tr(
                            ref.watch(suspendedCardsProvider).contains(c.number)
                                ? 'mc_reactivate'
                                : 'mc_suspend',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AdminCardPage extends ConsumerWidget {
  const _AdminCardPage({required this.holderId});
  final String holderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref
        .watch(memberCardsProvider)
        .where((c) => c.holderId == holderId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mc_title'))),
      body: adminCompact(
        context,
        card == null
            ? const NoAccess()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: MemberCardView(card: card),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => downloadMemberCard(context, card),
                        icon: const Icon(Icons.download),
                        label: Text(context.tr('summons_download')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => printMemberCard(context, card),
                        icon: const Icon(Icons.print_outlined),
                        label: Text(context.tr('summons_print')),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Used by other sections: display name of a user or facility id.
String holderName(WidgetRef ref, String id) {
  for (final r in ref.read(registrationsProvider)) {
    if (r.id == id) return '${r.code} ${r.name}';
  }
  final f = ref.read(facilityProvider).facility(id);
  return f == null ? id : '${f.code} ${f.name}';
}

/// Approved users and facilities that can receive a message.
List<(String, String, MessageAudience)> messageTargets(WidgetRef ref) => [
  for (final r in ref.read(registrationsProvider))
    if (r.status == ReviewStatus.approved)
      (
        r.id,
        '${r.code} ${r.name}',
        r.role == UserRole.doctor
            ? MessageAudience.doctors
            : MessageAudience.patients,
      ),
  for (final f in ref.read(facilityProvider).facilities)
    if (f.isApproved) (f.id, '${f.code} ${f.name}', MessageAudience.facilities),
];
