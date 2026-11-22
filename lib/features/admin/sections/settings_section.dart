import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../admin_ui.dart';

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(adminProvider);
    final s = admin.settings;
    final n = ref.read(adminProvider.notifier);
    final canSettings = admin.can(AdminPermission.manageSettings);
    final canContent = admin.can(AdminPermission.manageContent);

    return AdminPage(
      title: context.tr('ads_settings'),
      children: [
        if (canSettings)
          Panel(
            title: context.tr('ad_sections'),
            child: Column(
              children: [
                Text(
                  context.tr('ad_sections_hint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                for (final sec in AppSection.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: s.enabled(sec),
                    onChanged: (v) => guarded(
                      context,
                      () => n.setSection(sec, v),
                      ok: 'ad_done',
                    ),
                    title: Text(context.tr('sec_${sec.name}')),
                  ),
              ],
            ),
          ),
        if (canSettings)
          Panel(
            title: context.tr('vc_settings_title'),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.showVisitorCounter,
                  onChanged: (v) => guarded(
                    context,
                    () => n.setVisitorCounter(
                      visible: v,
                      registered: s.showRegisteredCount,
                      beneficiaries: s.showBeneficiariesCount,
                    ),
                    ok: 'ad_done',
                  ),
                  title: Text(context.tr('vc_settings_show')),
                  subtitle: Text(context.tr('vc_settings_show_desc')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.showRegisteredCount,
                  onChanged: s.showVisitorCounter
                      ? (v) => guarded(
                          context,
                          () => n.setVisitorCounter(
                            visible: true,
                            registered: v,
                            beneficiaries: s.showBeneficiariesCount,
                          ),
                          ok: 'ad_done',
                        )
                      : null,
                  title: Text(context.tr('vc_settings_registered')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.showBeneficiariesCount,
                  onChanged: s.showVisitorCounter
                      ? (v) => guarded(
                          context,
                          () => n.setVisitorCounter(
                            visible: true,
                            registered: s.showRegisteredCount,
                            beneficiaries: v,
                          ),
                          ok: 'ad_done',
                        )
                      : null,
                  title: Text(context.tr('vc_settings_beneficiaries')),
                ),
              ],
            ),
          ),
        if (canSettings) _CallServerForm(current: s.callServer),
        if (canContent) const _Announcements(),
        if (canSettings) _InfoForm(info: s.info),
        if (canSettings)
          Panel(
            title: context.tr('ad_languages'),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.frenchEnabled,
                  onChanged: (v) => guarded(
                    context,
                    () => n.setLanguages(
                      defaultLanguage: s.defaultLanguage,
                      french: v,
                    ),
                    ok: 'ad_done',
                  ),
                  title: Text(context.tr('ad_french_enabled')),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.englishEnabled,
                  onChanged: (v) => guarded(
                    context,
                    () => n.setLanguages(
                      defaultLanguage: s.defaultLanguage,
                      french: s.frenchEnabled,
                      english: v,
                    ),
                    ok: 'ad_done',
                  ),
                  title: Text(context.tr('ad_english_enabled')),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('ad_default_language')),
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in s.languages)
                        ButtonSegment(
                          value: l,
                          label: Text(AppStrings.languageNames[l]!),
                        ),
                    ],
                    selected: {
                      s.languages.contains(s.defaultLanguage)
                          ? s.defaultLanguage
                          : 'ar',
                    },
                    onSelectionChanged: (v) => guarded(
                      context,
                      () => n.setLanguages(
                        defaultLanguage: v.first,
                        french: s.frenchEnabled,
                      ),
                      ok: 'ad_done',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Announcements extends ConsumerStatefulWidget {
  const _Announcements();
  @override
  ConsumerState<_Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends ConsumerState<_Announcements> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(adminProvider).announcements;
    final n = ref.read(adminProvider.notifier);
    return Panel(
      title: context.tr('ad_announcements'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('ad_announcements_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final a in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a.active ? LucideIcons.megaphone : LucideIcons.megaphone,
                color: a.active ? AppColors.primary : AppColors.grey,
              ),
              title: Text(a.title),
              subtitle: Text(a.body),
              trailing: Wrap(
                children: [
                  Switch(
                    value: a.active,
                    onChanged: (_) =>
                        guarded(context, () => n.toggleAnnouncement(a.id)),
                  ),
                  IconButton(
                    tooltip: context.tr('ad_delete'),
                    onPressed: () =>
                        guarded(context, () => n.deleteAnnouncement(a.id)),
                    icon: const Icon(LucideIcons.trash2),
                  ),
                ],
              ),
            ),
          const Divider(),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: context.tr('ad_msg_title')),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _body,
            maxLines: 2,
            decoration: InputDecoration(labelText: context.tr('ad_msg_body')),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: () {
                if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
                  snack(context, 'ad_invalid', error: true);
                  return;
                }
                if (guarded(
                  context,
                  () => n.addAnnouncement(_title.text, _body.text),
                  ok: 'ad_done',
                )) {
                  _title.clear();
                  _body.clear();
                }
              },
              icon: const Icon(LucideIcons.plus),
              label: Text(context.tr('ad_publish')),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoForm extends ConsumerStatefulWidget {
  const _InfoForm({required this.info});
  final AssociationInfo info;
  @override
  ConsumerState<_InfoForm> createState() => _InfoFormState();
}

class _InfoFormState extends ConsumerState<_InfoForm> {
  late final _c = {
    'name': TextEditingController(text: widget.info.name),
    'phone': TextEditingController(text: widget.info.phone),
    'whatsapp': TextEditingController(text: widget.info.whatsapp),
    'email': TextEditingController(text: widget.info.email),
    'address': TextEditingController(text: widget.info.address),
    'donation': TextEditingController(text: widget.info.donationNumber),
    'emergency': TextEditingController(text: widget.info.emergencyNumber),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String k, String label, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _c[k],
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(labelText: context.tr(label)),
      ),
    );
    return Panel(
      title: context.tr('ad_association_info'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field('name', 'summons_name'),
          field('phone', 'phone', ltr: true),
          field('whatsapp', 'whatsapp', ltr: true),
          field('email', 'email', ltr: true),
          field('address', 'address'),
          field('donation', 'ad_donation_number', ltr: true),
          field('emergency', 'ad_emergency_number', ltr: true),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: () => guarded(
                context,
                () => ref
                    .read(adminProvider.notifier)
                    .setAssociationInfo(
                      AssociationInfo(
                        name: _c['name']!.text.trim(),
                        phone: _c['phone']!.text.trim(),
                        whatsapp: _c['whatsapp']!.text.trim(),
                        email: _c['email']!.text.trim(),
                        address: _c['address']!.text.trim(),
                        donationNumber: _c['donation']!.text.trim(),
                        emergencyNumber: _c['emergency']!.text.trim(),
                      ),
                    ),
                ok: 'ad_done',
              ),
              child: Text(context.tr('save')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallServerForm extends ConsumerStatefulWidget {
  const _CallServerForm({required this.current});
  final String current;
  @override
  ConsumerState<_CallServerForm> createState() => _CallServerFormState();
}

class _CallServerFormState extends ConsumerState<_CallServerForm> {
  late final _c = TextEditingController(text: widget.current);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Panel(
    title: context.tr('call_server_title'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('call_server_hint'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _c,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(hintText: 'https://meet.jit.si'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            onPressed: () => guarded(
              context,
              () => ref.read(adminProvider.notifier).setCallServer(_c.text),
              ok: 'ad_done',
            ),
            child: Text(context.tr('save')),
          ),
        ),
      ],
    ),
  );
}
