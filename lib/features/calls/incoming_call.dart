import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/accounts_remote.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

/// Patients (server accounts): when their doctor starts a call, a window
/// offers to answer, wherever they are in the app.
class IncomingCallWatcher extends ConsumerStatefulWidget {
  const IncomingCallWatcher({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<IncomingCallWatcher> createState() =>
      _IncomingCallWatcherState();
}

class _IncomingCallWatcherState extends ConsumerState<IncomingCallWatcher> {
  /// Calls already offered (consultation id + time), never asked twice.
  final _seen = <String>{};
  bool _showing = false;

  /// A call is offered while it is fresh (the doctor waits in the room).
  static const _ringWindow = Duration(minutes: 2);

  void _check(List<Consultation> list) {
    if (!AccountsRemote.enabled || _showing) return;
    final auth = ref.read(authProvider);
    if (!auth.loggedIn || auth.isDoctor) return;
    final now = DateTime.now();
    for (final c in list) {
      if (c.patientId != CurrentAccount.patientId) continue;
      ChatMessage? call;
      for (final m in c.messages.reversed) {
        if (m.call != null && m.fromDoctor) {
          call = m;
          break;
        }
      }
      if (call == null || now.difference(call.time) > _ringWindow) continue;
      final key = '${c.id}@${call.time.toIso8601String()}';
      if (!_seen.add(key)) continue;
      _offer(c, call.call!);
      return;
    }
  }

  Future<void> _offer(Consultation c, CallKind kind) async {
    final router = ref.read(routerProvider);
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null) return;
    // Already in this call's screen: nothing to ask.
    if (router.state.uri.path == '/call/${c.id}') return;
    _showing = true;
    HapticFeedback.heavyImpact();
    final doctor = consultationDoctor(c)?.name ?? '';
    final answer = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        icon: CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.secondary,
          child: Icon(
            kind == CallKind.video ? LucideIcons.video : LucideIcons.phone,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          d.tr(
            kind == CallKind.video ? 'lc_incoming_video' : 'lc_incoming_voice',
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(doctor, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(d.tr('lc_later')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(d, true),
            icon: const Icon(LucideIcons.phone),
            label: Text(d.tr('lc_answer')),
          ),
        ],
      ),
    );
    _showing = false;
    if (answer == true) {
      router.push(
        Uri(
          path: '/call/${c.id}',
          queryParameters: {'kind': kind.name, 'name': doctor},
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(consultationsProvider, (_, next) => _check(next));
    return widget.child;
  }
}
