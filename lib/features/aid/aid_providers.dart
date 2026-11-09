import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/mock_data.dart';
import 'aid_models.dart';
import 'aid_repository.dart';

/// Supabase when configured, otherwise demo data tied to the app session
/// (the follow-up team login acts as committee supervisor in the demo).
final aidRepositoryProvider = Provider<AidRepository>((ref) {
  if (supabaseConfigured) return SupabaseAidRepository();
  final auth = ref.watch(authProvider);
  return DemoAidRepository(
    role: auth.isCommittee ? CommitteeRole.supervisor : null,
    userId: auth.isCommittee ? 'demo-supervisor' : MockData.currentPatientId,
  );
});

/// Bumped after sign in / sign out to re-read the session.
class AidSessionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void changed() => state++;
}

final aidSessionProvider = NotifierProvider<AidSessionNotifier, int>(
  AidSessionNotifier.new,
);

final aidRoleProvider = FutureProvider<CommitteeRole?>((ref) {
  ref.watch(aidSessionProvider);
  final repo = ref.watch(aidRepositoryProvider);
  if (!repo.signedIn) return null;
  return repo.myRole();
});

final aidMineProvider = StreamProvider<List<AidRequest>>((ref) {
  ref.watch(aidSessionProvider);
  return ref.watch(aidRepositoryProvider).watchMine();
});

final aidAllProvider = StreamProvider<List<AidRequest>>((ref) {
  ref.watch(aidSessionProvider);
  return ref.watch(aidRepositoryProvider).watchAll();
});

final aidMembersProvider = StreamProvider<List<CommitteeMember>>((ref) {
  ref.watch(aidSessionProvider);
  return ref.watch(aidRepositoryProvider).watchMembers();
});
