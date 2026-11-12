import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_data.dart';
import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/search.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../admin_ui.dart';

enum Period { month, quarter, year, all }

DateTime? periodStart(Period p, DateTime now) => switch (p) {
  Period.month => DateTime(now.year, now.month),
  Period.quarter => now.subtract(const Duration(days: 90)),
  Period.year => DateTime(now.year),
  Period.all => null,
};

bool inPeriod(DateTime d, Period p) {
  final s = periodStart(p, DateTime.now());
  return s == null || !d.isBefore(s);
}

class FinanceSection extends ConsumerStatefulWidget {
  const FinanceSection({super.key});
  @override
  ConsumerState<FinanceSection> createState() => _FinanceSectionState();
}

class _FinanceSectionState extends ConsumerState<FinanceSection> {
  Period _period = Period.quarter;
  DonationMethod? _method;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final cases = ref.watch(adminCasesProvider);
    final codeOf = {for (final c in cases) c.id: c.code};
    String caseLabel(String id) =>
        id.isEmpty ? context.tr('ad_general_fund') : (codeOf[id] ?? id);

    final donations = admin.donations
        .where((d) => inPeriod(d.date, _period))
        .where((d) => _method == null || d.method == _method)
        .where(
          (d) => Search.matches(_q, [
            d.anonymous ? '' : d.donor,
            d.receiptNo,
            caseLabel(d.caseRef),
            d.note,
          ]),
        )
        .toList();
    final expenses = admin.expenses
        .where((e) => inPeriod(e.date, _period))
        .where(
          (e) => Search.matches(_q, [
            caseLabel(e.caseRef),
            context.tr('ec_${e.category.name}'),
            e.note,
          ]),
        )
        .toList();
    final inSum = donations.fold<int>(0, (s, d) => s + d.amount);
    final outSum = expenses.fold<int>(0, (s, e) => s + e.amount);

    // Money per case: received for it vs spent on it.
    final perCase = <String, (int, int)>{};
    for (final d in admin.donations.where((d) => d.caseRef.isNotEmpty)) {
      final v = perCase[d.caseRef] ?? (0, 0);
      perCase[d.caseRef] = (v.$1 + d.amount, v.$2);
    }
    for (final e in admin.expenses.where((e) => e.caseRef.isNotEmpty)) {
      final v = perCase[e.caseRef] ?? (0, 0);
      perCase[e.caseRef] = (v.$1, v.$2 + e.amount);
    }

    // Last 6 months of donations.
    final now = DateTime.now();
    final months = [
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i),
    ];
    final monthly = {
      for (final m in months)
        m: admin.donations
            .where((d) => d.date.year == m.year && d.date.month == m.month)
            .fold<int>(0, (s, d) => s + d.amount),
    };
    final maxMonth = monthly.values.fold<int>(1, (m, v) => v > m ? v : m);
    final canManage = admin.can(AdminPermission.manageFinance);

    List<ReportTable> tables() => [
      ReportTable(
        context.tr('ad_fin_summary'),
        [context.tr('ad_item'), context.tr('ad_value')],
        [
          [context.tr('ad_period'), context.tr('pe_${_period.name}')],
          [context.tr('kp_donations'), money(inSum)],
          [context.tr('kp_aid'), money(outSum)],
          [context.tr('ad_balance'), money(inSum - outSum)],
          [context.tr('ad_total_balance'), money(admin.balance)],
        ],
      ),
      ReportTable(
        context.tr('ad_donations'),
        [
          context.tr('ad_receipt'),
          context.tr('ad_donor'),
          context.tr('ad_amount'),
          context.tr('ad_method'),
          context.tr('ad_case'),
          context.tr('ad_date'),
        ],
        [
          for (final d in donations)
            [
              d.receiptNo,
              d.anonymous ? context.tr('ad_anonymous') : d.donor,
              d.amount,
              context.tr('dm_${d.method.name}'),
              caseLabel(d.caseRef),
              fmtDate(d.date),
            ],
        ],
      ),
      ReportTable(
        context.tr('ad_expenses'),
        [
          context.tr('ad_category'),
          context.tr('ad_amount'),
          context.tr('ad_case'),
          context.tr('ad_note'),
          context.tr('ad_date'),
        ],
        [
          for (final e in expenses)
            [
              context.tr('ec_${e.category.name}'),
              e.amount,
              caseLabel(e.caseRef),
              e.note,
              fmtDate(e.date),
            ],
        ],
      ),
      ReportTable(
        context.tr('ad_per_case'),
        [
          context.tr('ad_case'),
          context.tr('ad_received'),
          context.tr('ad_spent'),
        ],
        [
          for (final e in perCase.entries)
            [caseLabel(e.key), e.value.$1, e.value.$2],
        ],
      ),
    ];

    return AdminPage(
      title: context.tr('ads_finance'),
      actions: [
        if (canManage) ...[
          FilledButton.icon(
            onPressed: () => _addDonation(context, cases),
            icon: const Icon(Icons.add),
            label: Text(context.tr('ad_add_donation')),
          ),
          OutlinedButton.icon(
            onPressed: () => _addExpense(context, cases),
            icon: const Icon(Icons.remove),
            label: Text(context.tr('ad_add_expense')),
          ),
        ],
        if (admin.can(AdminPermission.exportReports))
          ExportButtons(
            title:
                '${context.tr('ad_fin_report')} — ${context.tr('pe_${_period.name}')}',
            fileName: 'finance',
            tables: tables,
            onExport: () {
              ref
                  .read(adminProvider.notifier)
                  .record(
                    'au_report_exported',
                    target: context.tr('ads_finance'),
                    sensitive: true,
                  );
              return true;
            },
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
        KpiWrap(
          children: [
            Kpi(
              label: context.tr('kp_donations'),
              value: money(inSum),
              icon: Icons.volunteer_activism_outlined,
              color: AppColors.success,
            ),
            Kpi(
              label: context.tr('kp_aid'),
              value: money(outSum),
              icon: Icons.payments_outlined,
              color: AppColors.info,
            ),
            Kpi(
              label: context.tr('ad_total_balance'),
              value: money(admin.balance),
              icon: Icons.account_balance_wallet_outlined,
              color: admin.balance >= 0
                  ? AppColors.primary
                  : AppColors.emergency,
            ),
            Kpi(
              label: context.tr('ad_donors_count'),
              value: '${donations.length}',
              icon: Icons.people_outline,
            ),
          ],
        ),
        Panel(
          title: context.tr('ad_monthly'),
          child: SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in monthly.entries)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            child: Text(
                              '${(e.value / 1000).round()}k',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 100 * e.value / maxMonth,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${e.key.month}/${e.key.year % 100}'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        FilterRow<DonationMethod>(
          values: [null, ...DonationMethod.values],
          selected: _method,
          label: (v) => context.tr(v == null ? 'all' : 'dm_${v.name}'),
          onSelected: (v) => setState(() => _method = v),
        ),
        Panel(
          title: '${context.tr('ad_donations')} (${donations.length})',
          child: Column(
            children: [
              if (donations.isEmpty) Text(context.tr('ad_empty')),
              for (final d in donations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.volunteer_activism_outlined,
                    color: AppColors.success,
                  ),
                  title: Text(
                    '${d.anonymous ? context.tr('ad_anonymous') : d.donor} — ${money(d.amount)}',
                  ),
                  subtitle: Text(
                    '${d.receiptNo} • ${context.tr('dm_${d.method.name}')} • ${caseLabel(d.caseRef)} • ${fmtDate(d.date)}'
                    '${d.note.isEmpty ? '' : '\n${d.note}'}',
                  ),
                  isThreeLine: d.note.isNotEmpty,
                ),
            ],
          ),
        ),
        Panel(
          title: '${context.tr('ad_expenses')} (${expenses.length})',
          child: Column(
            children: [
              if (expenses.isEmpty) Text(context.tr('ad_empty')),
              for (final e in expenses)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.info,
                  ),
                  title: Text(
                    '${context.tr('ec_${e.category.name}')} — ${money(e.amount)}',
                  ),
                  subtitle: Text(
                    '${caseLabel(e.caseRef)} • ${fmtDate(e.date)}'
                    '${e.note.isEmpty ? '' : ' • ${e.note}'}',
                  ),
                ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_per_case'),
          child: Column(
            children: [
              for (final e in perCase.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(caseLabel(e.key)),
                  subtitle: Text(
                    '${context.tr('ad_received')}: ${money(e.value.$1)} • ${context.tr('ad_spent')}: ${money(e.value.$2)}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addDonation(BuildContext context, List<AdminCase> cases) async {
    final donor = TextEditingController();
    final amount = TextEditingController();
    final note = TextEditingController();
    var method = DonationMethod.bankily;
    var anonymous = false;
    var caseRef = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('ad_add_donation')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: anonymous,
                  onChanged: (v) => setState(() => anonymous = v),
                  title: Text(ctx.tr('ad_anonymous')),
                ),
                if (!anonymous)
                  TextField(
                    controller: donor,
                    decoration: InputDecoration(labelText: ctx.tr('ad_donor')),
                  ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '${ctx.tr('ad_amount')} (MRU)',
                  ),
                ),
                DropdownButtonFormField<DonationMethod>(
                  initialValue: method,
                  decoration: InputDecoration(labelText: ctx.tr('ad_method')),
                  items: [
                    for (final m in DonationMethod.values)
                      DropdownMenuItem(
                        value: m,
                        child: Text(ctx.tr('dm_${m.name}')),
                      ),
                  ],
                  onChanged: (v) => setState(() => method = v ?? method),
                ),
                _CasePicker(
                  cases: cases,
                  value: caseRef,
                  onChanged: (v) => setState(() => caseRef = v),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: ctx.tr('ad_note')),
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
    final d = Donation(
      id: '',
      donor: anonymous ? '' : donor.text,
      anonymous: anonymous,
      amount: int.tryParse(amount.text) ?? 0,
      method: method,
      date: DateTime.now(),
      caseRef: caseRef,
      note: note.text,
    );
    for (final c in [donor, amount, note]) {
      c.dispose();
    }
    if (ok != true || !context.mounted) return;
    guarded(
      context,
      () => ref.read(adminProvider.notifier).addDonation(d),
      ok: 'ad_done',
    );
  }

  Future<void> _addExpense(BuildContext context, List<AdminCase> cases) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    var category = ExpenseCategory.medicine;
    var caseRef = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('ad_add_expense')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: category,
                  decoration: InputDecoration(labelText: ctx.tr('ad_category')),
                  items: [
                    for (final c in ExpenseCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Text(ctx.tr('ec_${c.name}')),
                      ),
                  ],
                  onChanged: (v) => setState(() => category = v ?? category),
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: '${ctx.tr('ad_amount')} (MRU)',
                  ),
                ),
                _CasePicker(
                  cases: cases,
                  value: caseRef,
                  onChanged: (v) => setState(() => caseRef = v),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(labelText: ctx.tr('ad_note')),
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
    final e = Expense(
      id: '',
      category: category,
      amount: int.tryParse(amount.text) ?? 0,
      caseRef: caseRef,
      date: DateTime.now(),
      note: note.text,
    );
    amount.dispose();
    note.dispose();
    if (ok != true || !context.mounted) return;
    guarded(
      context,
      () => ref.read(adminProvider.notifier).addExpense(e),
      ok: 'ad_done',
    );
  }
}

/// Links money to a case (or to the general fund).
class _CasePicker extends StatelessWidget {
  const _CasePicker({
    required this.cases,
    required this.value,
    required this.onChanged,
  });
  final List<AdminCase> cases;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: context.tr('ad_case')),
    items: [
      DropdownMenuItem(value: '', child: Text(context.tr('ad_general_fund'))),
      for (final c in cases)
        DropdownMenuItem(
          value: c.id,
          child: Text(
            '${c.code} • ${context.tr('ck_${c.kind.name}')}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: (v) => onChanged(v ?? ''),
  );
}
