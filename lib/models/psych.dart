/// Psychological consultations: a patient books a confidential session with
/// a volunteer psychiatrist / psychologist. Only the patient and the assigned
/// doctor can see a session; the follow-up team never sees its content.
library;

enum PsychTopic {
  anxiety,
  depression,
  stress,
  sleep,
  family,
  trauma,
  addiction,
  other,
}

enum SessionMode { chat, voice, video }

enum PsychStatus { requested, confirmed, completed, declined, cancelled }

class PsychMessage {
  final bool fromDoctor;
  final String text;
  final DateTime time;
  const PsychMessage({
    required this.fromDoctor,
    required this.text,
    required this.time,
  });
}

class PsychSession {
  final String id;
  final String patientId;

  /// Real name, shown to the doctor only when [shareName] is true.
  final String patientName;

  /// Pseudonym chosen by the patient (default shown to the doctor).
  final String alias;
  final bool shareName;
  final int age;
  final bool male;
  final Set<PsychTopic> topics;
  final String description;

  /// The patient said they have thoughts of harming themselves.
  final bool riskFlag;
  final String doctorId;
  final DateTime slot;
  final SessionMode mode;
  final PsychStatus status;

  /// Seen by the doctor only.
  final String privateNotes;

  /// Advice shared with the patient after the session.
  final String recommendations;

  /// Previous session of the same follow-up.
  final String? followUpOf;
  final List<PsychMessage> messages;
  final DateTime createdAt;

  const PsychSession({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.alias,
    required this.age,
    required this.male,
    required this.topics,
    required this.description,
    required this.doctorId,
    required this.slot,
    required this.mode,
    required this.createdAt,
    this.shareName = false,
    this.riskFlag = false,
    this.status = PsychStatus.requested,
    this.privateNotes = '',
    this.recommendations = '',
    this.followUpOf,
    this.messages = const [],
  });

  /// Name the doctor sees.
  String get nameForDoctor => shareName ? patientName : alias;

  bool get isUpcoming =>
      status == PsychStatus.requested || status == PsychStatus.confirmed;

  String get code {
    var digits = id.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) digits = '0';
    if (digits.length > 4) digits = digits.substring(digits.length - 4);
    return 'PS-${digits.padLeft(3, '0')}';
  }

  PsychSession copyWith({
    PsychStatus? status,
    String? privateNotes,
    String? recommendations,
    List<PsychMessage>? messages,
  }) => PsychSession(
    id: id,
    patientId: patientId,
    patientName: patientName,
    alias: alias,
    shareName: shareName,
    age: age,
    male: male,
    topics: topics,
    description: description,
    riskFlag: riskFlag,
    doctorId: doctorId,
    slot: slot,
    mode: mode,
    followUpOf: followUpOf,
    createdAt: createdAt,
    status: status ?? this.status,
    privateNotes: privateNotes ?? this.privateNotes,
    recommendations: recommendations ?? this.recommendations,
    messages: messages ?? this.messages,
  );
}

/// Weekly hours of a volunteer psychiatrist: weekday (1 = Monday) → hours.
const psychDoctorHours = <String, Map<int, List<int>>>{
  'd9': {
    DateTime.saturday: [17, 18, 19],
    DateTime.monday: [20, 21],
    DateTime.wednesday: [18, 19, 20],
  },
  'd10': {
    DateTime.sunday: [16, 17, 18],
    DateTime.tuesday: [19, 20, 21],
    DateTime.thursday: [17, 18],
  },
};

/// Free 45-minute slots of [doctorId] in the next [days] days, excluding
/// those already booked.
List<DateTime> freeSlots(
  String doctorId,
  Iterable<PsychSession> sessions, {
  DateTime? from,
  int days = 14,
}) {
  final now = from ?? DateTime.now();
  final hours = psychDoctorHours[doctorId] ?? const {};
  final taken = {
    for (final s in sessions)
      if (s.doctorId == doctorId && s.isUpcoming) s.slot,
  };
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (var d = 0; d <= days; d++)
      for (final h
          in hours[today.add(Duration(days: d)).weekday] ?? const <int>[])
        if (DateTime(today.year, today.month, today.day + d, h) case final slot
            when !slot.isBefore(now.add(const Duration(hours: 2))) &&
                !taken.contains(slot))
          slot,
  ];
}
