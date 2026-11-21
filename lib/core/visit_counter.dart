import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/aid/aid_repository.dart' show supabaseConfigured;

// ---------------------------------------------------------------------------
// Public visitor counter, shown to everyone (no sign-in needed).
//
// With Supabase (see supabase/migrations/0003_visit_counter.sql) the figures
// are shared by all devices. Without it, demo figures are shown and marked
// as such.
//
// Privacy: a visitor is only a random id kept on the device.
// ---------------------------------------------------------------------------

class VisitStats {
  final int totalVisits;
  final int todayVisitors;
  final int onlineNow;

  /// Null when the association chose not to show it.
  final int? registered;
  final int? beneficiaries;

  /// Demo figures (no shared database yet).
  final bool demo;
  final DateTime updatedAt;

  const VisitStats({
    required this.totalVisits,
    required this.todayVisitors,
    required this.onlineNow,
    required this.updatedAt,
    this.registered,
    this.beneficiaries,
    this.demo = false,
  });

  factory VisitStats.fromJson(Map<String, dynamic> j) => VisitStats(
    totalVisits: (j['total_visits'] as num?)?.toInt() ?? 0,
    todayVisitors: (j['today_visitors'] as num?)?.toInt() ?? 0,
    onlineNow: math.max(1, (j['online_now'] as num?)?.toInt() ?? 1),
    registered: (j['registered'] as num?)?.toInt(),
    beneficiaries: (j['beneficiaries'] as num?)?.toInt(),
    updatedAt: DateTime.now(),
  );
}

abstract class VisitBackend {
  Future<void> record(String visitorId);
  Future<VisitStats> stats();
}

class SupabaseVisitBackend implements VisitBackend {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<void> record(String visitorId) =>
      _db.rpc<void>('record_visit', params: {'p_visitor': visitorId});

  @override
  Future<VisitStats> stats() async {
    final r = await _db.rpc<dynamic>('public_stats');
    return VisitStats.fromJson(Map<String, dynamic>.from(r as Map));
  }
}

/// Plausible figures that move a little, until the database is connected.
class DemoVisitBackend implements VisitBackend {
  DemoVisitBackend({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  static final _launch = DateTime(2026, 6, 1);

  @override
  Future<void> record(String visitorId) async {}

  @override
  Future<VisitStats> stats() async {
    final now = _clock();
    final minutes = math.max(0, now.difference(_launch).inMinutes);
    final dayMinutes = now.hour * 60 + now.minute;
    final wave = math.sin(now.millisecondsSinceEpoch / 90000);
    return VisitStats(
      totalVisits: 18240 + minutes ~/ 9,
      todayVisitors: 120 + dayMinutes ~/ 4,
      onlineNow: 34 + (wave * 9).round(),
      registered: 2310 + minutes ~/ 180,
      beneficiaries: 1240 + minutes ~/ 420,
      updatedAt: now,
      demo: true,
    );
  }
}

final visitBackendProvider = Provider<VisitBackend>(
  (ref) => supabaseConfigured ? SupabaseVisitBackend() : DemoVisitBackend(),
);

/// How often the figures refresh (and the visitor says "still here").
final visitRefreshProvider = Provider<Duration>(
  (_) => const Duration(seconds: 30),
);

const _idKey = 'visitor_id';

String newVisitorId([math.Random? rnd]) {
  final r = rnd ?? math.Random.secure();
  const hex = '0123456789abcdef';
  return List.generate(32, (_) => hex[r.nextInt(16)]).join();
}

Future<String> loadVisitorId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_idKey);
    if (saved != null && saved.length >= 16) return saved;
    final id = newVisitorId();
    await prefs.setString(_idKey, id);
    return id;
  } catch (_) {
    // Storage unavailable (private browsing, tests): one id per session.
    return newVisitorId();
  }
}

class VisitCounterNotifier extends Notifier<VisitStats?> {
  Timer? _timer;
  String? _id;

  @override
  VisitStats? build() {
    ref.onDispose(() => _timer?.cancel());
    final every = ref.watch(visitRefreshProvider);
    Future.microtask(() async {
      _id = await loadVisitorId();
      await _tick();
      if (!ref.mounted) return;
      _timer = Timer.periodic(every, (_) => _tick());
    });
    return null;
  }

  Future<void> _tick() async {
    final backend = ref.read(visitBackendProvider);
    try {
      if (_id != null) await backend.record(_id!);
      final s = await backend.stats();
      if (ref.mounted) state = s;
    } catch (_) {
      // Offline or server unreachable: keep the last figures.
    }
  }

  /// Pull to refresh.
  Future<void> refresh() => _tick();
}

final visitCounterProvider =
    NotifierProvider<VisitCounterNotifier, VisitStats?>(
      VisitCounterNotifier.new,
    );
