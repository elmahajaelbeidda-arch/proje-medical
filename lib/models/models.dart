import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum UserRole { patient, doctor, committee }

enum ConsultationStatus { pending, accepted, answered, closed }

enum ConsultationType { lab, imaging, general }

enum Urgency { normal, soon, urgent }

enum AttachmentKind { image, pdf }

/// What a file is: medical exam (imaging, ECG...), lab test, prescription...
enum AttachmentCategory { exam, lab, prescription, other }

class Specialty {
  final String id;
  final IconData icon;
  const Specialty(this.id, this.icon);

  /// Translation key, e.g. `sp_cardio`.
  String get key => 'sp_$id';

  static const all = <Specialty>[
    Specialty('general', Icons.medical_services_outlined),
    Specialty('internal', Icons.monitor_heart_outlined),
    Specialty('pediatrics', Icons.child_care_outlined),
    Specialty('gyneco', Icons.pregnant_woman_outlined),
    Specialty('cardio', Icons.favorite_outline),
    Specialty('derma', Icons.face_retouching_natural_outlined),
    Specialty('ortho', Icons.accessibility_new_outlined),
    Specialty('endo', Icons.bloodtype_outlined),
    Specialty('radiology', Icons.document_scanner_outlined),
    Specialty('psych', Icons.psychology_outlined),
  ];

  static Specialty byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

class Doctor {
  final String id;
  final String name;
  final String specialtyId;
  final int yearsOfExperience;
  final double rating;
  final int consultationsCount;
  final bool verified;
  final bool available;
  final String city;

  /// City name in Latin letters (French interface and search).
  final String cityFr;
  final String bio;
  final List<String> availability;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.yearsOfExperience,
    required this.rating,
    required this.consultationsCount,
    required this.city,
    required this.cityFr,
    required this.bio,
    this.verified = true,
    this.available = true,
    this.availability = const [],
  });

  String cityFor(String languageCode) => languageCode == 'fr' ? cityFr : city;

  String get initials => name.replaceAll('د. ', '').trim().characters.first;
}

class Attachment {
  final String name;
  final AttachmentKind kind;
  final AttachmentCategory category;

  /// File content (null for demo data).
  final Uint8List? bytes;
  final int? size;

  const Attachment(
    this.name,
    this.kind, {
    this.category = AttachmentCategory.lab,
    this.bytes,
    this.size,
  });

  Attachment withCategory(AttachmentCategory c) =>
      Attachment(name, kind, category: c, bytes: bytes, size: size);
}

/// A recorded voice message. [source] is a file path (mobile) or a blob URL
/// (web); it is empty for demo data that has no real audio.
@immutable
class VoiceNote {
  final String source;
  final Duration duration;
  const VoiceNote(this.source, this.duration);

  bool get playable => source.isNotEmpty;
}

class DoctorReply {
  final String findings;
  final String diagnosis;
  final String recommendations;
  final bool needsVisit;
  final DateTime date;

  const DoctorReply({
    required this.findings,
    required this.diagnosis,
    required this.recommendations,
    required this.needsVisit,
    required this.date,
  });
}

class ChatMessage {
  final bool fromDoctor;
  final String text;
  final DateTime time;
  final VoiceNote? voice;
  const ChatMessage({
    required this.fromDoctor,
    required this.text,
    required this.time,
    this.voice,
  });
}

class Consultation {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final bool patientMale;
  final bool hideName;
  final List<String> chronicDiseases;
  final String specialtyId;
  final ConsultationType type;
  final Urgency urgency;
  final String symptoms;
  final String durationKey;
  final List<Attachment> attachments;
  final VoiceNote? voiceNote;
  final ConsultationStatus status;
  final DateTime createdAt;
  final String? doctorId;
  final DoctorReply? reply;
  final List<ChatMessage> messages;
  final int? rating;

  const Consultation({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientMale,
    required this.specialtyId,
    required this.type,
    required this.urgency,
    required this.symptoms,
    required this.durationKey,
    required this.createdAt,
    this.hideName = false,
    this.chronicDiseases = const [],
    this.attachments = const [],
    this.voiceNote,
    this.status = ConsultationStatus.pending,
    this.doctorId,
    this.reply,
    this.messages = const [],
    this.rating,
  });

  String get displayPatientName {
    if (!hideName) return patientName;
    return patientName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p.characters.first}.')
        .join(' ');
  }

  bool get isActive =>
      status == ConsultationStatus.pending ||
      status == ConsultationStatus.accepted;

  Consultation copyWith({
    ConsultationStatus? status,
    String? doctorId,
    DoctorReply? reply,
    List<ChatMessage>? messages,
    int? rating,
  }) {
    return Consultation(
      id: id,
      patientId: patientId,
      patientName: patientName,
      patientAge: patientAge,
      patientMale: patientMale,
      hideName: hideName,
      chronicDiseases: chronicDiseases,
      specialtyId: specialtyId,
      type: type,
      urgency: urgency,
      symptoms: symptoms,
      durationKey: durationKey,
      attachments: attachments,
      voiceNote: voiceNote,
      createdAt: createdAt,
      status: status ?? this.status,
      doctorId: doctorId ?? this.doctorId,
      reply: reply ?? this.reply,
      messages: messages ?? this.messages,
      rating: rating ?? this.rating,
    );
  }
}

class HealthProfile {
  final int age;
  final bool male;
  final String bloodType;
  final Set<String> chronicDiseases;
  final String allergies;
  final String medications;

  const HealthProfile({
    required this.age,
    required this.male,
    required this.bloodType,
    required this.chronicDiseases,
    required this.allergies,
    required this.medications,
  });
}

class AppNotification {
  final IconData icon;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  const AppNotification({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });
}
