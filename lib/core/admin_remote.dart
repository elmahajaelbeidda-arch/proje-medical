/// The dashboard on the server (Supabase): real sign-in of the team, and
/// the dashboard data saved for everyone (see supabase/migrations/0004).
///
/// Without a configured server (SUPABASE_URL / SUPABASE_ANON_KEY at build
/// time) the dashboard keeps working on demo accounts, in memory.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/aid/aid_repository.dart' show supabaseConfigured;
import '../models/admin.dart';

class StaffRow {
  final String userId;
  final String email;
  final String name;
  final AdminRole role;
  final bool active;
  final DateTime createdAt;
  const StaffRow({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  factory StaffRow.fromJson(Map<String, dynamic> j) => StaffRow(
    userId: j['user_id'] as String,
    email: j['email'] as String? ?? '',
    name: j['name'] as String? ?? '',
    role: AdminRole.values.firstWhere(
      (r) => r.name == j['role'],
      orElse: () => AdminRole.followUp,
    ),
    active: j['active'] as bool? ?? true,
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  AdminAccount toAccount() => AdminAccount(
    id: userId,
    name: name.isEmpty ? email : name,
    email: email,
    // The password lives on the server (Supabase Auth), never here.
    salt: '',
    passwordHash: '',
    role: role,
    permissions: rolePermissions(role),
    active: active,
    createdAt: createdAt,
  );
}

/// Why a server sign-in failed.
enum RemoteLoginError { wrongPassword, notStaff, disabled, network }

class RemoteLoginException implements Exception {
  final RemoteLoginError error;
  const RemoteLoginException(this.error);
}

/// What a successful sign-in brings back.
class RemoteSession {
  final String userId;
  final List<StaffRow> staff;

  /// Saved dashboard data (null the very first time).
  final Map<String, dynamic>? state;
  const RemoteSession(this.userId, this.staff, this.state);
}

class AdminRemote {
  const AdminRemote();

  static bool get enabled => supabaseConfigured;

  SupabaseClient get _db => Supabase.instance.client;

  Future<RemoteSession> signIn(String email, String password) async {
    try {
      await _db.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException {
      throw const RemoteLoginException(RemoteLoginError.wrongPassword);
    } catch (_) {
      throw const RemoteLoginException(RemoteLoginError.network);
    }
    return _openSession();
  }

  /// Session kept by Supabase from an earlier visit, if any.
  Future<RemoteSession?> resume() async {
    if (_db.auth.currentUser == null) return null;
    try {
      return await _openSession();
    } catch (_) {
      return null;
    }
  }

  Future<RemoteSession> _openSession() async {
    final uid = _db.auth.currentUser!.id;
    final List<dynamic> rows;
    try {
      rows = await _db.from('admin_staff').select();
    } catch (_) {
      throw const RemoteLoginException(RemoteLoginError.network);
    }
    final staff = [
      for (final r in rows) StaffRow.fromJson(r as Map<String, dynamic>),
    ];
    final me = staff.where((s) => s.userId == uid).firstOrNull;
    if (me == null) {
      await _db.auth.signOut();
      throw const RemoteLoginException(RemoteLoginError.notStaff);
    }
    if (!me.active) {
      await _db.auth.signOut();
      throw const RemoteLoginException(RemoteLoginError.disabled);
    }
    final saved = await _db
        .from('admin_store')
        .select('data')
        .eq('id', 'state')
        .maybeSingle();
    return RemoteSession(
      uid,
      staff,
      saved == null ? null : saved['data'] as Map<String, dynamic>,
    );
  }

  Future<void> signOut() => _db.auth.signOut();

  /// Checks the current password, then sets the new one.
  Future<bool> changePassword(String current, String next) async {
    final email = _db.auth.currentUser?.email;
    if (email == null) return false;
    try {
      await _db.auth.signInWithPassword(email: email, password: current);
      await _db.auth.updateUser(UserAttributes(password: next));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Saves the dashboard data, and the part the users' app reads.
  Future<void> save({
    required Map<String, dynamic> state,
    required Map<String, dynamic> public,
  }) async {
    await _db.from('admin_store').upsert([
      {'id': 'state', 'data': state},
      {'id': 'public', 'data': public},
    ]);
  }

  /// Adds a team member (their account must exist in Supabase Auth).
  Future<void> grantStaff(String email, String name, AdminRole role) async {
    await _db.rpc(
      'grant_staff',
      params: {'p_email': email, 'p_name': name, 'p_role': role.name},
    );
  }

  Future<List<StaffRow>> listStaff() async {
    final List<dynamic> rows = await _db.from('admin_staff').select();
    return [for (final r in rows) StaffRow.fromJson(r as Map<String, dynamic>)];
  }

  Future<void> setStaffActive(String userId, bool active) async {
    await _db
        .from('admin_staff')
        .update({'active': active})
        .eq('user_id', userId);
  }

  /// Users' app: sections on/off, association information, announcements.
  static Future<Map<String, dynamic>?> loadPublic() async {
    if (!enabled) return null;
    try {
      final row = await Supabase.instance.client
          .from('admin_store')
          .select('data')
          .eq('id', 'public')
          .maybeSingle();
      return row == null ? null : row['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
