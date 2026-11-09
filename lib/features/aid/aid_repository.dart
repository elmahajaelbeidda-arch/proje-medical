import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'aid_models.dart';

/// Supabase project, given at build time:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
/// Without them the feature runs on demo data (nothing leaves the device).
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

abstract class AidRepository {
  bool get isDemo;

  /// Supabase needs a signed-in account; the demo uses the app's session.
  bool get signedIn;
  String? get currentUserId;
  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();

  /// Committee role of the signed-in user, null for a patient.
  Future<CommitteeRole?> myRole();

  Stream<List<AidRequest>> watchMine();
  Stream<List<AidRequest>> watchAll();
  Future<String> submit(AidRequestDraft draft);
  Future<void> setStatus(String id, AidStatus status);
  Future<void> delete(String id);

  Stream<List<CommitteeMember>> watchMembers();
  Future<void> addMember(String userId, String name, CommitteeRole role);
  Future<void> removeMember(String userId);
}

// ---------------------------------------------------------------------------
// Supabase
// ---------------------------------------------------------------------------

class SupabaseAidRepository implements AidRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  bool get isDemo => false;
  @override
  bool get signedIn => _db.auth.currentSession != null;
  @override
  String? get currentUserId => _db.auth.currentUser?.id;

  @override
  Future<void> signIn(String email, String password) =>
      _db.auth.signInWithPassword(email: email.trim(), password: password);

  @override
  Future<void> signUp(String email, String password) =>
      _db.auth.signUp(email: email.trim(), password: password);

  @override
  Future<void> signOut() => _db.auth.signOut();

  @override
  Future<CommitteeRole?> myRole() async {
    final role = await _db.rpc('my_committee_role');
    return switch (role) {
      'supervisor' => CommitteeRole.supervisor,
      'member' => CommitteeRole.member,
      _ => null,
    };
  }

  // Realtime streams (RLS decides which rows each user receives).
  @override
  Stream<List<AidRequest>> watchMine() => _db
      .from('patients_requests')
      .stream(primaryKey: ['id'])
      .eq('user_id', currentUserId ?? '')
      .order('created_at')
      .map((rows) => rows.map(AidRequest.fromMap).toList().reversed.toList());

  @override
  Stream<List<AidRequest>> watchAll() => _db
      .from('patients_requests')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((rows) => rows.map(AidRequest.fromMap).toList().reversed.toList());

  @override
  Future<String> submit(AidRequestDraft draft) async {
    final row = await _db
        .from('patients_requests')
        .insert(draft.toInsertMap())
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<void> setStatus(String id, AidStatus status) =>
      _db.from('patients_requests').update({'status': status.db}).eq('id', id);

  @override
  Future<void> delete(String id) =>
      _db.from('patients_requests').delete().eq('id', id);

  @override
  Stream<List<CommitteeMember>> watchMembers() => _db
      .from('committee_members')
      .stream(primaryKey: ['user_id'])
      .map((rows) => rows.map(CommitteeMember.fromMap).toList());

  @override
  Future<void> addMember(String userId, String name, CommitteeRole role) =>
      _db.from('committee_members').upsert({
        'user_id': userId.trim(),
        'name': name.trim(),
        'role': role.name,
      });

  @override
  Future<void> removeMember(String userId) =>
      _db.from('committee_members').delete().eq('user_id', userId);
}

// ---------------------------------------------------------------------------
// Demo (no backend): sample requests around Nouakchott
// ---------------------------------------------------------------------------

class DemoAidRepository implements AidRepository {
  DemoAidRepository({required this.role, required this.userId}) {
    _emit();
  }

  /// Committee role given by the app session (team login = supervisor).
  final CommitteeRole? role;
  final String userId;

  static final List<AidRequest> _requests = _seed();
  static final List<CommitteeMember> _members = [
    const CommitteeMember(
      userId: 'demo-supervisor',
      name: 'رئيس اللجنة',
      role: CommitteeRole.supervisor,
    ),
    const CommitteeMember(
      userId: 'demo-member-1',
      name: 'أحمد سالم',
      role: CommitteeRole.member,
    ),
  ];
  static final _requestsCtrl = StreamController<List<AidRequest>>.broadcast();
  static final _membersCtrl =
      StreamController<List<CommitteeMember>>.broadcast();

  static void _emit() {
    _requestsCtrl.add(List.unmodifiable(_requests));
    _membersCtrl.add(List.unmodifiable(_members));
  }

  @override
  bool get isDemo => true;
  @override
  bool get signedIn => true;
  @override
  String? get currentUserId => userId;
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signUp(String email, String password) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<CommitteeRole?> myRole() async => role;

  Stream<List<AidRequest>> _watch(bool Function(AidRequest) where) async* {
    yield _requests.where(where).toList();
    yield* _requestsCtrl.stream.map((l) => l.where(where).toList());
  }

  @override
  Stream<List<AidRequest>> watchMine() => _watch((r) => r.userId == userId);
  @override
  Stream<List<AidRequest>> watchAll() =>
      role == null ? _watch((r) => r.userId == userId) : _watch((_) => true);

  @override
  Future<String> submit(AidRequestDraft d) async {
    if (!d.consentGiven) throw StateError('consent required');
    final id = 'aid-${DateTime.now().millisecondsSinceEpoch}';
    _requests.insert(
      0,
      AidRequest(
        id: id,
        userId: userId,
        patientName: d.patientName.trim(),
        phone: d.phone.trim(),
        latitude: d.latitude,
        longitude: d.longitude,
        addressNote: d.addressNote.trim(),
        conditionDescription: d.conditionDescription.trim(),
        urgency: d.urgency,
        consentGiven: true,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
    return id;
  }

  @override
  Future<void> setStatus(String id, AidStatus status) async {
    if (role == null) throw StateError('committee only');
    final i = _requests.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final closing =
        status == AidStatus.closed || _requests[i].status == AidStatus.closed;
    if (closing && role != CommitteeRole.supervisor) {
      throw StateError('supervisor only');
    }
    _requests[i] = _requests[i].copyWith(status: status, verifiedBy: userId);
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    if (role != CommitteeRole.supervisor) throw StateError('supervisor only');
    _requests.removeWhere((r) => r.id == id);
    _emit();
  }

  @override
  Stream<List<CommitteeMember>> watchMembers() async* {
    yield List.of(_members);
    yield* _membersCtrl.stream;
  }

  @override
  Future<void> addMember(String userId, String name, CommitteeRole role) async {
    if (this.role != CommitteeRole.supervisor) {
      throw StateError('supervisor only');
    }
    _members.removeWhere((m) => m.userId == userId.trim());
    _members.add(
      CommitteeMember(userId: userId.trim(), name: name.trim(), role: role),
    );
    _emit();
  }

  @override
  Future<void> removeMember(String userId) async {
    if (role != CommitteeRole.supervisor) throw StateError('supervisor only');
    _members.removeWhere((m) => m.userId == userId);
    _emit();
  }

  static List<AidRequest> _seed() {
    final now = DateTime.now();
    AidRequest r(
      String id,
      String name,
      double lat,
      double lng,
      String cond,
      AidUrgency u,
      AidStatus s,
      String note,
      int hoursAgo, {
      String user = 'demo-patient-x',
    }) => AidRequest(
      id: id,
      userId: user,
      patientName: name,
      phone: '22 ${id.hashCode.abs() % 90 + 10} 45 67',
      latitude: lat,
      longitude: lng,
      addressNote: note,
      conditionDescription: cond,
      urgency: u,
      status: s,
      createdAt: now.subtract(Duration(hours: hoursAgo)),
    );
    return [
      r(
        'aid-1',
        'خديجة محمد',
        18.0921,
        -15.9745,
        'مسنة مقعدة تحتاج زيارة طبيب وأدوية الضغط',
        AidUrgency.urgent,
        AidStatus.newRequest,
        'تفرغ زينة، قرب مسجد...',
        2,
      ),
      r(
        'aid-2',
        'سيدي أحمد',
        18.1157,
        -15.9572,
        'طفل يعاني من حمى متكررة منذ أسبوع',
        AidUrgency.medium,
        AidStatus.verifying,
        'دار النعيم، الحي الثالث',
        6,
      ),
      r(
        'aid-3',
        'مريم عبد الله',
        18.0455,
        -15.9531,
        'مريضة سكري تحتاج أنسولين',
        AidUrgency.urgent,
        AidStatus.verified,
        'الميناء، قرب السوق',
        20,
      ),
      r(
        'aid-4',
        'محمد الأمين',
        18.0634,
        -15.9351,
        'حاجة إلى نظارة طبية وفحص نظر',
        AidUrgency.normal,
        AidStatus.helped,
        'لكصر',
        48,
        user: 'p1',
      ),
      r(
        'aid-5',
        'فاطمة سالم',
        18.1032,
        -15.9988,
        'امرأة حامل بدون متابعة طبية',
        AidUrgency.medium,
        AidStatus.newRequest,
        'السبخة',
        9,
      ),
      r(
        'aid-6',
        'عبد الرحمن',
        18.0258,
        -15.9724,
        'كسر في اليد يحتاج جبيرة',
        AidUrgency.normal,
        AidStatus.closed,
        'الرياض',
        96,
      ),
    ];
  }
}
