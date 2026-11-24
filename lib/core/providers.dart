import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/registration.dart';
import 'accounts_remote.dart';
import 'consultations_remote.dart';
import 'admin_provider.dart';

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class LocaleNotifier extends Notifier<Locale> {
  /// Default language set by the administration (French and English can
  /// be switched off; Arabic is always offered).
  @override
  Locale build() {
    final settings = ref.watch(appSettingsProvider);
    final lang = settings.defaultLanguage;
    return Locale(settings.languages.contains(lang) ? lang : 'ar');
  }

  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  /// Light by default; dark or automatic (phone setting) from the settings.
  ThemeMode build() => ThemeMode.light;
  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ---------------------------------------------------------------------------
// Auth (mock)
// ---------------------------------------------------------------------------

class AuthState {
  final UserRole role;
  final bool loggedIn;
  final String name;
  final String phone;

  /// National ID card number (verified with the SMS code at sign-up).
  final String idNumber;
  final bool phoneVerified;

  /// Registration sent to the committee at sign-up (null for the demo
  /// accounts, which are already approved).
  final String? registrationId;

  /// Doctor's specialty chosen at sign-up (null: the demo doctor's).
  final String? specialtyId;
  const AuthState({
    this.role = UserRole.patient,
    this.loggedIn = false,
    this.name = '',
    this.phone = '',
    this.idNumber = '',
    this.phoneVerified = false,
    this.registrationId,
    this.specialtyId,
  });

  /// Volunteer psychiatrists get their own confidential workspace.
  bool get isPsychDoctor => isDoctor && specialtyId == 'psych';

  /// Doctor account behind this session (demo data).
  String get doctorId {
    // A real (server) doctor account is known by its own id.
    if (AccountsRemote.enabled && isDoctor && registrationId != null) {
      return registrationId!;
    }
    return isPsychDoctor ? MockData.psychDoctorId : MockData.currentDoctorId;
  }

  /// e.g. "•••• 4821"
  String get maskedId => idNumber.length <= 4
      ? idNumber
      : '•••• ${idNumber.substring(idNumber.length - 4)}';

  bool get isDoctor => role == UserRole.doctor;
  bool get isCommittee => role == UserRole.committee;

  /// Name shown in the UI (falls back to the demo user's name).
  String get displayName {
    if (name.isNotEmpty) return name;
    if (isCommittee) return 'فريق المتابعة والإدارة';
    return isDoctor
        ? (MockData.doctorById(doctorId)?.name ?? '')
        : 'محمد الأمين';
  }

  String get userId => isDoctor ? doctorId : MockData.currentPatientId;
}

/// Who is signed in, for the parts of the app linked to the server: the
/// account's id there (else the demo ids). Kept up to date by AuthNotifier.
abstract final class CurrentAccount {
  static String patientId = MockData.currentPatientId;
  static String doctorId = MockData.currentDoctorId;

  /// The signed-in doctor (a server account has no demo profile).
  static Doctor doctor = MockData.demoDoctor;

  static void update(AuthState a) {
    final serverId = AccountsRemote.enabled ? a.registrationId : null;
    patientId = serverId ?? MockData.currentPatientId;
    doctorId = serverId ?? a.doctorId;
    doctor = serverId == null || !a.isDoctor
        ? (MockData.doctorById(a.doctorId) ?? MockData.demoDoctor)
        : Doctor(
            id: serverId,
            name: a.name,
            specialtyId: a.specialtyId ?? 'general',
            yearsOfExperience: 0,
            rating: 0,
            consultationsCount: 0,
            city: '',
            cityFr: '',
            bio: '',
          );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    listenSelf((_, next) => CurrentAccount.update(next));
    return const AuthState();
  }

  void selectRole(UserRole role) =>
      state = AuthState(role: role, name: state.name);

  /// Sign-up step 1: data entered, waiting for the SMS code.
  void register({
    required String name,
    required String phone,
    required String idNumber,
    String? registrationId,
    String? specialtyId,
  }) {
    state = AuthState(
      role: state.role,
      name: name.trim(),
      phone: phone.trim(),
      idNumber: idNumber.trim(),
      registrationId: registrationId,
      specialtyId: specialtyId,
    );
  }

  /// Sign-up step 2: SMS code verified.
  void verifyPhone() => state = AuthState(
    role: state.role,
    loggedIn: true,
    name: state.name,
    phone: state.phone,
    idNumber: state.idNumber,
    phoneVerified: true,
    registrationId: state.registrationId,
    specialtyId: state.specialtyId,
  );

  /// [specialtyId] 'psych' opens the demo psychiatrist account.
  void login({String? name, String? specialtyId}) {
    final sp = state.isDoctor ? specialtyId : null;
    final defaultName = state.isCommittee
        ? 'فريق المتابعة والإدارة'
        : state.isDoctor
        ? MockData.doctorById(
            sp == 'psych' ? MockData.psychDoctorId : MockData.currentDoctorId,
          )!.name
        : 'محمد الأمين';
    state = AuthState(
      role: state.role,
      specialtyId: sp,
      loggedIn: true,
      name: (name == null || name.trim().isEmpty) ? defaultName : name.trim(),
      // Demo account: already verified at sign-up.
      phone: '22 12 34 56',
      idNumber: MockData.demoIdNumber,
      phoneVerified: true,
    );
  }

  /// Signs in the account found by the one sign-in form.
  void loginAs({
    required UserRole role,
    required String name,
    String phone = '',
    String idNumber = '',
    String? registrationId,
    String? specialtyId,
  }) => state = AuthState(
    role: role,
    loggedIn: true,
    name: name,
    phone: phone,
    idNumber: idNumber,
    phoneVerified: true,
    registrationId: registrationId,
    specialtyId: role == UserRole.doctor ? specialtyId : null,
  );

  void logout() {
    state = const AuthState();
    if (AccountsRemote.enabled) const AccountsRemote().signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ---------------------------------------------------------------------------
// Doctor availability
// ---------------------------------------------------------------------------

class AvailabilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

final doctorAvailableProvider = NotifierProvider<AvailabilityNotifier, bool>(
  AvailabilityNotifier.new,
);

// ---------------------------------------------------------------------------
// Health profile
// ---------------------------------------------------------------------------

class HealthProfileNotifier extends Notifier<HealthProfile> {
  @override
  HealthProfile build() => AccountsRemote.enabled
      // Real accounts start empty: the patient fills their health profile.
      ? const HealthProfile(
          age: 0,
          male: true,
          bloodType: '',
          chronicDiseases: {},
          allergies: '',
          medications: '',
        )
      : const HealthProfile(
          age: 54,
          male: true,
          bloodType: 'O+',
          chronicDiseases: {'cd_diabetes'},
          allergies: '',
          medications: 'Metformin 850mg',
        );

  void update(HealthProfile profile) => state = profile;
}

final healthProfileProvider =
    NotifierProvider<HealthProfileNotifier, HealthProfile>(
      HealthProfileNotifier.new,
    );

// ---------------------------------------------------------------------------
// Consultations (in-memory repository)
// ---------------------------------------------------------------------------

class ConsultationsNotifier extends Notifier<List<Consultation>> {
  /// Server mode: the list comes from the server, live.
  bool get _remote =>
      ConsultationsRemote.enabled &&
      ref.read(authProvider).registrationId != null;

  @override
  List<Consultation> build() {
    if (!ConsultationsRemote.enabled) return MockData.consultations();
    final account = ref.watch(
      authProvider.select((a) => a.loggedIn ? a.registrationId : null),
    );
    // The dashboard team sees every consultation (server rules).
    final team = ref.watch(
      adminProvider.select((s) => s.remote && s.me != null),
    );
    if (account == null && !team) return const [];
    final sub = const ConsultationsRemote().watch().listen(
      (list) => state = list,
      onError: (_) {},
    );
    ref.onDispose(sub.cancel);
    // The person's own account (e.g. approved by the team meanwhile) is
    // read again now and then, without signing out and in.
    if (account != null) {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) async {
        final p = await const AccountsRemote().current();
        if (p != null && ref.mounted) {
          ref.read(registrationsProvider.notifier).upsert(p.toRegistration());
        }
      });
      ref.onDispose(timer.cancel);
    }
    return const [];
  }

  /// Runs a change on the server; on failure the list is put back.
  void _push(Future<void> Function() action, List<Consultation> before) {
    action().catchError((Object _) {
      if (ref.mounted) state = before;
    });
  }

  Consultation? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  String create({
    required String specialtyId,
    required ConsultationType type,
    required Urgency urgency,
    required String symptoms,
    required String durationKey,
    required List<Attachment> attachments,
    VoiceNote? voiceNote,
    required bool hideName,
    required String patientName,
    required HealthProfile profile,
  }) {
    final remote = _remote;
    final id = remote ? newUuid() : 'c${DateTime.now().millisecondsSinceEpoch}';
    final before = state;
    state = [
      Consultation(
        id: id,
        patientId: CurrentAccount.patientId,
        patientName: patientName,
        patientAge: profile.age,
        patientMale: profile.male,
        chronicDiseases: profile.chronicDiseases.toList(),
        hideName: hideName,
        specialtyId: specialtyId,
        type: type,
        urgency: urgency,
        symptoms: symptoms,
        durationKey: durationKey,
        attachments: attachments,
        voiceNote: voiceNote,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    if (remote) {
      final c = state.first;
      _push(() => const ConsultationsRemote().create(c), before);
    }
    return id;
  }

  void _update(String id, Consultation Function(Consultation c) change) {
    state = [for (final c in state) c.id == id ? change(c) : c];
  }

  void accept(String id, String doctorId) {
    final before = state;
    _update(
      id,
      (c) => c.copyWith(
        status: ConsultationStatus.accepted,
        doctorId: doctorId,
        doctorName: ref.read(authProvider).displayName,
      ),
    );
    if (_remote) _push(() => const ConsultationsRemote().accept(id), before);
  }

  /// A doctor acts on a new case (message, voice, call): the case becomes
  /// theirs first, so there is no separate «accept» step to remember.
  Future<bool> ensureMine(String id) async {
    final c = byId(id);
    if (c == null) return false;
    final me = CurrentAccount.doctorId;
    if (c.doctorId == me) return true;
    if (c.doctorId != null || c.status != ConsultationStatus.pending) {
      return false;
    }
    final before = state;
    _update(
      id,
      (x) => x.copyWith(
        status: ConsultationStatus.accepted,
        doctorId: me,
        doctorName: ref.read(authProvider).displayName,
      ),
    );
    if (!_remote) return true;
    try {
      await const ConsultationsRemote().accept(id);
      return true;
    } catch (_) {
      if (ref.mounted) state = before;
      return false;
    }
  }

  void reply(String id, DoctorReply reply) {
    final before = state;
    _update(
      id,
      (c) => c.copyWith(status: ConsultationStatus.answered, reply: reply),
    );
    if (_remote) {
      _push(() => const ConsultationsRemote().reply(id, reply), before);
    }
  }

  void sendMessage(String id, ChatMessage message) {
    final before = state;
    _update(id, (c) => c.copyWith(messages: [...c.messages, message]));
    if (_remote) {
      _push(() => const ConsultationsRemote().sendMessage(id, message), before);
    }
  }

  void rate(String id, int rating) {
    final before = state;
    _update(id, (c) => c.copyWith(rating: rating));
    if (_remote) {
      _push(() => const ConsultationsRemote().rate(id, rating), before);
    }
  }
}

/// Doctor of a consultation: a demo profile, or (server accounts) a short
/// profile made from the name saved when the doctor accepted the case.
Doctor? consultationDoctor(Consultation c) {
  final demo = MockData.doctorById(c.doctorId);
  if (demo != null || c.doctorId == null) return demo;
  return Doctor(
    id: c.doctorId!,
    name: c.doctorName ?? '',
    specialtyId: c.specialtyId,
    yearsOfExperience: 0,
    rating: 0,
    consultationsCount: 0,
    city: '',
    cityFr: '',
    bio: '',
  );
}

final consultationsProvider =
    NotifierProvider<ConsultationsNotifier, List<Consultation>>(
      ConsultationsNotifier.new,
    );

final consultationProvider = Provider.family<Consultation?, String>((ref, id) {
  final list = ref.watch(consultationsProvider);
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Account registrations (reviewed by the committee)
// ---------------------------------------------------------------------------

class RegistrationsNotifier extends Notifier<List<Registration>> {
  int _seq = 0;
  @override
  List<Registration> build() => MockData.registrations();

  Registration? byId(String? id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  String add({
    required UserRole role,
    required String name,
    required String phone,
    required String idNumber,
    Attachment? idFront,
    Attachment? idBack,
    String? specialtyId,
    String? licenseNumber,
    Attachment? certificate,
  }) {
    // One account per person and role: block a second sign-up with the same
    // ID card number or phone (unless the earlier one was rejected).
    final active = state.where(
      (r) => r.role == role && r.status != ReviewStatus.rejected,
    );
    final idDigits = digitsOnly(idNumber);
    final phoneDigits = normalizePhone(phone);
    if (active.any((r) => digitsOnly(r.idNumber) == idDigits)) {
      throw const DuplicateRegistrationException('id');
    }
    if (active.any((r) => normalizePhone(r.phone) == phoneDigits)) {
      throw const DuplicateRegistrationException('phone');
    }
    final id = 'reg${DateTime.now().millisecondsSinceEpoch}${_seq++}';
    state = [
      Registration(
        id: id,
        role: role,
        name: name.trim(),
        phone: phone.trim(),
        idNumber: idNumber.trim(),
        idFront: idFront,
        idBack: idBack,
        specialtyId: specialtyId,
        licenseNumber: licenseNumber?.trim(),
        certificate: certificate,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    return id;
  }

  void _update(String id, Registration Function(Registration) f) {
    state = [for (final r in state) r.id == id ? f(r) : r];
  }

  /// Server: the list of accounts as the team sees it.
  void replaceAll(List<Registration> list) => state = list;

  /// Server: the signed-in person's own account.
  void upsert(Registration r) => state = [
    r,
    for (final x in state)
      if (x.id != r.id) x,
  ];

  void markPhoneVerified(String id) =>
      _update(id, (r) => r.copyWith(phoneVerified: true));

  /// Committee: approve or reject an account.
  void review(String id, ReviewStatus status) {
    final before = byId(id);
    _update(id, (r) => r.copyWith(status: status, reviewedAt: DateTime.now()));
    final r = byId(id);
    // Server: save the decision there (undone here if it fails).
    if (AccountsRemote.enabled && ref.read(adminProvider).remote) {
      const AccountsRemote().review(id, status).catchError((_) {
        if (before != null) _update(id, (_) => before);
      });
    }
    ref
        .read(adminProvider.notifier)
        .recordIfAdmin(
          status == ReviewStatus.approved ? 'au_approve' : 'au_reject',
          target: r == null ? id : '${r.code} ${r.name}',
        );
  }
}

final registrationsProvider =
    NotifierProvider<RegistrationsNotifier, List<Registration>>(
      RegistrationsNotifier.new,
    );

/// Review status of the signed-in user's account (approved for demo
/// accounts that have no registration).
final myAccountStatusProvider = Provider<ReviewStatus>((ref) {
  final id = ref.watch(authProvider).registrationId;
  if (id == null) return ReviewStatus.approved;
  for (final r in ref.watch(registrationsProvider)) {
    if (r.id == id) return r.status;
  }
  return ReviewStatus.approved;
});
