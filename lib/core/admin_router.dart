import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_shell.dart';
import '../features/aid/aid_screens.dart';
import '../features/blood/committee_screens.dart';
import '../features/cards/member_card_screens.dart';
import '../features/facility/facility_screens.dart';
import '../models/admin.dart';
import 'admin_provider.dart';

/// Routes of the follow-up & management dashboard, a separate app for the
/// association's staff only (users never load it).
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/admin',
    onException: (_, _, router) => router.go('/admin'),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Public card check (used by reception desks): no sign-in.
      if (loc == '/verify-card') return null;
      final admin = ref.read(adminProvider);
      if (admin.me == null) return loc.startsWith('/admin') ? null : '/admin';
      if (loc == '/' || loc == '/committee') return '/admin/blood';
      // Each page needs the matching permission.
      final needed = loc.startsWith('/committee/request/')
          ? [AdminPermission.manageBlood]
          : loc.startsWith('/committee/facility/')
          ? [
              AdminPermission.manageFacilities,
              AdminPermission.manageRegistrations,
            ]
          : loc.startsWith('/committee/card/')
          ? [AdminPermission.manageCards, AdminPermission.manageRegistrations]
          : loc.startsWith('/aid/')
          ? [AdminPermission.viewCases]
          : const <AdminPermission>[];
      if (needed.isNotEmpty && !needed.any(admin.can)) return '/admin';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AdminGate()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminGate()),
      GoRoute(
        path: '/admin/:section',
        builder: (_, state) =>
            AdminGate(section: state.pathParameters['section']),
      ),
      GoRoute(
        path: '/committee',
        builder: (_, _) => const AdminGate(section: 'blood'),
      ),
      GoRoute(
        path: '/committee/request/:id',
        builder: (_, state) =>
            CommitteeRequestScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/committee/facility/:id',
        builder: (_, state) =>
            CommitteeFacilityScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/committee/card/:holder',
        builder: (_, state) => CommitteeMemberCardScreen(
          holderId: state.pathParameters['holder']!,
        ),
      ),
      GoRoute(path: '/aid/map', builder: (_, _) => const AidMapScreen()),
      GoRoute(
        path: '/aid/members',
        builder: (_, _) => const AidMembersScreen(),
      ),
      GoRoute(
        path: '/verify-card',
        builder: (_, state) => VerifyCardScreen(
          number: state.uri.queryParameters['n'],
          code: state.uri.queryParameters['c'],
        ),
      ),
    ],
  );
});
