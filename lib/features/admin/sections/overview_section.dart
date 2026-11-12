import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin_data.dart';
import '../../../core/admin_provider.dart';
import '../../../core/blood_provider.dart';
import '../../../core/facility_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/member_card_provider.dart';
import '../../../core/providers.dart';
import '../../../core/psych_provider.dart';
import '../../../core/summons_provider.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/blood.dart';
import '../../../models/facility.dart';
import '../../../models/models.dart';
import '../../../models/registration.dart';
import '../admin_ui.dart';

/// Something the administration should look at now.
class AdminAlert {
  final IconData icon;
  final String key;
  final int count;
  final Color color;
  final String section;
  const AdminAlert(this.icon, this.key, this.count, this.color, this.section);
}

/// Live alerts computed from the app's data.
final adminAlertsProvider = Provider<List<AdminAlert>>((ref) {
  final regs = ref.watch(registrationsProvider);
  final facilities = ref.watch(facilityProvider);
  final blood = ref.watch(bloodProvider);
  final consultations = ref.watch(consultationsProvider);
  final psych = ref.watch(psychProvider);
  final summons = ref.watch(summonsProvider);
  final cards = ref.watch(memberCardsProvider);
  final admin = ref.watch(adminProvider);
  final now = DateTime.now();
  final alerts = <AdminAlert>[
    AdminAlert(
      Icons.person_add_alt,
      'al_pending_patients',
      regs.where((r) => !r.isDoctor && r.status == ReviewStatus.pending).length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      Icons.medical_services_outlined,
      'al_pending_doctors',
      regs.where((r) => r.isDoctor && r.status == ReviewStatus.pending).length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      Icons.local_hospital_outlined,
      'al_pending_facilities',
      facilities.facilities
          .where((f) => f.status == FacilityStatus.pending)
          .length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      Icons.bloodtype_outlined,
      'al_blood_new',
      blood.requests
          .where((r) => r.status == BloodRequestStatus.submitted)
          .length,
      AppColors.emergency,
      'cases',
    ),
    AdminAlert(
      Icons.hourglass_top,
      'al_consult_waiting',
      consultations
          .where(
            (c) =>
                c.status == ConsultationStatus.pending &&
                now.difference(c.createdAt).inHours >= 24,
          )
          .length,
      AppColors.warning,
      'cases',
    ),
    AdminAlert(
      Icons.assignment_late_outlined,
      'al_referrals_new',
      facilities.referrals.where((r) => r.status == ReferralStatus.sent).length,
      AppColors.info,
      'facilities',
    ),
    // Counts only: the content of psychological sessions stays private.
    AdminAlert(
      Icons.health_and_safety_outlined,
      'al_psych_risk',
      psych.where((s) => s.riskFlag && s.isUpcoming).length,
      AppColors.emergency,
      'doctors',
    ),
    AdminAlert(
      Icons.event_available,
      'al_visits_week',
      summons
          .where(
            (s) =>
                s.appointment.isAfter(now) &&
                s.appointment.difference(now).inDays < 7,
          )
          .length,
      AppColors.primary,
      'doctors',
    ),
    AdminAlert(
      Icons.badge_outlined,
      'al_cards_expiring',
      cards
          .where(
            (c) =>
                !c.isExpired(now) && c.expiresAt.difference(now).inDays <= 30,
          )
          .length,
      AppColors.info,
      'users',
    ),
    AdminAlert(
      Icons.handshake_outlined,
      'al_agreements_ending',
      admin.agreements.values
          .where((a) => a.isActive(now) && a.end.difference(now).inDays <= 30)
          .length,
      AppColors.info,
      'facilities',
    ),
  ];
  return [
    for (final a in alerts)
      if (a.count > 0) a,
  ];
});

class OverviewSection extends ConsumerWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminProvider);
    final regs = ref.watch(registrationsProvider);
    final facilities = ref.watch(facilityProvider).facilities;
    final cases = ref.watch(adminCasesProvider);
    final consultations = ref.watch(consultationsProvider);
    final referrals = ref.watch(facilityProvider).referrals;
    final alerts = ref.watch(adminAlertsProvider);

    int count(bool Function(Registration r) f) => regs.where(f).length;
    final stages = {
      for (final s in CaseStage.values)
        s: cases.where((c) => c.stage == s).length,
    };

    return AdminPage(
      title: context.tr('ads_overview'),
      subtitle: '${context.tr('ad_live')} • ${fmtDateTime(DateTime.now())}',
      children: [
        KpiWrap(
          children: [
            Kpi(
              label: context.tr('kp_patients'),
              value: '${count((r) => !r.isDoctor)}',
              icon: Icons.people_outline,
            ),
            Kpi(
              label: context.tr('kp_beneficiaries'),
              value:
                  '${cases.where((c) => c.stage == CaseStage.completed).map((c) => c.patientName).toSet().length}',
              icon: Icons.favorite_outline,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('kp_doctors'),
              value: '${ref.watch(approvedDoctorsCountProvider)}',
              icon: Icons.medical_services_outlined,
            ),
            Kpi(
              label: context.tr('kp_facilities'),
              value: '${facilities.where((f) => f.isApproved).length}',
              icon: Icons.local_hospital_outlined,
            ),
            Kpi(
              label: context.tr('kp_cases_done'),
              value: '${stages[CaseStage.completed]}',
              icon: Icons.task_alt,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('kp_consultations'),
              value: '${consultations.length}',
              icon: Icons.forum_outlined,
            ),
            Kpi(
              label: context.tr('kp_referrals'),
              value: '${referrals.length}',
              icon: Icons.assignment_ind_outlined,
            ),
            if (admin.can(AdminPermission.viewFinance)) ...[
              Kpi(
                label: context.tr('kp_donations'),
                value: money(admin.totalDonations),
                icon: Icons.volunteer_activism_outlined,
                color: AppColors.success,
              ),
              Kpi(
                label: context.tr('kp_aid'),
                value: money(admin.totalExpenses),
                icon: Icons.payments_outlined,
                color: AppColors.info,
              ),
            ],
          ],
        ),
        Panel(
          title: context.tr('ad_alerts'),
          child: alerts.isEmpty
              ? Text(context.tr('ad_no_alerts'))
              : Column(
                  children: [
                    for (final a in alerts)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: a.color.withValues(alpha: .15),
                          child: Icon(a.icon, color: a.color),
                        ),
                        title: Text(context.tr(a.key)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Pill(label: '${a.count}', color: a.color),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.go('/admin/${a.section}'),
                      ),
                  ],
                ),
        ),
        Panel(
          title: context.tr('ad_cases_by_stage'),
          child: StageBars(stages: stages),
        ),
        if (admin.can(AdminPermission.viewAudit))
          Panel(
            title: context.tr('ad_recent_activity'),
            trailing: TextButton(
              onPressed: () => context.go('/admin/security'),
              child: Text(context.tr('ad_see_all')),
            ),
            child: Column(
              children: [
                for (final e in admin.audit.take(6))
                  AuditTile(entry: e, dense: true),
              ],
            ),
          ),
      ],
    );
  }
}

Color stageColor(CaseStage s) => switch (s) {
  CaseStage.pending => AppColors.warning,
  CaseStage.accepted => AppColors.teal,
  CaseStage.onHold => AppColors.info,
  CaseStage.rejected => AppColors.grey,
  CaseStage.completed => AppColors.success,
};

/// Simple horizontal bars (no chart library needed).
class StageBars extends StatelessWidget {
  const StageBars({super.key, required this.stages});
  final Map<CaseStage, int> stages;

  @override
  Widget build(BuildContext context) {
    final max = stages.values.fold<int>(1, (m, v) => v > m ? v : m);
    return Column(
      children: [
        for (final e in stages.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(context.tr('cs_${e.key.name}')),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: e.value / max,
                      minHeight: 14,
                      color: stageColor(e.key),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${e.value}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AuditTile extends StatelessWidget {
  const AuditTile({super.key, required this.entry, this.dense = false});
  final AuditEntry entry;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    // Group names and sections are stored as codes: show them translated.
    var target = e.target;
    for (final prefix in ['ma_', 'sec_']) {
      final t = context.tr('$prefix${e.target}');
      if (t != '$prefix${e.target}') target = t;
    }
    final denied = e.action == 'au_denied' || e.action.contains('failed');
    return ListTile(
      dense: dense,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        denied
            ? Icons.gpp_bad_outlined
            : e.sensitive
            ? Icons.lock_outline
            : Icons.history,
        color: denied
            ? AppColors.emergency
            : e.sensitive
            ? AppColors.warning
            : AppColors.primary,
      ),
      title: Text(
        '${context.tr(e.action)}${target.isEmpty ? '' : ' — $target'}',
      ),
      subtitle: Text(
        '${e.adminName} • ${fmtDateTime(e.at)}${e.details.isEmpty ? '' : '\n${e.details}'}',
      ),
      isThreeLine: e.details.isNotEmpty && !dense,
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: AppColors.on(color),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}
