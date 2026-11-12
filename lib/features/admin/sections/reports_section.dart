import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_data.dart';
import '../../../core/admin_provider.dart';
import '../../../core/blood_provider.dart';
import '../../../core/facility_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/member_card_provider.dart';
import '../../../core/providers.dart';
import '../../../core/psych_provider.dart';
import '../../../core/summons_provider.dart';
import '../../../models/admin.dart';
import '../../../models/blood.dart';
import '../../../models/facility.dart';
import '../../../models/member_card.dart';
import '../../../models/models.dart';
import '../../../models/psych.dart';
import '../../../models/registration.dart';
import '../admin_ui.dart';
import 'finance_section.dart' show Period, inPeriod;

/// Global statistics, downloadable as PDF or Excel.
class ReportsSection extends ConsumerStatefulWidget {
  const ReportsSection({super.key});
  @override
  ConsumerState<ReportsSection> createState() => _ReportsSectionState();
}

class _ReportsSectionState extends ConsumerState<ReportsSection> {
  Period _period = Period.all;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final regs = ref.watch(registrationsProvider);
    final facilities = ref.watch(facilityProvider);
    final cases = ref.watch(adminCasesProvider);
    final consultations = ref.watch(consultationsProvider);
    final blood = ref.watch(bloodProvider);
    final psych = ref.watch(psychProvider);
    final summons = ref.watch(summonsProvider);
    final cards = ref.watch(memberCardsProvider);
    final activity = ref.watch(doctorActivityProvider);

    bool p(DateTime d) => inPeriod(d, _period);
    final pc = cases.where((c) => p(c.createdAt)).toList();
    final donations = admin.donations.where((d) => p(d.date)).toList();
    final expenses = admin.expenses.where((e) => p(e.date)).toList();
    final finance = admin.can(AdminPermission.viewFinance);

    final rows = <(String, Object)>[
      (
        context.tr('kp_patients'),
        regs.where((r) => !r.isDoctor && p(r.createdAt)).length,
      ),
      (
        context.tr('kp_patients_approved'),
        regs
            .where((r) => !r.isDoctor && r.status == ReviewStatus.approved)
            .length,
      ),
      (
        context.tr('kp_beneficiaries'),
        pc
            .where((c) => c.stage == CaseStage.completed)
            .map((c) => c.patientName)
            .toSet()
            .length,
      ),
      (context.tr('kp_doctors'), ref.watch(approvedDoctorsCountProvider)),
      (
        context.tr('kp_facilities'),
        facilities.facilities.where((f) => f.isApproved).length,
      ),
      (
        context.tr('kp_cards'),
        cards.where((c) => !c.suspended && !c.isExpired()).length,
      ),
      (context.tr('kp_cases_total'), pc.length),
      (
        context.tr('kp_cases_done'),
        pc.where((c) => c.stage == CaseStage.completed).length,
      ),
      (
        context.tr('kp_consultations'),
        consultations.where((c) => p(c.createdAt)).length,
      ),
      (
        context.tr('kp_consult_answered'),
        consultations
            .where(
              (c) =>
                  p(c.createdAt) &&
                  (c.status == ConsultationStatus.answered ||
                      c.status == ConsultationStatus.closed),
            )
            .length,
      ),
      (
        context.tr('kp_referrals'),
        facilities.referrals.where((r) => p(r.createdAt)).length,
      ),
      (
        context.tr('kp_referrals_done'),
        facilities.referrals
            .where(
              (r) => p(r.createdAt) && r.status == ReferralStatus.completed,
            )
            .length,
      ),
      (
        context.tr('kp_blood'),
        blood.requests.where((r) => p(r.createdAt)).length,
      ),
      (
        context.tr('kp_blood_done'),
        blood.requests
            .where(
              (r) => p(r.createdAt) && r.status == BloodRequestStatus.fulfilled,
            )
            .length,
      ),
      (
        context.tr('kp_psych'),
        psych
            .where((s) => p(s.createdAt) && s.status == PsychStatus.completed)
            .length,
      ),
      (context.tr('kp_summons'), summons.where((s) => p(s.issuedAt)).length),
      if (finance) ...[
        (
          context.tr('kp_donations'),
          money(donations.fold(0, (s, d) => s + d.amount)),
        ),
        (context.tr('kp_aid'), money(expenses.fold(0, (s, e) => s + e.amount))),
      ],
    ];

    List<ReportTable> tables() => [
      ReportTable(
        context.tr('ad_stats'),
        [context.tr('ad_item'), context.tr('ad_value')],
        [
          [context.tr('ad_period'), context.tr('pe_${_period.name}')],
          for (final r in rows) [r.$1, r.$2],
        ],
      ),
      ReportTable(
        context.tr('ad_cases_by_stage'),
        [
          context.tr('ad_kind'),
          for (final s in CaseStage.values) context.tr('cs_${s.name}'),
        ],
        [
          for (final k in CaseKind.values)
            [
              context.tr('ck_${k.name}'),
              for (final s in CaseStage.values)
                pc.where((c) => c.kind == k && c.stage == s).length,
            ],
        ],
      ),
      ReportTable(
        context.tr('ad_doctor_activity'),
        [
          context.tr('summons_name'),
          context.tr('specialty'),
          context.tr('ad_accepted'),
          context.tr('ad_answered'),
          context.tr('ad_commitment'),
        ],
        [
          for (final a in activity)
            [
              a.doctor.name,
              context.tr('sp_${a.doctor.specialtyId}'),
              a.accepted,
              a.answered,
              '${a.commitment}%',
            ],
        ],
      ),
      ReportTable(
        context.tr('ad_cards_by_kind'),
        [
          context.tr('ad_kind'),
          context.tr('cc_valid'),
          context.tr('cc_suspended'),
          context.tr('cc_expired'),
        ],
        [
          for (final k in MemberKind.values)
            [
              context.tr('mc_kind_${k.name}'),
              cards
                  .where((c) => c.kind == k && !c.suspended && !c.isExpired())
                  .length,
              cards.where((c) => c.kind == k && c.suspended).length,
              cards.where((c) => c.kind == k && c.isExpired()).length,
            ],
        ],
      ),
    ];

    return AdminPage(
      title: context.tr('ads_reports'),
      subtitle: context.tr('ad_reports_hint'),
      actions: [
        ExportButtons(
          title:
              '${context.tr('ad_full_report')} — ${context.tr('pe_${_period.name}')}',
          fileName: 'report',
          tables: tables,
          onExport: () => guarded(context, () {
            final n = ref.read(adminProvider.notifier);
            n.authorize(AdminPermission.exportReports);
            n.record(
              'au_report_exported',
              target:
                  '${context.tr('ad_full_report')} — ${context.tr('pe_${_period.name}')}',
            );
          }),
        ),
      ],
      children: [
        FilterRow<Period>(
          values: Period.values,
          selected: _period,
          label: (v) => context.tr('pe_${v!.name}'),
          onSelected: (v) => setState(() => _period = v ?? Period.all),
        ),
        const SizedBox(height: 8),
        Panel(
          title: context.tr('ad_stats'),
          child: Column(
            children: [
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(child: Text(r.$1)),
                      Text(
                        '${r.$2}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_cases_by_stage'),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(context.tr('ad_kind'))),
                for (final s in CaseStage.values)
                  DataColumn(
                    label: Text(context.tr('cs_${s.name}')),
                    numeric: true,
                  ),
              ],
              rows: [
                for (final k in CaseKind.values)
                  DataRow(
                    cells: [
                      DataCell(Text(context.tr('ck_${k.name}'))),
                      for (final s in CaseStage.values)
                        DataCell(
                          Text(
                            '${pc.where((c) => c.kind == k && c.stage == s).length}',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
