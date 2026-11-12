import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/admin/totp.dart';
import '../models/admin.dart';

/// Demo code accepted for admin accounts that have not yet linked an
/// authenticator app.
const adminDemoCode = '123456';

class AdminState {
  final List<AdminAccount> admins;
  final List<AuditEntry> audit;
  final List<Donation> donations;
  final List<Expense> expenses;
  final List<ServiceRecord> services;
  final Map<String, FacilityAgreement> agreements;
  final Map<String, CaseDecision> caseDecisions;
  final Map<String, DoctorEvaluation> evaluations;
  final List<AdminMessage> messages;
  final List<Announcement> announcements;
  final AppSettings settings;

  /// Suspended accounts (registration or facility id) → reason.
  final Map<String, String> suspendedAccounts;

  /// Card renewals: holder id → renewal date (valid one more year).
  final Map<String, DateTime> cardRenewals;

  // Session
  final String? sessionAdminId;
  final bool sessionVerified;
  final int failedLogins;
  final DateTime? lockedUntil;

  const AdminState({
    required this.admins,
    this.audit = const [],
    this.donations = const [],
    this.expenses = const [],
    this.services = const [],
    this.agreements = const {},
    this.caseDecisions = const {},
    this.evaluations = const {},
    this.messages = const [],
    this.announcements = const [],
    this.settings = const AppSettings(),
    this.suspendedAccounts = const {},
    this.cardRenewals = const {},
    this.sessionAdminId,
    this.sessionVerified = false,
    this.failedLogins = 0,
    this.lockedUntil,
  });

  AdminAccount? get me {
    if (!sessionVerified) return null;
    for (final a in admins) {
      if (a.id == sessionAdminId && a.active) return a;
    }
    return null;
  }

  bool can(AdminPermission p) => me?.can(p) ?? false;

  int get totalDonations => donations.fold(0, (s, d) => s + d.amount);
  int get totalExpenses => expenses.fold(0, (s, e) => s + e.amount);
  int get balance => totalDonations - totalExpenses;

  AdminState copyWith({
    List<AdminAccount>? admins,
    List<AuditEntry>? audit,
    List<Donation>? donations,
    List<Expense>? expenses,
    List<ServiceRecord>? services,
    Map<String, FacilityAgreement>? agreements,
    Map<String, CaseDecision>? caseDecisions,
    Map<String, DoctorEvaluation>? evaluations,
    List<AdminMessage>? messages,
    List<Announcement>? announcements,
    AppSettings? settings,
    Map<String, String>? suspendedAccounts,
    Map<String, DateTime>? cardRenewals,
    String? sessionAdminId,
    bool clearSession = false,
    bool? sessionVerified,
    int? failedLogins,
    DateTime? lockedUntil,
    bool clearLock = false,
  }) => AdminState(
    admins: admins ?? this.admins,
    audit: audit ?? this.audit,
    donations: donations ?? this.donations,
    expenses: expenses ?? this.expenses,
    services: services ?? this.services,
    agreements: agreements ?? this.agreements,
    caseDecisions: caseDecisions ?? this.caseDecisions,
    evaluations: evaluations ?? this.evaluations,
    messages: messages ?? this.messages,
    announcements: announcements ?? this.announcements,
    settings: settings ?? this.settings,
    suspendedAccounts: suspendedAccounts ?? this.suspendedAccounts,
    cardRenewals: cardRenewals ?? this.cardRenewals,
    sessionAdminId: clearSession
        ? null
        : (sessionAdminId ?? this.sessionAdminId),
    sessionVerified: clearSession
        ? false
        : (sessionVerified ?? this.sessionVerified),
    failedLogins: failedLogins ?? this.failedLogins,
    lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
  );
}

enum LoginResult { needCode, wrong, locked, disabled }

class AdminNotifier extends Notifier<AdminState> {
  int _seq = 0;
  String _id(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}${_seq++}';

  @override
  AdminState build() => _seed();

  // -------------------------------------------------------------------------
  // Audit
  // -------------------------------------------------------------------------

  void _log(
    String action, {
    String target = '',
    String details = '',
    bool sensitive = false,
    AdminAccount? as,
  }) {
    final a = as ?? state.me;
    state = state.copyWith(
      audit: [
        AuditEntry(
          id: _id('au'),
          at: DateTime.now(),
          adminId: a?.id ?? '-',
          adminName: a?.name ?? '-',
          action: action,
          target: target,
          details: details,
          sensitive: sensitive,
        ),
        ...state.audit,
      ],
    );
  }

  /// Every protected action goes through here: refused (and logged) when
  /// the admin lacks the permission.
  AdminAccount _require(AdminPermission p) {
    final me = state.me;
    if (me == null || !me.can(p)) {
      _log('au_denied', details: p.name, as: me);
      throw AdminPermissionDenied(p);
    }
    return me;
  }

  /// Public wrapper for actions done in other providers (approvals...).
  void authorize(AdminPermission p) => _require(p);

  /// Logs an action done in another part of the app, only when it is done
  /// by a signed-in member of the follow-up & management team.
  void recordIfAdmin(
    String action, {
    String target = '',
    String details = '',
    bool sensitive = false,
  }) {
    if (state.me == null) return;
    _log(action, target: target, details: details, sensitive: sensitive);
  }

  /// Logs an action done elsewhere (e.g. approving a registration).
  void record(
    String action, {
    String target = '',
    String details = '',
    bool sensitive = false,
  }) => _log(action, target: target, details: details, sensitive: sensitive);

  // -------------------------------------------------------------------------
  // Session: password, then second factor
  // -------------------------------------------------------------------------

  LoginResult login(String email, String password) {
    final now = DateTime.now();
    if (state.lockedUntil != null && now.isBefore(state.lockedUntil!)) {
      return LoginResult.locked;
    }
    AdminAccount? a;
    for (final x in state.admins) {
      if (x.email.toLowerCase() == email.trim().toLowerCase()) a = x;
    }
    if (a == null || !a.checkPassword(password)) {
      final failed = state.failedLogins + 1;
      state = state.copyWith(
        failedLogins: failed,
        lockedUntil: failed >= 5 ? now.add(const Duration(minutes: 5)) : null,
      );
      _log('au_login_failed', target: email.trim(), as: a);
      return failed >= 5 ? LoginResult.locked : LoginResult.wrong;
    }
    if (!a.active) {
      _log('au_login_disabled', target: a.email, as: a);
      return LoginResult.disabled;
    }
    state = state.copyWith(
      sessionAdminId: a.id,
      sessionVerified: false,
      failedLogins: 0,
      clearLock: true,
    );
    return LoginResult.needCode;
  }

  /// Second factor: authenticator code, or the demo code for accounts that
  /// have not linked an app yet.
  bool verifyCode(String code) {
    AdminAccount? a;
    for (final x in state.admins) {
      if (x.id == state.sessionAdminId) a = x;
    }
    if (a == null) return false;
    final ok = a.totpSecret == null
        ? code.trim() == adminDemoCode
        : Totp.verify(a.totpSecret!, code);
    if (!ok) {
      _log('au_2fa_failed', target: a.email, as: a);
      return false;
    }
    state = state.copyWith(
      sessionVerified: true,
      admins: [
        for (final x in state.admins)
          x.id == a.id ? x.copyWith(lastLoginAt: DateTime.now()) : x,
      ],
    );
    _log('au_login', target: a.email);
    return true;
  }

  void logout() {
    if (state.me != null) _log('au_logout');
    state = state.copyWith(clearSession: true);
  }

  /// Link an authenticator app to my account (code checked first).
  bool enableTotp(String secret, String code) {
    final me = state.me;
    if (me == null || !Totp.verify(secret, code)) return false;
    _replaceAdmin(me.copyWith(totpSecret: secret));
    _log('au_2fa_enabled', target: me.email);
    return true;
  }

  bool changeMyPassword(String current, String next) {
    final me = state.me;
    if (me == null || !me.checkPassword(current) || next.length < 8) {
      return false;
    }
    final salt = _id('s');
    _replaceAdmin(
      me.copyWith(salt: salt, passwordHash: hashPassword(salt, next)),
    );
    _log('au_password_changed', target: me.email);
    return true;
  }

  // -------------------------------------------------------------------------
  // Admin accounts
  // -------------------------------------------------------------------------

  void _replaceAdmin(AdminAccount a) => state = state.copyWith(
    admins: [for (final x in state.admins) x.id == a.id ? a : x],
  );

  String createAdmin({
    required String name,
    required String email,
    required String password,
    required AdminRole role,
    Set<AdminPermission>? permissions,
  }) {
    _require(AdminPermission.manageAdmins);
    final e = email.trim().toLowerCase();
    if (state.admins.any((a) => a.email.toLowerCase() == e)) {
      throw ArgumentError('email exists');
    }
    if (password.length < 8) throw ArgumentError('weak password');
    final salt = _id('s');
    final id = _id('adm');
    final perms = role == AdminRole.custom
        ? (permissions ?? const {})
        : rolePermissions(role);
    state = state.copyWith(
      admins: [
        ...state.admins,
        AdminAccount(
          id: id,
          name: name.trim(),
          email: e,
          salt: salt,
          passwordHash: hashPassword(salt, password),
          role: role,
          permissions: {...perms},
          createdAt: DateTime.now(),
        ),
      ],
    );
    _log('au_admin_created', target: e, details: role.name);
    return id;
  }

  void updatePermissions(
    String adminId,
    AdminRole role,
    Set<AdminPermission> permissions,
  ) {
    final me = _require(AdminPermission.manageAdmins);
    final a = state.admins.firstWhere((x) => x.id == adminId);
    // Nobody removes their own right to manage admins (no lock-out).
    final perms = a.id == me.id
        ? {...permissions, AdminPermission.manageAdmins}
        : permissions;
    _replaceAdmin(a.copyWith(role: role, permissions: perms));
    _log(
      'au_permissions_changed',
      target: a.email,
      details: '${role.name}: ${perms.map((p) => p.name).join(', ')}',
    );
  }

  void setAdminActive(String adminId, bool active) {
    final me = _require(AdminPermission.manageAdmins);
    if (adminId == me.id) throw ArgumentError('cannot disable yourself');
    final a = state.admins.firstWhere((x) => x.id == adminId);
    _replaceAdmin(a.copyWith(active: active));
    _log(active ? 'au_admin_enabled' : 'au_admin_disabled', target: a.email);
  }

  void resetTwoFactor(String adminId) {
    _require(AdminPermission.manageAdmins);
    final a = state.admins.firstWhere((x) => x.id == adminId);
    _replaceAdmin(a.copyWith(clearTotp: true));
    _log('au_2fa_reset', target: a.email);
  }

  // -------------------------------------------------------------------------
  // Accounts and cards
  // -------------------------------------------------------------------------

  void suspendAccount(String holderId, String name, String reason) {
    _require(AdminPermission.suspendAccounts);
    if (reason.trim().isEmpty) throw ArgumentError('reason required');
    state = state.copyWith(
      suspendedAccounts: {...state.suspendedAccounts, holderId: reason.trim()},
    );
    _log('au_account_suspended', target: name, details: reason.trim());
  }

  void reactivateAccount(String holderId, String name) {
    _require(AdminPermission.suspendAccounts);
    state = state.copyWith(
      suspendedAccounts: {...state.suspendedAccounts}..remove(holderId),
    );
    _log('au_account_reactivated', target: name);
  }

  void renewCard(String holderId, String cardNumber) {
    _require(AdminPermission.manageCards);
    state = state.copyWith(
      cardRenewals: {...state.cardRenewals, holderId: DateTime.now()},
    );
    _log('au_card_renewed', target: cardNumber);
  }

  // -------------------------------------------------------------------------
  // Cases and doctors
  // -------------------------------------------------------------------------

  /// Opening a medical file: permission + reason, always logged.
  void openMedicalFile(String caseCode, String reason) {
    _require(AdminPermission.viewMedicalRecords);
    if (reason.trim().isEmpty) throw ArgumentError('reason required');
    _log(
      'au_medical_opened',
      target: caseCode,
      details: reason.trim(),
      sensitive: true,
    );
  }

  void decideCase(
    String caseId,
    String caseCode,
    CaseStage stage,
    String note,
  ) {
    final me = _require(AdminPermission.manageCases);
    if ((stage == CaseStage.rejected || stage == CaseStage.onHold) &&
        note.trim().isEmpty) {
      throw ArgumentError('reason required');
    }
    state = state.copyWith(
      caseDecisions: {
        ...state.caseDecisions,
        caseId: CaseDecision(stage, note.trim(), DateTime.now(), me.name),
      },
    );
    _log('au_case_${stage.name}', target: caseCode, details: note.trim());
  }

  void clearCaseDecision(String caseId, String caseCode) {
    _require(AdminPermission.manageCases);
    state = state.copyWith(
      caseDecisions: {...state.caseDecisions}..remove(caseId),
    );
    _log('au_case_reopened', target: caseCode);
  }

  void evaluateDoctor(String doctorId, String name, int score, String note) {
    _require(AdminPermission.manageDoctors);
    state = state.copyWith(
      evaluations: {
        ...state.evaluations,
        doctorId: DoctorEvaluation(
          score.clamp(1, 5),
          note.trim(),
          DateTime.now(),
        ),
      },
    );
    _log(
      'au_doctor_evaluated',
      target: name,
      details: '$score/5 ${note.trim()}',
    );
  }

  // -------------------------------------------------------------------------
  // Facilities
  // -------------------------------------------------------------------------

  void setAgreement(String facilityId, String name, FacilityAgreement a) {
    _require(AdminPermission.manageFacilities);
    if (a.end.isBefore(a.start)) throw ArgumentError('end before start');
    state = state.copyWith(agreements: {...state.agreements, facilityId: a});
    _log('au_agreement_saved', target: name);
  }

  void addServiceRecord(ServiceRecord r, String facilityName) {
    _require(AdminPermission.manageFacilities);
    state = state.copyWith(
      services: [
        ServiceRecord(
          id: _id('sv'),
          facilityId: r.facilityId,
          service: r.service,
          free: r.free,
          value: r.value,
          discount: r.discount,
          caseRef: r.caseRef,
          date: r.date,
        ),
        ...state.services,
      ],
    );
    _log('au_service_recorded', target: facilityName, details: r.service);
  }

  // -------------------------------------------------------------------------
  // Finance
  // -------------------------------------------------------------------------

  String addDonation(Donation d) {
    _require(AdminPermission.manageFinance);
    if (d.amount <= 0) throw ArgumentError('amount');
    final id = _id('dn');
    state = state.copyWith(
      donations: [
        Donation(
          id: id,
          donor: d.donor.trim(),
          anonymous: d.anonymous,
          amount: d.amount,
          method: d.method,
          date: d.date,
          caseRef: d.caseRef,
          note: d.note.trim(),
        ),
        ...state.donations,
      ],
    );
    _log(
      'au_donation_added',
      target: d.anonymous ? '—' : d.donor,
      details: '${d.amount} MRU ${d.caseRef}',
      sensitive: true,
    );
    return id;
  }

  String addExpense(Expense e) {
    _require(AdminPermission.manageFinance);
    if (e.amount <= 0) throw ArgumentError('amount');
    final id = _id('ex');
    state = state.copyWith(
      expenses: [
        Expense(
          id: id,
          category: e.category,
          amount: e.amount,
          caseRef: e.caseRef,
          date: e.date,
          note: e.note.trim(),
        ),
        ...state.expenses,
      ],
    );
    _log(
      'au_expense_added',
      target: e.caseRef,
      details: '${e.amount} MRU ${e.category.name}',
      sensitive: true,
    );
    return id;
  }

  // -------------------------------------------------------------------------
  // Communication and content
  // -------------------------------------------------------------------------

  void sendMessage({
    required MessageAudience audience,
    String targetId = '',
    String targetName = '',
    required String title,
    required String body,
  }) {
    final me = _require(AdminPermission.sendNotifications);
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw ArgumentError('empty');
    }
    if (audience == MessageAudience.user && targetId.isEmpty) {
      throw ArgumentError('target');
    }
    state = state.copyWith(
      messages: [
        AdminMessage(
          id: _id('msg'),
          audience: audience,
          targetId: targetId,
          targetName: targetName,
          title: title.trim(),
          body: body.trim(),
          at: DateTime.now(),
          by: me.name,
        ),
        ...state.messages,
      ],
    );
    _log(
      'au_message_sent',
      target: audience == MessageAudience.user ? targetName : audience.name,
      details: title.trim(),
    );
  }

  void addAnnouncement(String title, String body) {
    _require(AdminPermission.manageContent);
    state = state.copyWith(
      announcements: [
        Announcement(
          id: _id('an'),
          title: title.trim(),
          body: body.trim(),
          createdAt: DateTime.now(),
        ),
        ...state.announcements,
      ],
    );
    _log('au_announcement_added', target: title.trim());
  }

  void toggleAnnouncement(String id) {
    _require(AdminPermission.manageContent);
    final a = state.announcements.firstWhere((x) => x.id == id);
    state = state.copyWith(
      announcements: [
        for (final x in state.announcements)
          x.id == id ? x.copyWith(active: !x.active) : x,
      ],
    );
    _log(
      a.active ? 'au_announcement_hidden' : 'au_announcement_shown',
      target: a.title,
    );
  }

  void deleteAnnouncement(String id) {
    _require(AdminPermission.manageContent);
    final a = state.announcements.firstWhere((x) => x.id == id);
    state = state.copyWith(
      announcements: [
        for (final x in state.announcements)
          if (x.id != id) x,
      ],
    );
    _log('au_announcement_deleted', target: a.title);
  }

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  void setSection(AppSection s, bool enabled) {
    _require(AdminPermission.manageSettings);
    state = state.copyWith(
      settings: state.settings.copyWith(
        sections: {...state.settings.sections, s: enabled},
      ),
    );
    _log(enabled ? 'au_section_on' : 'au_section_off', target: s.name);
  }

  void setAssociationInfo(AssociationInfo info) {
    _require(AdminPermission.manageSettings);
    state = state.copyWith(settings: state.settings.copyWith(info: info));
    _log('au_info_updated', target: info.name);
  }

  void setLanguages({required String defaultLanguage, required bool french}) {
    _require(AdminPermission.manageSettings);
    state = state.copyWith(
      settings: state.settings.copyWith(
        defaultLanguage: french ? defaultLanguage : 'ar',
        frenchEnabled: french,
      ),
    );
    _log('au_languages_updated', details: '$defaultLanguage fr=$french');
  }

  // -------------------------------------------------------------------------
  // Backup and restore
  // -------------------------------------------------------------------------

  /// Full copy of the administration data (JSON). Passwords are stored as
  /// salted hashes only.
  String exportBackup() {
    _require(AdminPermission.manageBackups);
    final s = state;
    final json = {
      'format': 'shifa-linnas-admin-backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'admins': [for (final a in s.admins) a.toJson()],
      'audit': [for (final a in s.audit) a.toJson()],
      'donations': [for (final d in s.donations) d.toJson()],
      'expenses': [for (final e in s.expenses) e.toJson()],
      'services': [for (final r in s.services) r.toJson()],
      'agreements': {
        for (final e in s.agreements.entries) e.key: e.value.toJson(),
      },
      'caseDecisions': {
        for (final e in s.caseDecisions.entries) e.key: e.value.toJson(),
      },
      'evaluations': {
        for (final e in s.evaluations.entries) e.key: e.value.toJson(),
      },
      'messages': [for (final m in s.messages) m.toJson()],
      'announcements': [for (final a in s.announcements) a.toJson()],
      'settings': s.settings.toJson(),
      'suspendedAccounts': s.suspendedAccounts,
      'cardRenewals': {
        for (final e in s.cardRenewals.entries)
          e.key: e.value.toIso8601String(),
      },
    };
    _log('au_backup_created', sensitive: true);
    return const JsonEncoder.withIndent(' ').convert(json);
  }

  /// Replaces the administration data with a backup. The current admin must
  /// still exist and be active in it (otherwise refused).
  void restoreBackup(String text) {
    final me = _require(AdminPermission.manageBackups);
    final j = jsonDecode(text) as Map<String, dynamic>;
    if (j['format'] != 'shifa-linnas-admin-backup') {
      throw const FormatException('not a backup');
    }
    List<T> list<T>(String k, T Function(Map<String, dynamic>) f) => [
      for (final x in (j[k] as List? ?? const [])) f(x as Map<String, dynamic>),
    ];
    Map<String, T> map<T>(String k, T Function(Map<String, dynamic>) f) => {
      for (final e in ((j[k] as Map<String, dynamic>?) ?? const {}).entries)
        e.key: f(e.value as Map<String, dynamic>),
    };
    final admins = list('admins', AdminAccount.fromJson);
    if (!admins.any((a) => a.id == me.id && a.active)) {
      throw const FormatException('current admin missing from backup');
    }
    state = state.copyWith(
      admins: admins,
      audit: list('audit', AuditEntry.fromJson),
      donations: list('donations', Donation.fromJson),
      expenses: list('expenses', Expense.fromJson),
      services: list('services', ServiceRecord.fromJson),
      agreements: map('agreements', FacilityAgreement.fromJson),
      caseDecisions: map('caseDecisions', CaseDecision.fromJson),
      evaluations: map('evaluations', DoctorEvaluation.fromJson),
      messages: list('messages', AdminMessage.fromJson),
      announcements: list('announcements', Announcement.fromJson),
      settings: AppSettings.fromJson(j['settings'] as Map<String, dynamic>),
      suspendedAccounts:
          (j['suspendedAccounts'] as Map<String, dynamic>? ?? const {}).map(
            (k, v) => MapEntry(k, v as String),
          ),
      cardRenewals: (j['cardRenewals'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, DateTime.parse(v as String))),
    );
    _log(
      'au_backup_restored',
      details: j['createdAt'] as String? ?? '',
      sensitive: true,
    );
  }

  // -------------------------------------------------------------------------
  // Demo data
  // -------------------------------------------------------------------------

  static AdminState _seed() {
    AdminAccount admin(
      String id,
      String name,
      String email,
      String password,
      AdminRole role,
    ) => AdminAccount(
      id: id,
      name: name,
      email: email,
      salt: 'seed-$id',
      passwordHash: hashPassword('seed-$id', password),
      role: role,
      permissions: rolePermissions(role),
      createdAt: DateTime(2026, 9, 1),
    );
    final now = DateTime.now();
    DateTime ago(int days) => now.subtract(Duration(days: days));
    return AdminState(
      admins: [
        admin(
          'adm1',
          'المدير العام',
          'admin@shifa.mr',
          'Admin@2026',
          AdminRole.superAdmin,
        ),
        admin(
          'adm2',
          'مسؤول التسجيلات',
          'reg@shifa.mr',
          'Reg@2026!',
          AdminRole.registrations,
        ),
        admin(
          'adm3',
          'المنسق الطبي',
          'medical@shifa.mr',
          'Medical@2026',
          AdminRole.medical,
        ),
        admin(
          'adm4',
          'المسؤول المالي',
          'finance@shifa.mr',
          'Finance@2026',
          AdminRole.finance,
        ),
        admin(
          'adm5',
          'مسؤول التواصل',
          'comm@shifa.mr',
          'Comm@2026!',
          AdminRole.communications,
        ),
        admin(
          'adm6',
          'المدقق',
          'audit@shifa.mr',
          'Audit@2026',
          AdminRole.auditor,
        ),
        admin(
          'adm7',
          'عضو فريق المتابعة',
          'team@shifa.mr',
          'Team@2026!',
          AdminRole.followUp,
        ),
      ],
      donations: [
        Donation(
          id: 'dn1',
          donor: 'محسن من نواكشوط',
          amount: 150000,
          method: DonationMethod.bankily,
          date: ago(70),
        ),
        Donation(
          id: 'dn2',
          donor: 'مؤسسة البر',
          amount: 500000,
          method: DonationMethod.bank,
          date: ago(62),
          note: 'دعم العمليات الجراحية',
        ),
        Donation(
          id: 'dn3',
          donor: '',
          anonymous: true,
          amount: 20000,
          method: DonationMethod.masrvi,
          date: ago(45),
        ),
        Donation(
          id: 'dn4',
          donor: 'أحمد سالم',
          amount: 35000,
          method: DonationMethod.cash,
          date: ago(33),
          caseRef: 'c2',
        ),
        Donation(
          id: 'dn5',
          donor: 'جالية موريتانية بالخارج',
          amount: 250000,
          method: DonationMethod.bank,
          date: ago(21),
        ),
        Donation(
          id: 'dn6',
          donor: '',
          anonymous: true,
          amount: 10000,
          method: DonationMethod.sedad,
          date: ago(12),
        ),
        Donation(
          id: 'dn7',
          donor: 'فاطمة محمد',
          amount: 60000,
          method: DonationMethod.bankily,
          date: ago(6),
          caseRef: 'ref1',
        ),
        Donation(
          id: 'dn8',
          donor: 'متبرع',
          amount: 15000,
          method: DonationMethod.cash,
          date: ago(2),
        ),
      ],
      expenses: [
        Expense(
          id: 'ex1',
          category: ExpenseCategory.surgery,
          amount: 280000,
          caseRef: 'ref3',
          date: ago(50),
          note: 'عملية نظر',
        ),
        Expense(
          id: 'ex2',
          category: ExpenseCategory.medicine,
          amount: 18500,
          caseRef: 'c1',
          date: ago(30),
          note: 'أدوية السكري لثلاثة أشهر',
        ),
        Expense(
          id: 'ex3',
          category: ExpenseCategory.tests,
          amount: 12000,
          caseRef: 'c2',
          date: ago(25),
        ),
        Expense(
          id: 'ex4',
          category: ExpenseCategory.imaging,
          amount: 25000,
          caseRef: 'ref5',
          date: ago(9),
        ),
        Expense(
          id: 'ex5',
          category: ExpenseCategory.transport,
          amount: 8000,
          caseRef: 'ref1',
          date: ago(3),
          note: 'نقل المريضة إلى المستشفى',
        ),
      ],
      services: [
        ServiceRecord(
          id: 'sv1',
          facilityId: 'f1',
          service: 'فحص نظر',
          free: true,
          value: 15000,
          caseRef: 'ref3',
          date: ago(6),
        ),
        ServiceRecord(
          id: 'sv2',
          facilityId: 'f2',
          service: 'السكر التراكمي ووظائف الكلى',
          free: false,
          value: 12000,
          discount: 50,
          caseRef: 'ref4',
          date: ago(1),
        ),
        ServiceRecord(
          id: 'sv3',
          facilityId: 'f4',
          service: 'أشعة سينية لليد',
          free: true,
          value: 9000,
          caseRef: 'ref5',
          date: ago(4),
        ),
      ],
      agreements: {
        'f1': FacilityAgreement(
          DateTime(2026, 9, 12),
          DateTime(2027, 9, 11),
          'استشارات مجانية واستقبال 20 حالة شهرياً',
        ),
        'f2': FacilityAgreement(
          DateTime(2026, 10, 2),
          DateTime(2027, 4, 1),
          'تخفيض 50% على التحاليل',
        ),
        'f4': FacilityAgreement(
          DateTime(2026, 10, 28),
          DateTime(2026, 11, 30),
          'أشعة مجانية — تجريبي',
        ),
      },
      announcements: [
        Announcement(
          id: 'an1',
          title: 'حملة فحص السكري المجانية',
          body: 'يوم السبت القادم بالتعاون مع مختبر الشفاء: فحص مجاني لمرضى الجمعية.',
          createdAt: ago(1),
        ),
      ],
      messages: [
        AdminMessage(
          id: 'msg1',
          audience: MessageAudience.doctors,
          title: 'شكراً لأطبائنا المتطوعين',
          body: 'تجاوزنا 600 استشارة هذا الشهر بفضل جهودكم.',
          at: ago(4),
          by: 'المدير العام',
        ),
      ],
      audit: [
        AuditEntry(
          id: 'au0',
          at: ago(3),
          adminId: 'adm1',
          adminName: 'المدير العام',
          action: 'au_login',
          target: 'admin@shifa.mr',
        ),
      ],
    );
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(
  AdminNotifier.new,
);

/// Settings read by the whole app (sections on/off, association info...).
final appSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(adminProvider.select((s) => s.settings)),
);

/// Announcements shown on the home screen.
final activeAnnouncementsProvider = Provider<List<Announcement>>(
  (ref) => [
    for (final a in ref.watch(adminProvider.select((s) => s.announcements)))
      if (a.active) a,
  ],
);
