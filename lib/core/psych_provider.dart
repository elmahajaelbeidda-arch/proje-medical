import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/psych.dart';

class PsychNotifier extends Notifier<List<PsychSession>> {
  int _seq = 0;

  /// Unique even when two sessions are created in the same millisecond.
  String _newId() => 'ps${DateTime.now().millisecondsSinceEpoch}${_seq++}';

  @override
  List<PsychSession> build() => _seed();

  PsychSession? byId(String id) {
    for (final s in state) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _update(String id, PsychSession Function(PsychSession s) change) =>
      state = [for (final s in state) s.id == id ? change(s) : s];

  /// Patient: request a session at one of the doctor's free slots.
  String book({
    required String patientId,
    required String patientName,
    required String alias,
    required bool shareName,
    required int age,
    required bool male,
    required Set<PsychTopic> topics,
    required String description,
    required bool riskFlag,
    required String doctorId,
    required DateTime slot,
    required SessionMode mode,
  }) {
    if (!freeSlots(doctorId, state, from: DateTime.now()).contains(slot)) {
      throw StateError('slot not available');
    }
    final id = _newId();
    state = [
      PsychSession(
        id: id,
        patientId: patientId,
        patientName: patientName.trim(),
        alias: alias.trim().isEmpty ? 'مستفيد' : alias.trim(),
        shareName: shareName,
        age: age,
        male: male,
        topics: topics,
        description: description.trim(),
        riskFlag: riskFlag,
        doctorId: doctorId,
        slot: slot,
        mode: mode,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    return id;
  }

  /// Doctor: confirm or decline a requested appointment.
  void confirm(String id) =>
      _setStatus(id, PsychStatus.confirmed, {PsychStatus.requested});
  void decline(String id) =>
      _setStatus(id, PsychStatus.declined, {PsychStatus.requested});

  /// Patient: cancel an upcoming appointment.
  void cancel(String id) => _setStatus(id, PsychStatus.cancelled, {
    PsychStatus.requested,
    PsychStatus.confirmed,
  });

  /// Doctor: end the session, with advice shared with the patient.
  void complete(String id, {String recommendations = ''}) {
    _setStatus(id, PsychStatus.completed, {PsychStatus.confirmed});
    if (recommendations.trim().isNotEmpty) {
      _update(id, (s) => s.copyWith(recommendations: recommendations.trim()));
    }
  }

  void _setStatus(String id, PsychStatus to, Set<PsychStatus> from) {
    final s = byId(id);
    if (s == null || !from.contains(s.status)) {
      throw StateError('cannot go from ${s?.status} to $to');
    }
    _update(id, (s) => s.copyWith(status: to));
  }

  /// Doctor: confidential notes, never shown to the patient or the team.
  void saveNotes(String id, String notes) =>
      _update(id, (s) => s.copyWith(privateNotes: notes));

  void sendMessage(
    String id, {
    required bool fromDoctor,
    required String text,
  }) {
    if (text.trim().isEmpty) return;
    _update(
      id,
      (s) => s.copyWith(
        messages: [
          ...s.messages,
          PsychMessage(
            fromDoctor: fromDoctor,
            text: text.trim(),
            time: DateTime.now(),
          ),
        ],
      ),
    );
  }

  /// Doctor: book the next session of the same follow-up (confirmed).
  String scheduleFollowUp(String id, DateTime slot) {
    final s = byId(id)!;
    if (!freeSlots(s.doctorId, state, from: DateTime.now()).contains(slot)) {
      throw StateError('slot not available');
    }
    final newId = _newId();
    state = [
      PsychSession(
        id: newId,
        patientId: s.patientId,
        patientName: s.patientName,
        alias: s.alias,
        shareName: s.shareName,
        age: s.age,
        male: s.male,
        topics: s.topics,
        description: s.description,
        doctorId: s.doctorId,
        slot: slot,
        mode: s.mode,
        status: PsychStatus.confirmed,
        followUpOf: s.id,
        privateNotes: s.privateNotes,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    return newId;
  }

  static List<PsychSession> _seed() {
    final now = DateTime.now();
    DateTime at(int days, int hour) =>
        DateTime(now.year, now.month, now.day + days, hour);
    return [
      PsychSession(
        id: 'ps1',
        patientId: MockData.currentPatientId,
        patientName: 'محمد الأمين',
        alias: 'أبو أحمد',
        age: 54,
        male: true,
        topics: const {PsychTopic.sleep, PsychTopic.stress},
        description: 'أرق منذ أشهر وقلق مستمر بسبب المرض والعمل.',
        doctorId: 'd10',
        slot: at(-6, 17),
        mode: SessionMode.voice,
        status: PsychStatus.completed,
        recommendations: 'تنظيم مواعيد النوم، تمارين التنفس قبل النوم 10 دقائق، وتقليل الشاي بعد العصر. نلتقي في جلسة متابعة.',
        privateNotes: 'قلق مرتبط بالسكري. لا مؤشرات خطر.',
        messages: [
          PsychMessage(
            fromDoctor: true,
            text: 'مرحباً، كيف كان نومك هذا الأسبوع؟',
            time: at(-6, 17),
          ),
          PsychMessage(
            fromDoctor: false,
            text: 'أفضل قليلاً، شكراً دكتور.',
            time: at(-6, 17).add(const Duration(minutes: 5)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      PsychSession(
        id: 'ps2',
        patientId: 'p20',
        patientName: 'عائشة سالم',
        alias: 'أمل',
        age: 27,
        male: false,
        topics: const {PsychTopic.anxiety, PsychTopic.family},
        description: 'نوبات قلق وضيق في التنفس قبل المناسبات العائلية.',
        doctorId: 'd9',
        slot: at(1, 18),
        mode: SessionMode.chat,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      PsychSession(
        id: 'ps3',
        patientId: 'p21',
        patientName: 'سيدي محمد',
        alias: 'س. م',
        age: 34,
        male: true,
        topics: const {PsychTopic.depression},
        description: 'فقدان الرغبة في العمل والعزلة منذ وفاة والدي.',
        riskFlag: true,
        doctorId: 'd9',
        slot: at(2, 19),
        mode: SessionMode.voice,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      PsychSession(
        id: 'ps4',
        patientId: 'p22',
        patientName: 'مريم الشيخ',
        alias: 'مريم',
        shareName: true,
        age: 41,
        male: false,
        topics: const {PsychTopic.stress, PsychTopic.sleep},
        description: 'إرهاق وضغط نفسي بسبب رعاية والدتي المريضة.',
        doctorId: 'd9',
        slot: at(3, 20),
        mode: SessionMode.video,
        status: PsychStatus.confirmed,
        privateNotes: 'الجلسة الثانية. تحسّن في النوم.',
        followUpOf: 'ps0',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }
}

final psychProvider = NotifierProvider<PsychNotifier, List<PsychSession>>(
  PsychNotifier.new,
);
