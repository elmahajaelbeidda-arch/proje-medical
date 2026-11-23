import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_provider.dart';
import '../../core/admin_remote.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';

/// Saves the dashboard on the server a moment after each change, while a
/// team member is signed in through the server.
class AdminSync extends ConsumerStatefulWidget {
  const AdminSync({super.key, required this.child});
  final Widget child;

  static _AdminSyncState? _current;

  /// Saves now (e.g. before signing out).
  static Future<void> flush(WidgetRef ref) async {
    await _current?._save();
  }

  @override
  ConsumerState<AdminSync> createState() => _AdminSyncState();
}

class _AdminSyncState extends ConsumerState<AdminSync> {
  Timer? _timer;
  bool _dirty = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    AdminSync._current = this;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (identical(AdminSync._current, this)) AdminSync._current = null;
    super.dispose();
  }

  Future<void> _save() async {
    _timer?.cancel();
    if (!_dirty) return;
    final s = ref.read(adminProvider);
    if (!s.remote || s.me == null) return;
    final n = ref.read(adminProvider.notifier);
    _dirty = false;
    try {
      await const AdminRemote().save(
        state: n.serverState(),
        public: n.serverPublic(),
      );
      if (_failed && mounted) setState(() => _failed = false);
    } catch (_) {
      _dirty = true;
      if (mounted) setState(() => _failed = true);
      // Try again a little later.
      _timer = Timer(const Duration(seconds: 10), _save);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminProvider, (prev, next) {
      if (!next.remote || next.me == null) return;
      // Signing in loads the data: nothing to save yet.
      if (prev?.me == null) return;
      _dirty = true;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 1200), _save);
    });
    return Stack(
      children: [
        widget.child,
        if (_failed)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Material(
                color: AppColors.emergency,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr('ad_save_failed'),
                    style: TextStyle(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
