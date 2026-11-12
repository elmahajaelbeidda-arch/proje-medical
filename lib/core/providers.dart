import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../models/registration.dart';
import 'admin_provider.dart';

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class LocaleNotifier extends Notifier<Locale> {
  /// Default language set by the administration (French can be switched off).
  @override
  Locale build() {
    final settings = ref.watch(appSettingsProvider);
    return Locale(settings.frenchEnabled ? settings.defaultLanguage : 'ar');
  }

  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
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
  String get doctorId =>
      isPsychDoctor ? MockData.psychDoctorId : MockData.currentDoctorId;

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
    return isDoctor ? MockData.doctorById(doctorId)!.name : 'محمد الأمين';
  }

  String get userId => isDoctor ? doctorId : MockData.currentPatientId;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

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

  void logout() => state = const AuthState();
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
  HealthProfile build() => const HealthProfile(
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
  @override
  List<Consultation> build() => MockData.consultations();

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
    final id = 'c${DateTime.now().millisecondsSinceEpoch}';
    state = [
      Consultation(
        id: id,
        patientId: MockData.currentPatientId,
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
    return id;
  }

  void _update(String id, Consultation Function(Consultation c) change) {
    state = [for (final c in state) c.id == id ? change(c) : c];
  }

  void accept(String id, String doctorId) => _update(
    id,
    (c) => c.copyWith(status: ConsultationStatus.accepted, doctorId: doctorId),
  );

  void reply(String id, DoctorReply reply) => _update(
    id,
    (c) => c.copyWith(status: ConsultationStatus.answered, reply: reply),
  );

  void sendMessage(String id, ChatMessage message) =>
      _update(id, (c) => c.copyWith(messages: [...c.messages, message]));

  void rate(String id, int rating) =>
      _update(id, (c) => c.copyWith(rating: rating));
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

  void markPhoneVerified(String id) =>
      _update(id, (r) => r.copyWith(phoneVerified: true));

  /// Committee: approve or reject an account.
  void review(String id, ReviewStatus status) => _update(
    id,
    (r) => r.copyWith(status: status, reviewedAt: DateTime.now()),
  );
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
