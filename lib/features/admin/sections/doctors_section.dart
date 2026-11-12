import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin_data.dart';
import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/psych_provider.dart';
import '../../../core/search.dart';
import '../../../core/summons_provider.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/blood.dart' show maskName;
import '../../../models/models.dart';
import '../../../models/psych.dart';
import '../../../models/registration.dart';
import '../../../models/summons.dart';
import '../admin_ui.dart';
import 'overview_section.dart' show Pill;

class DoctorsSection extends ConsumerStatefulWidget {
  const DoctorsSection({super.key});
  @override
  ConsumerState<DoctorsSection> createState() => _DoctorsSectionState();
}

class _DoctorsSectionState extends ConsumerState<DoctorsSection> {
  String? _specialty;
  String _q = '';
  bool _upcomingOnly = true;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final activity = ref.watch(doctorActivityProvider);
    final regs = ref.watch(registrationsProvider);
    final consultations = ref.watch(consultationsProvider);
    final psych = ref.watch(psychProvider);
    final now = DateTime.now();
    final summons =
        ref
            .watch(summonsProvider)
            .where((s) => !_upcomingOnly || s.appointment.isAfter(now))
            .toList()
          ..sort((a, b) => a.appointment.compareTo(b.appointment));
    final pendingDoctors = regs
        .where((r) => r.isDoctor && r.status == ReviewStatus.pending)
        .length;
    final list =
        activity
            .where(
              (a) => _specialty == null || a.doctor.specialtyId == _specialty,
            )
            .where(
              (a) => Search.matches(_q, [
                a.doctor.name,
                a.doctor.city,
                context.tr('sp_${a.doctor.specialtyId}'),
              ]),
            )
            .toList()
          ..sort((a, b) => b.commitment.compareTo(a.commitment));

    String? licenseOf(String name) =>
        regs.where((r) => r.name == name).firstOrNull?.licenseNumber;

    return AdminPage(
      title: context.tr('ads_doctors'),
      actions: [
        if (admin.can(AdminPermission.exportReports))
          ExportButtons(
            title: context.tr('ad_doctor_activity'),
            fileName: 'doctors',
            onExport: () {
              ref
                  .read(adminProvider.notifier)
                  .record(
                    'au_report_exported',
                    target: context.tr('ads_doctors'),
                  );
              return true;
            },
            tables: () => [
              ReportTable(
                context.tr('ad_doctor_activity'),
                [
                  context.tr('summons_name'),
                  context.tr('specialty'),
                  context.tr('license_number'),
                  context.tr('ad_accepted'),
                  context.tr('ad_answered'),
                  context.tr('ad_late'),
                  context.tr('rating'),
                  context.tr('ad_commitment'),
                ],
                [
                  for (final a in list)
                    [
                      a.doctor.name,
                      context.tr('sp_${a.doctor.specialtyId}'),
                      licenseOf(a.doctor.name) ?? '—',
                      a.accepted,
                      a.answered,
                      a.late,
                      a.patientRating?.toStringAsFixed(1) ?? '—',
                      '${a.commitment}%',
                    ],
                ],
              ),
            ],
          ),
      ],
      children: [
        KpiWrap(
          children: [
            Kpi(
              label: context.tr('kp_doctors'),
              value: '${activity.length}',
              icon: Icons.medical_services_outlined,
            ),
            Kpi(
              label: context.tr('al_pending_doctors'),
              value: '$pendingDoctors',
              icon: Icons.person_add_alt,
              color: AppColors.warning,
              onTap: () => context.go('/admin/users'),
            ),
            Kpi(
              label: context.tr('ad_unassigned'),
              value:
                  '${consultations.where((c) => c.status == ConsultationStatus.pending).length}',
              icon: Icons.inbox_outlined,
              color: AppColors.info,
              onTap: () => context.go('/admin/cases'),
            ),
            Kpi(
              label: context.tr('ad_psych_sessions'),
              value:
                  '${psych.where((s) => s.status == PsychStatus.completed).length}',
              icon: Icons.psychology_outlined,
            ),
            Kpi(
              label: context.tr('al_visits_week'),
              value:
                  '${ref.watch(summonsProvider).where((s) => s.appointment.isAfter(now) && s.appointment.difference(now).inDays < 7).length}',
              icon: Icons.event_available,
            ),
          ],
        ),
        Text(
          context.tr('ad_psych_privacy'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Panel(
          title: context.tr('ad_doctor_activity'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchBox(onChanged: (v) => setState(() => _q = v)),
              FilterRow<String>(
                values: [null, ...Specialty.all.map((s) => s.id)],
                selected: _specialty,
                label: (v) => context.tr(v == null ? 'all' : 'sp_$v'),
                onSelected: (v) => setState(() => _specialty = v),
              ),
              for (final a in list)
                _DoctorRow(activity: a, license: licenseOf(a.doctor.name)),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_visits'),
          trailing: FilterChip(
            label: Text(context.tr('summons_upcoming')),
            selected: _upcomingOnly,
            onSelected: (v) => setState(() => _upcomingOnly = v),
          ),
          child: Column(
            children: [
              if (summons.isEmpty) Text(context.tr('ad_empty')),
              for (final s in summons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.issuer == SummonsIssuer.doctor
                        ? Icons.medical_services_outlined
                        : Icons.local_hospital_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('${s.code} • ${s.issuerName}'),
                  subtitle: Text(
                    '${fmtDateTime(s.appointment)} • ${s.place}\n'
                    '${admin.can(AdminPermission.viewMedicalRecords) ? s.patientName : maskName(s.patientName)}',
                  ),
                  isThreeLine: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorRow extends ConsumerWidget {
  const _DoctorRow({required this.activity, this.license});
  final DoctorActivity activity;
  final String? license;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = activity;
    final d = a.doctor;
    final color = a.commitment >= 80
        ? AppColors.success
        : a.commitment >= 50
        ? AppColors.warning
        : AppColors.emergency;

    Future<void> evaluate() async {
      var score = a.evaluation?.score ?? 4;
      final note = TextEditingController(text: a.evaluation?.note ?? '');
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('${ctx.tr('ad_evaluate')} — ${d.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setState(() => score = i),
                        icon: Icon(
                          i <= score ? Icons.star : Icons.star_border,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: ctx.tr('ad_note')),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.tr('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.tr('save')),
              ),
            ],
          ),
        ),
      );
      final text = note.text;
      note.dispose();
      if (ok != true || !context.mounted) return;
      guarded(
        context,
        () => ref
            .read(adminProvider.notifier)
            .evaluateDoctor(d.id, d.name, score, text),
        ok: 'ad_done',
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${context.tr('sp_${d.specialtyId}')} • ${d.city}'
                        '${license == null ? '' : ' • $license'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Pill(label: '${a.commitment}%', color: color),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                Text('${context.tr('ad_accepted')}: ${a.accepted}'),
                Text('${context.tr('ad_answered')}: ${a.answered}'),
                Text(
                  '${context.tr('ad_late')}: ${a.late}',
                  style: TextStyle(
                    color: a.late > 0 ? AppColors.emergency : null,
                  ),
                ),
                Text(
                  '${context.tr('rating')}: ${a.patientRating?.toStringAsFixed(1) ?? d.rating}',
                ),
                Text('${context.tr('summons_cards')}: ${a.summons}'),
                if (d.specialtyId == 'psych')
                  Text(
                    '${context.tr('ad_psych_sessions')}: ${a.psychSessions}',
                  ),
              ],
            ),
            if (a.evaluation != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${context.tr('ad_evaluation')}: ${'★' * a.evaluation!.score}${'☆' * (5 - a.evaluation!.score)} ${a.evaluation!.note}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            if (ref.watch(adminProvider).can(AdminPermission.manageDoctors))
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: evaluate,
                  icon: const Icon(Icons.star_half),
                  label: Text(context.tr('ad_evaluate')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
