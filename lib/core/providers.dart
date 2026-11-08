import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar');
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
  const AuthState({
    this.role = UserRole.patient,
    this.loggedIn = false,
    this.name = '',
    this.phone = '',
    this.idNumber = '',
    this.phoneVerified = false,
  });

  /// e.g. "•••• 4821"
  String get maskedId => idNumber.length <= 4
      ? idNumber
      : '•••• ${idNumber.substring(idNumber.length - 4)}';

  bool get isDoctor => role == UserRole.doctor;

  /// Name shown in the UI (falls back to the demo user's name).
  String get displayName {
    if (name.isNotEmpty) return name;
    return isDoctor
        ? MockData.doctorById(MockData.currentDoctorId)!.name
        : 'محمد الأمين';
  }

  String get userId =>
      isDoctor ? MockData.currentDoctorId : MockData.currentPatientId;
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
  }) {
    state = AuthState(
      role: state.role,
      name: name.trim(),
      phone: phone.trim(),
      idNumber: idNumber.trim(),
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
  );

  void login({String? name}) {
    final defaultName = state.isDoctor
        ? MockData.doctorById(MockData.currentDoctorId)!.name
        : 'محمد الأمين';
    state = AuthState(
      role: state.role,
      loggedIn: true,
      name: (name == null || name.trim().isEmpty) ? defaultName : name.trim(),
      // Demo account: already verified at sign-up.
      phone: '0550 12 34 56',
      idNumber: '109870512304821',
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
