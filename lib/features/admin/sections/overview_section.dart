import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      LucideIcons.userPlus,
      'al_pending_patients',
      regs.where((r) => !r.isDoctor && r.status == ReviewStatus.pending).length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      LucideIcons.briefcaseMedical,
      'al_pending_doctors',
      regs.where((r) => r.isDoctor && r.status == ReviewStatus.pending).length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      LucideIcons.hospital,
      'al_pending_facilities',
      facilities.facilities
          .where((f) => f.status == FacilityStatus.pending)
          .length,
      AppColors.warning,
      'users',
    ),
    AdminAlert(
      LucideIcons.droplet,
      'al_blood_new',
      blood.requests
          .where((r) => r.status == BloodRequestStatus.submitted)
          .length,
      AppColors.emergency,
      'cases',
    ),
    AdminAlert(
      LucideIcons.hourglass,
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
      LucideIcons.clipboardX,
      'al_referrals_new',
      facilities.referrals.where((r) => r.status == ReferralStatus.sent).length,
      AppColors.info,
      'facilities',
    ),
    // Counts only: the content of psychological sessions stays private.
    AdminAlert(
      LucideIcons.shieldPlus,
      'al_psych_risk',
      psych.where((s) => s.riskFlag && s.isUpcoming).length,
      AppColors.emergency,
      'doctors',
    ),
    AdminAlert(
      LucideIcons.calendarCheck,
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
      LucideIcons.idCard,
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
      LucideIcons.handshake,
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
              icon: LucideIcons.users,
            ),
            Kpi(
              label: context.tr('kp_beneficiaries'),
              value:
                  '${cases.where((c) => c.stage == CaseStage.completed).map((c) => c.patientName).toSet().length}',
              icon: LucideIcons.heart,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('kp_doctors'),
              value: '${ref.watch(approvedDoctorsCountProvider)}',
              icon: LucideIcons.briefcaseMedical,
            ),
            Kpi(
              label: context.tr('kp_facilities'),
              value: '${facilities.where((f) => f.isApproved).length}',
              icon: LucideIcons.hospital,
            ),
            Kpi(
              label: context.tr('kp_cases_done'),
              value: '${stages[CaseStage.completed]}',
              icon: LucideIcons.circleCheckBig,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('kp_consultations'),
              value: '${consultations.length}',
              icon: LucideIcons.messagesSquare,
            ),
            Kpi(
              label: context.tr('kp_referrals'),
              value: '${referrals.length}',
              icon: LucideIcons.squareUser,
            ),
            if (admin.can(AdminPermission.viewFinance)) ...[
              Kpi(
                label: context.tr('kp_donations'),
                value: money(admin.totalDonations),
                icon: LucideIcons.handHeart,
                color: AppColors.success,
              ),
              Kpi(
                label: context.tr('kp_aid'),
                value: money(admin.totalExpenses),
                icon: LucideIcons.banknote,
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
                            const Icon(LucideIcons.chevronRightDir),
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
  CaseStage.accepted => AppColors.turquoise,
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
            ? LucideIcons.shieldAlert
            : e.sensitive
            ? LucideIcons.lock
            : LucideIcons.history,
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
