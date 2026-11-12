import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_data.dart';
import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/search.dart';
import '../../../core/summons_provider.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/blood.dart' show maskName;
import '../admin_ui.dart';
import 'overview_section.dart' show Pill, StageBars, stageColor;

IconData caseIcon(CaseKind k) => switch (k) {
  CaseKind.consultation => Icons.forum_outlined,
  CaseKind.blood => Icons.bloodtype_outlined,
  CaseKind.referral => Icons.assignment_ind_outlined,
};

/// "sp_cardio|type_lab" → "قلب • تحاليل".
String needLabel(BuildContext context, String need) => need
    .split('|')
    .map(
      (p) => p.startsWith('sp_') || p.startsWith('type_') ? context.tr(p) : p,
    )
    .join(' • ');

class CasesSection extends ConsumerStatefulWidget {
  const CasesSection({super.key});
  @override
  ConsumerState<CasesSection> createState() => _CasesSectionState();
}

class _CasesSectionState extends ConsumerState<CasesSection> {
  CaseKind? _kind;
  CaseStage? _stage;
  bool _urgentOnly = false;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final all = ref.watch(adminCasesProvider);
    final medical = admin.can(AdminPermission.viewMedicalRecords);
    final list = all
        .where((c) => _kind == null || c.kind == _kind)
        .where((c) => _stage == null || c.stage == _stage)
        .where((c) => !_urgentOnly || c.urgent)
        .where(
          (c) => Search.matches(_q, [
            c.code,
            if (medical) c.patientName,
            c.assignee,
            needLabel(context, c.need),
          ]),
        )
        .toList();

    List<ReportTable> tables() => [
      ReportTable(
        context.tr('ads_cases'),
        [
          context.tr('ad_ref'),
          context.tr('ad_kind'),
          context.tr('ad_patient'),
          context.tr('ad_need'),
          context.tr('ad_stage'),
          context.tr('ad_assignee'),
          context.tr('ad_date'),
        ],
        [
          for (final c in list)
            [
              c.code,
              context.tr('ck_${c.kind.name}'),
              // Exports never contain full names without the permission.
              medical ? c.patientName : maskName(c.patientName),
              needLabel(context, c.need),
              context.tr('cs_${c.stage.name}'),
              c.assignee,
              fmtDate(c.createdAt),
            ],
        ],
      ),
    ];

    return AdminPage(
      title: context.tr('ads_cases'),
      subtitle: context.tr(medical ? 'ad_medical_access' : 'ad_masked_note'),
      actions: [
        if (admin.can(AdminPermission.exportReports))
          ExportButtons(
            title: context.tr('ads_cases'),
            fileName: 'cases',
            tables: tables,
            onExport: () {
              ref
                  .read(adminProvider.notifier)
                  .record(
                    'au_report_exported',
                    target: context.tr('ads_cases'),
                  );
              return true;
            },
          ),
      ],
      children: [
        Panel(
          child: StageBars(
            stages: {
              for (final s in CaseStage.values)
                s: all.where((c) => c.stage == s).length,
            },
          ),
        ),
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<CaseKind>(
          values: [null, ...CaseKind.values],
          selected: _kind,
          label: (v) => context.tr(v == null ? 'all' : 'ck_${v.name}'),
          onSelected: (v) => setState(() => _kind = v),
        ),
        FilterRow<CaseStage>(
          values: [null, ...CaseStage.values],
          selected: _stage,
          label: (v) => context.tr(v == null ? 'all' : 'cs_${v.name}'),
          onSelected: (v) => setState(() => _stage = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _urgentOnly,
          onChanged: (v) => setState(() => _urgentOnly = v),
          title: Text(context.tr('ad_urgent_only')),
        ),
        Text(
          context.tr('ad_results', args: {'n': list.length}),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        for (final c in list)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: stageColor(c.stage).withValues(alpha: .15),
                child: Icon(caseIcon(c.kind), color: stageColor(c.stage)),
              ),
              title: Text(
                '${c.code} • ${medical ? c.patientName : maskName(c.patientName)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${context.tr('ck_${c.kind.name}')} • ${needLabel(context, c.need)}'
                '${c.assignee.isEmpty ? '' : '\n${c.assignee}'}',
              ),
              isThreeLine: c.assignee.isNotEmpty,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Pill(
                    label: context.tr('cs_${c.stage.name}'),
                    color: stageColor(c.stage),
                  ),
                  if (c.urgent)
                    const Icon(
                      Icons.priority_high,
                      color: AppColors.emergency,
                      size: 18,
                    ),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AdminCasePage(caseId: c.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AdminCasePage extends ConsumerStatefulWidget {
  const AdminCasePage({super.key, required this.caseId});
  final String caseId;
  @override
  ConsumerState<AdminCasePage> createState() => _AdminCasePageState();
}

class _AdminCasePageState extends ConsumerState<AdminCasePage> {
  /// The medical file is shown only after a logged, justified opening.
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final c = ref
        .watch(adminCasesProvider)
        .where((x) => x.id == widget.caseId)
        .firstOrNull;
    if (c == null || admin.me == null) return const Scaffold(body: NoAccess());
    final notifier = ref.read(adminProvider.notifier);
    final medical = admin.can(AdminPermission.viewMedicalRecords);
    final canDecide = admin.can(AdminPermission.manageCases);
    final donations = admin.donations.where((d) => d.caseRef == c.id).toList();
    final expenses = admin.expenses.where((e) => e.caseRef == c.id).toList();
    final summons = ref
        .watch(summonsProvider)
        .where((s) => s.sourceId == c.id)
        .toList();

    Future<void> open() async {
      final reason = await askReason(
        context,
        title: context.tr('ad_open_file'),
        label: context.tr('ad_open_reason'),
      );
      if (reason == null || !mounted) return;
      if (guarded(
        this.context,
        () => notifier.openMedicalFile(c.code, reason),
      )) {
        setState(() => _opened = true);
      }
    }

    Future<void> decide(CaseStage stage) async {
      var note = '';
      if (stage == CaseStage.rejected || stage == CaseStage.onHold) {
        final r = await askReason(
          context,
          title: context.tr('cs_${stage.name}'),
        );
        if (r == null) return;
        note = r;
      }
      if (!mounted) return;
      guarded(
        this.context,
        () => notifier.decideCase(c.id, c.code, stage, note),
        ok: 'ad_done',
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(c.code)),
      body: adminCompact(
        context,
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(caseIcon(c.kind), color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${context.tr('ck_${c.kind.name}')} • ${needLabel(context, c.need)}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Pill(
                        label: context.tr('cs_${c.stage.name}'),
                        color: stageColor(c.stage),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.tr('ad_patient')}: ${_opened ? c.patientName : maskName(c.patientName)}',
                  ),
                  Text(
                    '${context.tr('ad_assignee')}: ${c.assignee.isEmpty ? '—' : c.assignee}',
                  ),
                  Text('${context.tr('ad_date')}: ${fmtDateTime(c.createdAt)}'),
                  if (c.decision != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${context.tr('ad_decision')}: ${context.tr('cs_${c.decision!.stage.name}')} — ${c.decision!.by} (${fmtDate(c.decision!.at)})'
                      '${c.decision!.note.isEmpty ? '' : '\n${c.decision!.note}'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            Panel(
              title: context.tr('ad_medical_file'),
              child: _opened
                  ? Text(c.details.isEmpty ? '—' : c.details)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(context.tr('ad_file_locked')),
                        const SizedBox(height: 8),
                        if (medical)
                          FilledButton.icon(
                            onPressed: open,
                            icon: const Icon(Icons.lock_open),
                            label: Text(context.tr('ad_open_file')),
                          )
                        else
                          Text(
                            context.tr('ad_no_access'),
                            style: const TextStyle(color: AppColors.grey),
                          ),
                      ],
                    ),
            ),
            if (canDecide)
              Panel(
                title: context.tr('ad_decision'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in [
                      CaseStage.accepted,
                      CaseStage.onHold,
                      CaseStage.rejected,
                      CaseStage.completed,
                    ])
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: stageColor(s),
                        ),
                        onPressed: c.stage == s ? null : () => decide(s),
                        child: Text(context.tr('cs_${s.name}')),
                      ),
                    if (c.decision != null)
                      TextButton.icon(
                        onPressed: () => guarded(
                          context,
                          () => notifier.clearCaseDecision(c.id, c.code),
                          ok: 'ad_done',
                        ),
                        icon: const Icon(Icons.undo),
                        label: Text(context.tr('ad_clear_decision')),
                      ),
                  ],
                ),
              ),
            if (summons.isNotEmpty)
              Panel(
                title: context.tr('summons_cards'),
                child: Column(
                  children: [
                    for (final s in summons)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(s.issuerName),
                        subtitle: Text(
                          '${fmtDateTime(s.appointment)} • ${s.place}',
                        ),
                      ),
                  ],
                ),
              ),
            if (admin.can(AdminPermission.viewFinance))
              Panel(
                title: context.tr('ad_case_finance'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr('kp_donations')}: ${money(donations.fold(0, (s, d) => s + d.amount))}'
                      ' • ${context.tr('kp_aid')}: ${money(expenses.fold(0, (s, e) => s + e.amount))}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final e in expenses)
                      Text(
                        '• ${context.tr('ec_${e.category.name}')} — ${money(e.amount)} (${fmtDate(e.date)})',
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
