/// Real accounts of patients and volunteer doctors (Supabase), see
/// supabase/migrations/0005_accounts.sql.
///
/// People sign in with their account code (P-013 / M-023), phone number or
/// national ID number (NNI) and a password. Behind the scenes each account
/// has a sign-in address made from its phone number (no real mailbox).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/aid/aid_repository.dart' show supabaseConfigured;
import '../models/models.dart';
import '../models/registration.dart';

class RemoteProfile {
  final String userId;
  final UserRole role;
  final String code;
  final String name;
  final String phone;
  final String nationalId;
  final String? specialtyId;
  final String? licenseNumber;
  final String? certificatePath;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const RemoteProfile({
    required this.userId,
    required this.role,
    required this.code,
    required this.name,
    required this.phone,
    required this.nationalId,
    required this.status,
    required this.createdAt,
    this.specialtyId,
    this.licenseNumber,
    this.certificatePath,
    this.reviewedAt,
  });

  factory RemoteProfile.fromJson(Map<String, dynamic> j) => RemoteProfile(
    userId: j['user_id'] as String,
    role: j['role'] == 'doctor' ? UserRole.doctor : UserRole.patient,
    code: j['code'] as String? ?? '',
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    nationalId: j['national_id'] as String? ?? '',
    specialtyId: j['specialty_id'] as String?,
    licenseNumber: j['license_number'] as String?,
    certificatePath: j['certificate_path'] as String?,
    status: ReviewStatus.values.firstWhere(
      (s) => s.name == j['status'],
      orElse: () => ReviewStatus.pending,
    ),
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
    reviewedAt: DateTime.tryParse(j['reviewed_at'] as String? ?? ''),
  );

  Registration toRegistration() => Registration(
    id: userId,
    serverCode: code,
    role: role,
    name: name,
    phone: phone,
    idNumber: nationalId,
    specialtyId: specialtyId,
    licenseNumber: licenseNumber,
    certificate: certificatePath == null
        ? null
        : Attachment(
            certificatePath!.split('/').last,
            certificatePath!.toLowerCase().endsWith('.pdf')
                ? AttachmentKind.pdf
                : AttachmentKind.image,
            category: AttachmentCategory.other,
          ),
    phoneVerified: false,
    status: status,
    createdAt: createdAt,
    reviewedAt: reviewedAt,
  );
}

enum AccountError {
  notFound,
  wrongPassword,
  confirmEmailOn,
  weakPassword,
  network,
}

class AccountException implements Exception {
  final AccountError error;
  const AccountException(this.error);
}

class AccountsRemote {
  const AccountsRemote();

  static bool get enabled => supabaseConfigured;

  SupabaseClient get _db => Supabase.instance.client;

  /// Sign-in address behind an account (made from the phone, unique).
  static String loginAddress(UserRole role, String phone) {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final r = role == UserRole.doctor ? 'm' : 'p';
    return '$r${normalizePhone(phone)}.$stamp@users.chifa-linnas.app';
  }

  /// Creates the account and its profile (waiting for the team's review).
  /// Throws [DuplicateRegistrationException] when the person is already
  /// registered.
  Future<RemoteProfile> signUp({
    required UserRole role,
    required String name,
    required String phone,
    required String nationalId,
    required String password,
    String? specialtyId,
    String? licenseNumber,
    Attachment? certificate,
  }) async {
    final String? conflict;
    try {
      conflict = await _db.rpc(
        'registration_conflict',
        params: {
          'p_role': role.name,
          'p_phone': phone,
          'p_national_id': nationalId,
          'p_license': licenseNumber ?? '',
        },
      );
    } catch (_) {
      throw const AccountException(AccountError.network);
    }
    if (conflict != null) throw DuplicateRegistrationException(conflict);

    final AuthResponse res;
    try {
      res = await _db.auth.signUp(
        email: loginAddress(role, phone),
        password: password,
      );
    } on AuthException catch (e) {
      final weak =
          e.message.toLowerCase().contains('password') ||
          e.code == 'weak_password';
      throw AccountException(
        weak ? AccountError.weakPassword : AccountError.network,
      );
    } catch (_) {
      throw const AccountException(AccountError.network);
    }
    // «Confirm email» must be off in Supabase (no real mailbox).
    if (res.session == null || res.user == null) {
      throw const AccountException(AccountError.confirmEmailOn);
    }
    final uid = res.user!.id;
    final row = await _db
        .from('profiles')
        .insert({
          'user_id': uid,
          'role': role.name,
          'name': name.trim(),
          'phone': phone,
          'national_id': nationalId.trim(),
          'specialty_id': specialtyId,
          'license_number': licenseNumber,
        })
        .select()
        .single();
    var profile = RemoteProfile.fromJson(row);
    final bytes = certificate?.bytes;
    if (certificate != null && bytes != null) {
      try {
        final ext = certificate.name.contains('.')
            ? certificate.name.split('.').last.toLowerCase()
            : 'pdf';
        final path = '$uid/certificate.$ext';
        await _db.storage
            .from('documents')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        final updated = await _db
            .from('profiles')
            .update({'certificate_path': path})
            .eq('user_id', uid)
            .select()
            .single();
        profile = RemoteProfile.fromJson(updated);
      } catch (_) {
        // The account exists; the certificate can be sent again later.
      }
    }
    return profile;
  }

  /// Signs in with an account code, a phone number or the NNI.
  Future<RemoteProfile> signIn(String identifier, String password) async {
    final String? email;
    try {
      email = await _db.rpc(
        'login_email',
        params: {'p_identifier': identifier},
      );
    } catch (_) {
      throw const AccountException(AccountError.network);
    }
    if (email == null) throw const AccountException(AccountError.notFound);
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      throw const AccountException(AccountError.wrongPassword);
    } catch (_) {
      throw const AccountException(AccountError.network);
    }
    final me = await current();
    if (me == null) throw const AccountException(AccountError.notFound);
    return me;
  }

  /// Profile of the account kept signed in on this phone, if any.
  Future<RemoteProfile?> current() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _db
          .from('profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return row == null ? null : RemoteProfile.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _db.auth.signOut();
    } catch (_) {}
  }

  // ---------- Team (dashboard) --------------------------------------------

  Future<List<RemoteProfile>> listProfiles() async {
    final List<dynamic> rows = await _db
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return [
      for (final r in rows) RemoteProfile.fromJson(r as Map<String, dynamic>),
    ];
  }

  Future<void> review(String userId, ReviewStatus status) async {
    await _db
        .from('profiles')
        .update({'status': status.name})
        .eq('user_id', userId);
  }

  /// Short-lived link to read a doctor's certificate.
  Future<String?> certificateUrl(String path) async {
    try {
      return await _db.storage.from('documents').createSignedUrl(path, 600);
    } catch (_) {
      return null;
    }
  }
}
