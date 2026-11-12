import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_provider.dart';
import '../../../core/facility_provider.dart';
import '../../../core/l10n.dart';
import '../../../core/summons_provider.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../facility/facility_screens.dart'
    show referralStatusColor, referralStatusKey;
import '../admin_ui.dart';
import 'overview_section.dart' show AuditTile, Pill, adminAlertsProvider;
import 'users_section.dart' show messageTargets;

/// Individual and group messages, alerts, and follow-up of decisions.
class MessagesSection extends ConsumerStatefulWidget {
  const MessagesSection({super.key});
  @override
  ConsumerState<MessagesSection> createState() => _MessagesSectionState();
}

class _MessagesSectionState extends ConsumerState<MessagesSection> {
  MessageAudience _audience = MessageAudience.all;
  String? _target;
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _send() {
    final targets = messageTargets(ref);
    final t = targets.where((x) => x.$1 == _target).firstOrNull;
    final ok = guarded(
      context,
      () => ref
          .read(adminProvider.notifier)
          .sendMessage(
            audience: _audience,
            targetId: _audience == MessageAudience.user ? (_target ?? '') : '',
            targetName: t?.$2 ?? '',
            title: _title.text,
            body: _body.text,
          ),
      ok: 'ad_message_sent',
    );
    if (ok) {
      _title.clear();
      _body.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final alerts = ref.watch(adminAlertsProvider);
    final targets = messageTargets(ref);
    final facilities = ref.watch(facilityProvider);
    final summons = ref.watch(summonsProvider).take(6).toList();
    final decisions = admin.audit
        .where(
          (a) =>
              a.action == 'au_approve' ||
              a.action == 'au_reject' ||
              a.action.startsWith('au_facility_') ||
              a.action.startsWith('au_case_'),
        )
        .take(8)
        .toList();

    return AdminPage(
      title: context.tr('ads_messages'),
      children: [
        Panel(
          title: context.tr('ad_new_message'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilterRow<MessageAudience>(
                values: MessageAudience.values,
                selected: _audience,
                label: (v) => context.tr('ma_${v!.name}'),
                onSelected: (v) =>
                    setState(() => _audience = v ?? MessageAudience.all),
              ),
              if (_audience == MessageAudience.user)
                DropdownButtonFormField<String>(
                  initialValue: _target,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('ad_recipient'),
                  ),
                  items: [
                    for (final t in targets)
                      DropdownMenuItem(
                        value: t.$1,
                        child: Text(
                          '${t.$2} (${context.tr('ma_${t.$3.name}')})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _target = v),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: context.tr('ad_msg_title'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('ad_msg_body'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  label: Text(context.tr('ad_send')),
                ),
              ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_alerts'),
          child: Column(
            children: [
              if (alerts.isEmpty) Text(context.tr('ad_no_alerts')),
              for (final a in alerts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(a.icon, color: a.color),
                  title: Text(context.tr(a.key)),
                  trailing: Pill(label: '${a.count}', color: a.color),
                ),
            ],
          ),
        ),
        Panel(
          title: context.tr('ad_decisions_follow'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in decisions) AuditTile(entry: d, dense: true),
              const Divider(),
              for (final r in facilities.referrals.take(6))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: Text(
                    '${r.code} • ${facilities.facility(r.facilityId)?.name ?? ''}',
                  ),
                  trailing: Pill(
                    label: context.tr(referralStatusKey(r.status)),
                    color: referralStatusColor(r.status),
                  ),
                ),
              for (final s in summons)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: AppColors.primary),
                  title: Text('${s.code} • ${s.issuerName}'),
                  subtitle: Text(fmtDateTime(s.appointment)),
                ),
            ],
          ),
        ),
        Panel(
          title: '${context.tr('ad_sent_messages')} (${admin.messages.length})',
          child: Column(
            children: [
              for (final m in admin.messages)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.campaign_outlined),
                  title: Text(m.title),
                  subtitle: Text(
                    '${m.audience == MessageAudience.user ? m.targetName : context.tr('ma_${m.audience.name}')}'
                    ' • ${m.by} • ${fmtDateTime(m.at)}\n${m.body}',
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
