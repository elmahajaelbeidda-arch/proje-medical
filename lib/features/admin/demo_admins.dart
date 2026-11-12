import '../../models/admin.dart';

/// Demo staff accounts of the follow-up & management dashboard (one per
/// role). Only imported by the dashboard app, never by the users' app.
/// Replace with real accounts (stored on a server) before going live.
List<AdminAccount> demoAdmins() {
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
  return [
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
    admin('adm6', 'المدقق', 'audit@shifa.mr', 'Audit@2026', AdminRole.auditor),
    admin(
      'adm7',
      'عضو فريق المتابعة',
      'team@shifa.mr',
      'Team@2026!',
      AdminRole.followUp,
    ),
  ];
}
