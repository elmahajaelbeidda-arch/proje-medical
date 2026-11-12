import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_provider.dart';
import '../../../core/facility_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/search.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../models/facility.dart';
import '../../facility/facility_screens.dart'
    show
        CooperationChips,
        facilityTypeKey,
        referralStatusColor,
        referralStatusKey,
        showReferPatientSheet;
import '../admin_ui.dart';
import 'overview_section.dart' show Pill;
import 'users_section.dart' show AdminFacilityPage;

class FacilitiesSection extends ConsumerStatefulWidget {
  const FacilitiesSection({super.key});
  @override
  ConsumerState<FacilitiesSection> createState() => _FacilitiesSectionState();
}

class _FacilitiesSectionState extends ConsumerState<FacilitiesSection> {
  FacilityType? _type;
  String _q = '';
  ReferralStatus? _refStatus;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final state = ref.watch(facilityProvider);
    final approved = state.facilities.where((f) => f.isApproved).toList();
    final list = approved
        .where((f) => _type == null || f.type == _type)
        .where((f) => Search.matches(_q, [f.name, f.city, ...f.services]))
        .toList();
    final services = admin.services;
    final savedFree = services
        .where((s) => s.free)
        .fold<int>(0, (t, s) => t + s.saved);
    final savedDiscount = services
        .where((s) => !s.free)
        .fold<int>(0, (t, s) => t + s.saved);
    final referrals = state.referrals
        .where((r) => _refStatus == null || r.status == _refStatus)
        .toList();

    return AdminPage(
      title: context.tr('ads_facilities'),
      actions: [
        if (admin.can(AdminPermission.exportReports))
          ExportButtons(
            title: context.tr('ads_facilities'),
            fileName: 'facilities',
            onExport: () {
              ref
                  .read(adminProvider.notifier)
                  .record(
                    'au_report_exported',
                    target: context.tr('ads_facilities'),
                  );
              return true;
            },
            tables: () => [
              ReportTable(
                context.tr('facilities'),
                [
                  context.tr('facility_name'),
                  context.tr('facility_type'),
                  context.tr('city'),
                  context.tr('facility_section_coop'),
                  context.tr('ad_agreement'),
                  context.tr('kp_referrals'),
                  context.tr('ad_beneficiaries'),
                ],
                [
                  for (final f in approved)
                    [
                      f.name,
                      context.tr(facilityTypeKey(f.type)),
                      f.city,
                      f.cooperation
                          .map((c) => context.tr('coop_${c.name}'))
                          .join('، '),
                      admin.agreements[f.id] == null
                          ? '—'
                          : '${fmtDate(admin.agreements[f.id]!.start)} → ${fmtDate(admin.agreements[f.id]!.end)}',
                      state.referralsOf(f.id).length,
                      state
                          .referralsOf(f.id)
                          .where((r) => r.status == ReferralStatus.completed)
                          .length,
                    ],
                ],
              ),
              ReportTable(
                context.tr('ad_services_documented'),
                [
                  context.tr('facility_name'),
                  context.tr('ad_service'),
                  context.tr('ad_kind'),
                  context.tr('ad_value'),
                  context.tr('ad_saved'),
                  context.tr('ad_case'),
                  context.tr('ad_date'),
                ],
                [
                  for (final s in services)
                    [
                      state.facility(s.facilityId)?.name ?? s.facilityId,
                      s.service,
                      s.free ? context.tr('coop_free') : '${s.discount}%',
                      s.value,
                      s.saved,
                      s.caseRef,
                      fmtDate(s.date),
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
              label: context.tr('kp_facilities'),
              value: '${approved.length}',
              icon: Icons.local_hospital_outlined,
            ),
            Kpi(
              label: context.tr('kp_referrals'),
              value: '${state.referrals.length}',
              icon: Icons.assignment_ind_outlined,
            ),
            Kpi(
              label: context.tr('ad_beneficiaries'),
              value:
                  '${state.referrals.where((r) => r.status == ReferralStatus.completed).length}',
              icon: Icons.favorite_outline,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('ad_saved_free'),
              value: money(savedFree),
              icon: Icons.volunteer_activism_outlined,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('ad_saved_discount'),
              value: money(savedDiscount),
              icon: Icons.percent,
              color: AppColors.info,
            ),
          ],
        ),
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<FacilityType>(
          values: [null, ...FacilityType.values],
          selected: _type,
          label: (v) => context.tr(v == null ? 'all' : facilityTypeKey(v)),
          onSelected: (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 8),
        for (final f in list) _FacilityPanel(facility: f),
        Panel(
          title: context.tr('ad_referrals_follow'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterRow<ReferralStatus>(
                values: [null, ...ReferralStatus.values],
                selected: _refStatus,
                label: (v) =>
                    context.tr(v == null ? 'all' : referralStatusKey(v)),
                onSelected: (v) => setState(() => _refStatus = v),
              ),
              for (final r in referrals)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${r.code} • ${state.facility(r.facilityId)?.name ?? ''}',
                  ),
                  subtitle: Text(
                    '${r.service} • ${fmtDate(r.createdAt)}'
                    '${r.facilityNote.isEmpty ? '' : '\n${r.facilityNote}'}',
                  ),
                  isThreeLine: r.facilityNote.isNotEmpty,
                  trailing: Pill(
                    label: context.tr(referralStatusKey(r.status)),
                    color: referralStatusColor(r.status),
                  ),
                ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_services_documented'),
          child: Column(
            children: [
              if (services.isEmpty) Text(context.tr('ad_empty')),
              for (final s in services)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.free ? Icons.volunteer_activism_outlined : Icons.percent,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    '${s.service} — ${state.facility(s.facilityId)?.name ?? ''}',
                  ),
                  subtitle: Text(
                    '${s.free ? context.tr('coop_free') : '${context.tr('coop_discounted')} ${s.discount}%'}'
                    ' • ${context.tr('ad_saved')}: ${money(s.saved)} • ${fmtDate(s.date)}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FacilityPanel extends ConsumerWidget {
  const _FacilityPanel({required this.facility});
  final MedicalFacility facility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = facility;
    final admin = ref.watch(adminProvider);
    final refs = ref.watch(facilityProvider).referralsOf(f.id);
    final agreement = admin.agreements[f.id];
    final now = DateTime.now();
    final canManage = admin.can(AdminPermission.manageFacilities);
    int countOf(ReferralStatus s) => refs.where((r) => r.status == s).length;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AdminFacilityPage(facilityId: f.id),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${f.name} • ${context.tr(facilityTypeKey(f.type))} • ${f.city}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 6),
          CooperationChips(facility: f),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final s in ReferralStatus.values)
                Text('${context.tr(referralStatusKey(s))}: ${countOf(s)}'),
              if (f.monthlyCapacity != null)
                Text(
                  context.tr('capacity_value', args: {'n': f.monthlyCapacity!}),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: agreement == null
                    ? AppColors.grey
                    : agreement.isActive(now)
                    ? AppColors.success
                    : AppColors.emergency,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  agreement == null
                      ? context.tr('ad_no_agreement')
                      : '${context.tr('ad_agreement')}: ${fmtDate(agreement.start)} → ${fmtDate(agreement.end)}'
                            '${agreement.isActive(now) ? '' : ' (${context.tr('ad_expired')})'}\n${agreement.terms}',
                ),
              ),
            ],
          ),
          if (canManage)
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _editAgreement(context, ref, f, agreement),
                  icon: const Icon(Icons.edit_calendar),
                  label: Text(context.tr('ad_agreement_edit')),
                ),
                TextButton.icon(
                  onPressed: () => showReferPatientSheet(context, ref, f),
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: Text(context.tr('refer_patient')),
                ),
                TextButton.icon(
                  onPressed: () => _addService(context, ref, f),
                  icon: const Icon(Icons.add_task),
                  label: Text(context.tr('ad_service_add')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _editAgreement(
    BuildContext context,
    WidgetRef ref,
    MedicalFacility f,
    FacilityAgreement? current,
  ) async {
    final now = DateTime.now();
    var start = current?.start ?? now;
    var end = current?.end ?? DateTime(now.year + 1, now.month, now.day);
    final terms = TextEditingController(text: current?.terms ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${ctx.tr('ad_agreement')} — ${f.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final isStart in [true, false])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(ctx.tr(isStart ? 'ad_start' : 'ad_end')),
                  subtitle: Text(fmtDate(isStart ? start : end)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                      initialDate: isStart ? start : end,
                    );
                    if (d != null) {
                      setState(() => isStart ? start = d : end = d);
                    }
                  },
                ),
              TextField(
                controller: terms,
                maxLines: 3,
                decoration: InputDecoration(labelText: ctx.tr('ad_terms')),
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
    final text = terms.text;
    terms.dispose();
    if (ok != true || !context.mounted) return;
    guarded(
      context,
      () => ref
          .read(adminProvider.notifier)
          .setAgreement(
            f.id,
            f.name,
            FacilityAgreement(start, end, text.trim()),
          ),
      ok: 'ad_done',
    );
  }

  Future<void> _addService(
    BuildContext context,
    WidgetRef ref,
    MedicalFacility f,
  ) async {
    final service = TextEditingController();
    final value = TextEditingController();
    final discount = TextEditingController(text: '${f.discountPercent ?? 30}');
    final caseRef = TextEditingController();
    var free = f.cooperation.contains(CooperationType.free);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${ctx.tr('ad_service_add')} — ${f.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: service,
                  decoration: InputDecoration(labelText: ctx.tr('ad_service')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: free,
                  onChanged: (v) => setState(() => free = v),
                  title: Text(ctx.tr('coop_free')),
                ),
                TextField(
                  controller: value,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '${ctx.tr('ad_value')} (MRU)',
                  ),
                ),
                if (!free)
                  TextField(
                    controller: discount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: ctx.tr('discount_percent'),
                    ),
                  ),
                TextField(
                  controller: caseRef,
                  decoration: InputDecoration(
                    labelText: ctx.tr('ad_case'),
                    hintText: 'ref1',
                  ),
                ),
              ],
            ),
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
    final record = ServiceRecord(
      id: '',
      facilityId: f.id,
      service: service.text.trim(),
      free: free,
      value: int.tryParse(value.text) ?? 0,
      discount: free ? 0 : (int.tryParse(discount.text) ?? 0).clamp(0, 100),
      caseRef: caseRef.text.trim(),
      date: DateTime.now(),
    );
    for (final c in [service, value, discount, caseRef]) {
      c.dispose();
    }
    if (ok != true || !context.mounted) return;
    if (record.service.isEmpty || record.value <= 0) {
      snack(context, 'ad_invalid', error: true);
      return;
    }
    guarded(
      context,
      () => ref.read(adminProvider.notifier).addServiceRecord(record, f.name),
      ok: 'ad_done',
    );
  }
}
