import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/search.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../admin_ui.dart';
import '../totp.dart';
import 'overview_section.dart' show AuditTile, Pill;

class SecuritySection extends ConsumerStatefulWidget {
  const SecuritySection({super.key});
  @override
  ConsumerState<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<SecuritySection> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final tabs = <(String, Widget)>[
      (context.tr('ad_my_account'), const _MyAccount()),
      if (admin.can(AdminPermission.manageAdmins))
        (context.tr('ad_admins'), const _Admins()),
      (context.tr('ad_permissions'), const _Matrix()),
      if (admin.can(AdminPermission.viewAudit))
        (context.tr('ad_audit'), const _Audit()),
      if (admin.can(AdminPermission.manageBackups))
        (context.tr('ad_backup'), const _Backup()),
    ];
    final tab = _tab.clamp(0, tabs.length - 1);
    return AdminPage(
      title: context.tr('ads_security'),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < tabs.length; i++)
                ButtonSegment(value: i, label: Text(tabs[i].$1)),
            ],
            selected: {tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
        ),
        const SizedBox(height: 12),
        tabs[tab].$2,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// My account: authenticator app and password
// ---------------------------------------------------------------------------

class _MyAccount extends ConsumerStatefulWidget {
  const _MyAccount();
  @override
  ConsumerState<_MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends ConsumerState<_MyAccount> {
  String? _secret;
  final _code = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(adminProvider).me!;
    final linked = me.totpSecret != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          title: me.name,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(me.email, textDirection: TextDirection.ltr),
              Text(
                '${context.tr('ad_role')}: ${context.tr('ar_${me.role.name}')}',
              ),
              if (me.lastLoginAt != null)
                Text(
                  '${context.tr('ad_last_login')}: ${fmtDateTime(me.lastLoginAt!)}',
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in me.permissions)
                    Chip(label: Text(context.tr('ap_${p.name}'))),
                ],
              ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_2fa'),
          trailing: Pill(
            label: context.tr(linked ? 'ad_2fa_app' : 'ad_2fa_demo'),
            color: linked ? AppColors.success : AppColors.grey,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('ad_2fa_hint')),
              const SizedBox(height: 8),
              if (_secret == null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          setState(() => _secret = Totp.newSecret()),
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(
                        context.tr(linked ? 'ad_2fa_relink' : 'ad_2fa_link'),
                      ),
                    ),
                    if (linked)
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.read(adminProvider.notifier).disableMyTotp();
                          snack(context, 'ad_done');
                        },
                        icon: const Icon(Icons.phonelink_erase),
                        label: Text(context.tr('ad_2fa_disable')),
                      ),
                  ],
                )
              else ...[
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: QrImageView(
                      data: Totp.uri(_secret!, me.email),
                      size: 180,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _secret!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  maxLength: 6,
                  decoration: InputDecoration(labelText: context.tr('ad_code')),
                ),
                FilledButton(
                  onPressed: () {
                    final ok = ref
                        .read(adminProvider.notifier)
                        .enableTotp(_secret!, _code.text);
                    snack(
                      context,
                      ok ? 'ad_2fa_enabled' : 'ad_code_wrong',
                      error: !ok,
                    );
                    if (ok) {
                      setState(() => _secret = null);
                      _code.clear();
                    }
                  },
                  child: Text(context.tr('ad_verify')),
                ),
              ],
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_change_password'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _current,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('ad_current_password'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _next,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('ad_new_password'),
                  helperText: context.tr('ad_password_rule'),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: () {
                    final ok = ref
                        .read(adminProvider.notifier)
                        .changeMyPassword(_current.text, _next.text);
                    snack(context, ok ? 'ad_done' : 'ad_invalid', error: !ok);
                    if (ok) {
                      _current.clear();
                      _next.clear();
                    }
                  },
                  child: Text(context.tr('save')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Admin accounts and permissions
// ---------------------------------------------------------------------------

class _Admins extends ConsumerWidget {
  const _Admins();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: () => _editAdmin(context, ref, null),
            icon: const Icon(Icons.person_add_alt),
            label: Text(context.tr('ad_new_admin')),
          ),
        ),
        const SizedBox(height: 10),
        for (final a in state.admins)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: a.active
                          ? AppColors.primary
                          : AppColors.grey,
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${a.email} • ${context.tr('ar_${a.role.name}')} • ${a.permissions.length} ${context.tr('ad_perms_count')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Pill(
                      label: context.tr(a.active ? 'ad_active' : 'ad_disabled'),
                      color: a.active ? AppColors.success : AppColors.grey,
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editAdmin(context, ref, a),
                      icon: const Icon(Icons.tune),
                      label: Text(context.tr('ad_edit_permissions')),
                    ),
                    if (a.id != state.me!.id)
                      TextButton.icon(
                        onPressed: () => guarded(
                          context,
                          () => notifier.setAdminActive(a.id, !a.active),
                          ok: 'ad_done',
                        ),
                        icon: Icon(
                          a.active ? Icons.block : Icons.check_circle_outline,
                        ),
                        label: Text(
                          context.tr(a.active ? 'ad_disable' : 'ad_enable'),
                        ),
                      ),
                    if (a.totpSecret != null)
                      TextButton.icon(
                        onPressed: () => guarded(
                          context,
                          () => notifier.resetTwoFactor(a.id),
                          ok: 'ad_done',
                        ),
                        icon: const Icon(Icons.phonelink_erase),
                        label: Text(context.tr('ad_2fa_reset')),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _editAdmin(
    BuildContext context,
    WidgetRef ref,
    AdminAccount? existing,
  ) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final password = TextEditingController();
    var role = existing?.role ?? AdminRole.communications;
    var perms = {...(existing?.permissions ?? rolePermissions(role))};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
            ctx.tr(existing == null ? 'ad_new_admin' : 'ad_edit_permissions'),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null) ...[
                    TextField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: ctx.tr('summons_name'),
                      ),
                    ),
                    TextField(
                      controller: email,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: ctx.tr('email')),
                    ),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: ctx.tr('password'),
                        helperText: ctx.tr('ad_password_rule'),
                      ),
                    ),
                  ],
                  DropdownButtonFormField<AdminRole>(
                    initialValue: role,
                    decoration: InputDecoration(labelText: ctx.tr('ad_role')),
                    items: [
                      for (final r in AdminRole.values)
                        DropdownMenuItem(
                          value: r,
                          child: Text(ctx.tr('ar_${r.name}')),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      role = v ?? role;
                      if (role != AdminRole.custom) {
                        perms = {...rolePermissions(role)};
                      }
                    }),
                  ),
                  const SizedBox(height: 6),
                  for (final p in AdminPermission.values)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: perms.contains(p),
                      onChanged: (v) => setState(() {
                        role = AdminRole.custom;
                        v == true ? perms.add(p) : perms.remove(p);
                      }),
                      title: Text(ctx.tr('ap_${p.name}')),
                    ),
                ],
              ),
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
    final n = name.text, e = email.text, pw = password.text;
    for (final c in [name, email, password]) {
      c.dispose();
    }
    if (ok != true || !context.mounted) return;
    final notifier = ref.read(adminProvider.notifier);
    guarded(context, () {
      if (existing == null) {
        notifier.createAdmin(
          name: n,
          email: e,
          password: pw,
          role: role,
          permissions: perms,
        );
      } else {
        notifier.updatePermissions(existing.id, role, perms);
      }
    }, ok: 'ad_done');
  }
}

/// Which role can do what (read-only reference).
class _Matrix extends StatelessWidget {
  const _Matrix();
  @override
  Widget build(BuildContext context) {
    final roles = AdminRole.values.where((r) => r != AdminRole.custom).toList();
    return Panel(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 18,
          columns: [
            DataColumn(label: Text(context.tr('ad_permissions'))),
            for (final r in roles)
              DataColumn(label: Text(context.tr('ar_${r.name}'))),
          ],
          rows: [
            for (final p in AdminPermission.values)
              DataRow(
                cells: [
                  DataCell(Text(context.tr('ap_${p.name}'))),
                  for (final r in roles)
                    DataCell(
                      rolePermissions(r).contains(p)
                          ? const Icon(Icons.check, color: AppColors.success)
                          : const Text('—'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audit log
// ---------------------------------------------------------------------------

class _Audit extends ConsumerStatefulWidget {
  const _Audit();
  @override
  ConsumerState<_Audit> createState() => _AuditState();
}

class _AuditState extends ConsumerState<_Audit> {
  String _q = '';
  bool _sensitive = false;
  bool _denied = false;
  String? _adminId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final list = state.audit
        .where((e) => !_sensitive || e.sensitive)
        .where(
          (e) =>
              !_denied ||
              e.action == 'au_denied' ||
              e.action.contains('failed'),
        )
        .where((e) => _adminId == null || e.adminId == _adminId)
        .where(
          (e) => Search.matches(_q, [
            context.tr(e.action),
            e.target,
            e.details,
            e.adminName,
          ]),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('ad_audit_hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(context.tr('ad_sensitive_only')),
              selected: _sensitive,
              onSelected: (v) => setState(() => _sensitive = v),
            ),
            FilterChip(
              label: Text(context.tr('ad_denied_only')),
              selected: _denied,
              onSelected: (v) => setState(() => _denied = v),
            ),
            DropdownButton<String?>(
              value: _adminId,
              hint: Text(context.tr('ad_all_admins')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(context.tr('ad_all_admins')),
                ),
                for (final a in state.admins)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _adminId = v),
            ),
            ExportButtons(
              title: context.tr('ad_audit'),
              fileName: 'audit',
              onExport: () {
                ref
                    .read(adminProvider.notifier)
                    .record('au_audit_exported', sensitive: true);
                return true;
              },
              tables: () => [
                ReportTable(
                  context.tr('ad_audit'),
                  [
                    context.tr('ad_date'),
                    context.tr('ad_admin'),
                    context.tr('ad_action'),
                    context.tr('ad_target'),
                    context.tr('ad_details'),
                  ],
                  [
                    for (final e in list)
                      [
                        fmtDateTime(e.at),
                        e.adminName,
                        context.tr(e.action),
                        e.target,
                        e.details,
                      ],
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        SearchBox(onChanged: (v) => setState(() => _q = v)),
        Text(
          context.tr('ad_results', args: {'n': list.length}),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Panel(
          child: Column(
            children: [for (final e in list.take(200)) AuditTile(entry: e)],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Backup and restore
// ---------------------------------------------------------------------------

class _Backup extends ConsumerWidget {
  const _Backup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(adminProvider.notifier);

    Future<void> restore() async {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (files.isEmpty || !context.mounted) return;
      final text = utf8.decode(await files.first.readAsBytes());
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.tr('ad_restore')),
          content: Text(ctx.tr('ad_restore_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('confirm')),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      guarded(context, () => notifier.restoreBackup(text), ok: 'ad_restored');
    }

    return Panel(
      title: context.tr('ad_backup'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('ad_backup_hint')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  String? json;
                  if (guarded(context, () => json = notifier.exportBackup())) {
                    exportText(
                      json!,
                      'shifa-backup-${stamp()}.json',
                      'application/json',
                    );
                  }
                },
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(context.tr('ad_backup_download')),
              ),
              OutlinedButton.icon(
                onPressed: restore,
                icon: const Icon(Icons.restore),
                label: Text(context.tr('ad_restore')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
