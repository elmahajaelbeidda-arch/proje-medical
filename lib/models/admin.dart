/// Central administration of the association (admin dashboard): admin
/// accounts and permissions, audit log, donations and expenses, messages,
/// announcements and app settings.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

// ---------------------------------------------------------------------------
// Permissions
// ---------------------------------------------------------------------------

/// Each admin only gets what their job needs.
enum AdminPermission {
  manageRegistrations,
  suspendAccounts,
  manageCards,
  viewCases,
  viewMedicalRecords,
  manageCases,
  manageDoctors,
  manageFacilities,
  viewFinance,
  manageFinance,
  exportReports,
  sendNotifications,
  manageContent,
  manageSettings,
  viewAudit,
  manageBackups,
  manageAdmins,
}

enum AdminRole {
  superAdmin,
  registrations,
  medical,
  finance,
  communications,
  auditor,
  custom,
}

const _p = AdminPermission.values;

/// Default permissions of each role (a custom role picks them one by one).
Set<AdminPermission> rolePermissions(AdminRole role) => switch (role) {
  AdminRole.superAdmin => _p.toSet(),
  AdminRole.registrations => {
    AdminPermission.manageRegistrations,
    AdminPermission.suspendAccounts,
    AdminPermission.manageCards,
    AdminPermission.manageDoctors,
    AdminPermission.manageFacilities,
  },
  AdminRole.medical => {
    AdminPermission.viewCases,
    AdminPermission.viewMedicalRecords,
    AdminPermission.manageCases,
    AdminPermission.manageDoctors,
    AdminPermission.manageFacilities,
    AdminPermission.sendNotifications,
  },
  AdminRole.finance => {
    AdminPermission.viewCases,
    AdminPermission.viewFinance,
    AdminPermission.manageFinance,
    AdminPermission.exportReports,
  },
  AdminRole.communications => {
    AdminPermission.sendNotifications,
    AdminPermission.manageContent,
  },
  AdminRole.auditor => {
    AdminPermission.viewCases,
    AdminPermission.viewFinance,
    AdminPermission.exportReports,
    AdminPermission.viewAudit,
  },
  AdminRole.custom => const {},
};

class AdminPermissionDenied implements Exception {
  final AdminPermission permission;
  const AdminPermissionDenied(this.permission);
  @override
  String toString() => 'AdminPermissionDenied(${permission.name})';
}

// ---------------------------------------------------------------------------
// Admin accounts
// ---------------------------------------------------------------------------

String hashPassword(String salt, String password) =>
    sha256.convert(utf8.encode('$salt::$password')).toString();

class AdminAccount {
  final String id;
  final String name;
  final String email;
  final String salt;
  final String passwordHash;
  final AdminRole role;
  final Set<AdminPermission> permissions;
  final bool active;

  /// Authenticator app secret (null: demo code until set up).
  final String? totpSecret;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.active = true,
    this.totpSecret,
    this.lastLoginAt,
  });

  bool can(AdminPermission p) => active && permissions.contains(p);

  bool checkPassword(String password) =>
      hashPassword(salt, password) == passwordHash;

  AdminAccount copyWith({
    String? name,
    AdminRole? role,
    Set<AdminPermission>? permissions,
    bool? active,
    String? totpSecret,
    bool clearTotp = false,
    String? salt,
    String? passwordHash,
    DateTime? lastLoginAt,
  }) => AdminAccount(
    id: id,
    name: name ?? this.name,
    email: email,
    salt: salt ?? this.salt,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    permissions: permissions ?? this.permissions,
    active: active ?? this.active,
    totpSecret: clearTotp ? null : (totpSecret ?? this.totpSecret),
    createdAt: createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
    'role': role.name,
    'permissions': [for (final p in permissions) p.name],
    'active': active,
    'totpSecret': totpSecret,
    'createdAt': createdAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  factory AdminAccount.fromJson(Map<String, dynamic> j) => AdminAccount(
    id: j['id'] as String,
    name: j['name'] as String,
    email: j['email'] as String,
    salt: j['salt'] as String,
    passwordHash: j['passwordHash'] as String,
    role: AdminRole.values.byName(j['role'] as String),
    permissions: {
      for (final p in (j['permissions'] as List).cast<String>())
        AdminPermission.values.byName(p),
    },
    active: j['active'] as bool? ?? true,
    totpSecret: j['totpSecret'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    lastLoginAt: j['lastLoginAt'] == null
        ? null
        : DateTime.parse(j['lastLoginAt'] as String),
  );
}

// ---------------------------------------------------------------------------
// Audit log (append only)
// ---------------------------------------------------------------------------

class AuditEntry {
  final String id;
  final DateTime at;
  final String adminId;
  final String adminName;

  /// Translation key of the action, e.g. 'au_approve'.
  final String action;
  final String target;
  final String details;

  /// Access to medical or financial data.
  final bool sensitive;

  const AuditEntry({
    required this.id,
    required this.at,
    required this.adminId,
    required this.adminName,
    required this.action,
    this.target = '',
    this.details = '',
    this.sensitive = false,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toIso8601String(),
    'adminId': adminId,
    'adminName': adminName,
    'action': action,
    'target': target,
    'details': details,
    'sensitive': sensitive,
  };

  factory AuditEntry.fromJson(Map<String, dynamic> j) => AuditEntry(
    id: j['id'] as String,
    at: DateTime.parse(j['at'] as String),
    adminId: j['adminId'] as String,
    adminName: j['adminName'] as String,
    action: j['action'] as String,
    target: j['target'] as String? ?? '',
    details: j['details'] as String? ?? '',
    sensitive: j['sensitive'] as bool? ?? false,
  );
}

// ---------------------------------------------------------------------------
// Donations and expenses (amounts in MRU, new ouguiya)
// ---------------------------------------------------------------------------

enum DonationMethod { cash, bank, bankily, masrvi, sedad, other }

class Donation {
  final String id;
  final String donor;
  final bool anonymous;
  final int amount;
  final DonationMethod method;
  final DateTime date;

  /// Case it is given for ('' = general fund).
  final String caseRef;
  final String note;

  const Donation({
    required this.id,
    required this.donor,
    required this.amount,
    required this.method,
    required this.date,
    this.anonymous = false,
    this.caseRef = '',
    this.note = '',
  });

  String get receiptNo =>
      'RC-${date.year}-${id.replaceAll(RegExp(r'\D'), '').padLeft(4, '0').substring(0, 4)}';

  Map<String, Object?> toJson() => {
    'id': id,
    'donor': donor,
    'anonymous': anonymous,
    'amount': amount,
    'method': method.name,
    'date': date.toIso8601String(),
    'caseRef': caseRef,
    'note': note,
  };

  factory Donation.fromJson(Map<String, dynamic> j) => Donation(
    id: j['id'] as String,
    donor: j['donor'] as String,
    anonymous: j['anonymous'] as bool? ?? false,
    amount: j['amount'] as int,
    method: DonationMethod.values.byName(j['method'] as String),
    date: DateTime.parse(j['date'] as String),
    caseRef: j['caseRef'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );
}

enum ExpenseCategory { medicine, tests, imaging, surgery, transport, other }

/// Money spent or aid given to a case.
class Expense {
  final String id;
  final ExpenseCategory category;
  final int amount;
  final String caseRef;
  final DateTime date;
  final String note;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.caseRef = '',
    this.note = '',
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'category': category.name,
    'amount': amount,
    'caseRef': caseRef,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    category: ExpenseCategory.values.byName(j['category'] as String),
    amount: j['amount'] as int,
    caseRef: j['caseRef'] as String? ?? '',
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String? ?? '',
  );
}

// ---------------------------------------------------------------------------
// Facilities: agreements and documented services
// ---------------------------------------------------------------------------

class FacilityAgreement {
  final DateTime start;
  final DateTime end;
  final String terms;
  const FacilityAgreement(this.start, this.end, this.terms);

  bool isActive([DateTime? now]) {
    final t = now ?? DateTime.now();
    return !t.isBefore(start) && !t.isAfter(end);
  }

  Map<String, Object?> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'terms': terms,
  };

  factory FacilityAgreement.fromJson(Map<String, dynamic> j) =>
      FacilityAgreement(
        DateTime.parse(j['start'] as String),
        DateTime.parse(j['end'] as String),
        j['terms'] as String? ?? '',
      );
}

/// A free or discounted service a facility gave to a patient.
class ServiceRecord {
  final String id;
  final String facilityId;
  final String service;
  final bool free;

  /// Normal price of the service (MRU).
  final int value;

  /// Discount in % when not free.
  final int discount;
  final String caseRef;
  final DateTime date;

  const ServiceRecord({
    required this.id,
    required this.facilityId,
    required this.service,
    required this.free,
    required this.value,
    required this.date,
    this.discount = 0,
    this.caseRef = '',
  });

  /// What the patient did not have to pay.
  int get saved => free ? value : (value * discount / 100).round();

  Map<String, Object?> toJson() => {
    'id': id,
    'facilityId': facilityId,
    'service': service,
    'free': free,
    'value': value,
    'discount': discount,
    'caseRef': caseRef,
    'date': date.toIso8601String(),
  };

  factory ServiceRecord.fromJson(Map<String, dynamic> j) => ServiceRecord(
    id: j['id'] as String,
    facilityId: j['facilityId'] as String,
    service: j['service'] as String,
    free: j['free'] as bool,
    value: j['value'] as int,
    discount: j['discount'] as int? ?? 0,
    caseRef: j['caseRef'] as String? ?? '',
    date: DateTime.parse(j['date'] as String),
  );
}

// ---------------------------------------------------------------------------
// Cases: decisions of the administration
// ---------------------------------------------------------------------------

enum CaseStage { pending, accepted, onHold, rejected, completed }

class CaseDecision {
  final CaseStage stage;
  final String note;
  final DateTime at;
  final String by;
  const CaseDecision(this.stage, this.note, this.at, this.by);

  Map<String, Object?> toJson() => {
    'stage': stage.name,
    'note': note,
    'at': at.toIso8601String(),
    'by': by,
  };

  factory CaseDecision.fromJson(Map<String, dynamic> j) => CaseDecision(
    CaseStage.values.byName(j['stage'] as String),
    j['note'] as String? ?? '',
    DateTime.parse(j['at'] as String),
    j['by'] as String? ?? '',
  );
}

class DoctorEvaluation {
  final int score; // 1..5
  final String note;
  final DateTime at;
  const DoctorEvaluation(this.score, this.note, this.at);

  Map<String, Object?> toJson() => {
    'score': score,
    'note': note,
    'at': at.toIso8601String(),
  };

  factory DoctorEvaluation.fromJson(Map<String, dynamic> j) => DoctorEvaluation(
    j['score'] as int,
    j['note'] as String? ?? '',
    DateTime.parse(j['at'] as String),
  );
}

// ---------------------------------------------------------------------------
// Communication
// ---------------------------------------------------------------------------

enum MessageAudience { all, patients, doctors, facilities, user }

class AdminMessage {
  final String id;
  final MessageAudience audience;

  /// Registration / facility id when [audience] is `user`.
  final String targetId;
  final String targetName;
  final String title;
  final String body;
  final DateTime at;
  final String by;

  const AdminMessage({
    required this.id,
    required this.audience,
    required this.title,
    required this.body,
    required this.at,
    required this.by,
    this.targetId = '',
    this.targetName = '',
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'audience': audience.name,
    'targetId': targetId,
    'targetName': targetName,
    'title': title,
    'body': body,
    'at': at.toIso8601String(),
    'by': by,
  };

  factory AdminMessage.fromJson(Map<String, dynamic> j) => AdminMessage(
    id: j['id'] as String,
    audience: MessageAudience.values.byName(j['audience'] as String),
    targetId: j['targetId'] as String? ?? '',
    targetName: j['targetName'] as String? ?? '',
    title: j['title'] as String,
    body: j['body'] as String,
    at: DateTime.parse(j['at'] as String),
    by: j['by'] as String? ?? '',
  );
}

/// Banner shown on the home screen of the app.
class Announcement {
  final String id;
  final String title;
  final String body;
  final bool active;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.active = true,
  });

  Announcement copyWith({bool? active}) => Announcement(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    active: active ?? this.active,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id'] as String,
    title: j['title'] as String,
    body: j['body'] as String,
    active: j['active'] as bool? ?? true,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

// ---------------------------------------------------------------------------
// App settings
// ---------------------------------------------------------------------------

/// Sections the administration can switch on or off.
enum AppSection { consultations, psych, blood, aid, facilities, summons }

class AssociationInfo {
  final String name;
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String donationNumber;

  const AssociationInfo({
    this.name = 'جمعية عون وسند الخيرية',
    this.phone = '32203250',
    this.whatsapp = '32203250',
    this.email = 'contact@aoun-sanad.mr',
    this.address = 'نواكشوط، موريتانيا',
    this.donationNumber = '32203250',
  });

  Map<String, Object?> toJson() => {
    'name': name,
    'phone': phone,
    'whatsapp': whatsapp,
    'email': email,
    'address': address,
    'donationNumber': donationNumber,
  };

  factory AssociationInfo.fromJson(Map<String, dynamic> j) => AssociationInfo(
    name: j['name'] as String,
    phone: j['phone'] as String,
    whatsapp: j['whatsapp'] as String,
    email: j['email'] as String,
    address: j['address'] as String,
    donationNumber: j['donationNumber'] as String,
  );
}

class AppSettings {
  final Map<AppSection, bool> sections;
  final AssociationInfo info;

  /// 'ar' or 'fr' for new users.
  final String defaultLanguage;

  /// French interface available.
  final bool frenchEnabled;

  const AppSettings({
    this.sections = const {},
    this.info = const AssociationInfo(),
    this.defaultLanguage = 'ar',
    this.frenchEnabled = true,
  });

  bool enabled(AppSection s) => sections[s] ?? true;

  AppSettings copyWith({
    Map<AppSection, bool>? sections,
    AssociationInfo? info,
    String? defaultLanguage,
    bool? frenchEnabled,
  }) => AppSettings(
    sections: sections ?? this.sections,
    info: info ?? this.info,
    defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    frenchEnabled: frenchEnabled ?? this.frenchEnabled,
  );

  Map<String, Object?> toJson() => {
    'sections': {for (final e in sections.entries) e.key.name: e.value},
    'info': info.toJson(),
    'defaultLanguage': defaultLanguage,
    'frenchEnabled': frenchEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    sections: {
      for (final e in (j['sections'] as Map<String, dynamic>).entries)
        AppSection.values.byName(e.key): e.value as bool,
    },
    info: AssociationInfo.fromJson(j['info'] as Map<String, dynamic>),
    defaultLanguage: j['defaultLanguage'] as String? ?? 'ar',
    frenchEnabled: j['frenchEnabled'] as bool? ?? true,
  );
}
