import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/calls.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

IconData callIcon(CallKind k) =>
    k == CallKind.video ? LucideIcons.video : LucideIcons.phone;
String callKey(CallKind k) => 'call_${k.name}';

/// Shows a short note, logs the call and opens the private room.
/// Returns true when the call was opened.
Future<bool> openCall(
  BuildContext context,
  WidgetRef ref, {
  required String contextId,
  required CallKind kind,
  required bool byDoctor,
  required String displayName,
}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(callIcon(kind), color: AppColors.primary, size: 40),
      title: Text(
        ctx.tr(
          byDoctor ? 'call_start_title' : 'call_join_title',
          args: {'kind': ctx.tr(callKey(kind))},
        ),
      ),
      content: Text(ctx.tr('call_note'), textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: Icon(callIcon(kind)),
          label: Text(ctx.tr(byDoctor ? 'call_start' : 'call_join')),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;
  final calls = ref.read(callsProvider.notifier);
  final room = calls.roomFor(contextId);
  calls.start(contextId, kind, byDoctor: byDoctor);
  final uri = callUri(
    server: ref.read(callServerProvider),
    room: room,
    kind: kind,
    displayName: displayName,
  );
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('call_failed');
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
  return true;
}

/// Voice and video buttons for an app bar. When [enabled] is false a tap
/// explains why ([disabledKey]).
class CallActions extends StatelessWidget {
  const CallActions({
    super.key,
    required this.enabled,
    required this.onCall,
    this.disabledKey = 'call_wait_doctor',
    this.onDark = false,
  });
  final bool enabled;

  /// On a coloured header: white icons.
  final bool onDark;
  final void Function(CallKind kind) onCall;
  final String disabledKey;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final k in [CallKind.voice, CallKind.video])
        IconButton(
          tooltip: context.tr(callKey(k)),
          onPressed: enabled
              ? () => onCall(k)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr(disabledKey))),
                ),
          icon: Icon(
            callIcon(k),
            color: onDark
                ? (enabled ? AppColors.onPrimary : Colors.white54)
                : (enabled ? null : Theme.of(context).disabledColor),
          ),
        ),
    ],
  );
}

/// Chat bubble announcing a call the doctor started.
class CallBubble extends StatelessWidget {
  const CallBubble({
    super.key,
    required this.kind,
    required this.time,
    required this.canJoin,
    required this.onJoin,
  });
  final CallKind kind;
  final DateTime time;
  final bool canJoin;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.vivid,
            child: Icon(callIcon(kind), color: AppColors.onPrimary, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  'call_started_msg',
                  args: {'kind': context.tr(callKey(kind))},
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                context.timeAgo(time),
                style: TextStyle(fontSize: 11, color: AppColors.grey),
              ),
            ],
          ),
          if (canJoin) ...[
            const SizedBox(width: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(64, 36),
              ),
              onPressed: onJoin,
              child: Text(context.tr('call_join')),
            ),
          ],
        ],
      ),
    ),
  );
}
