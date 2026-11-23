/// Consultations on the server (Supabase), see
/// supabase/migrations/0006_consultations.sql.
///
/// The list each person receives is already filtered by the server: a
/// patient gets their own consultations, an approved doctor the new
/// requests of their specialty and their cases, the team everything.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'accounts_remote.dart';

/// Random identifier (UUID v4) so a new consultation can be shown at once.
String newUuid([math.Random? rnd]) {
  final r = rnd ?? math.Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final s = List.generate(16, h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20)}';
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

/// Server row (+ its files and messages) → the app's consultation.
Consultation consultationFromRows(
  Map<String, dynamic> j, {
  List<Map<String, dynamic>> files = const [],
  List<Map<String, dynamic>> messages = const [],
}) {
  final reply = j['reply'] as Map<String, dynamic>?;
  return Consultation(
    id: j['id'] as String,
    patientId: j['patient_id'] as String,
    patientName: j['patient_name'] as String? ?? '',
    patientAge: (j['patient_age'] as num?)?.toInt() ?? 0,
    patientMale: j['patient_male'] as bool? ?? true,
    hideName: j['hide_name'] as bool? ?? false,
    chronicDiseases: [
      for (final c in (j['chronic'] as List? ?? const [])) c as String,
    ],
    specialtyId: j['specialty_id'] as String? ?? 'general',
    type: _enum(ConsultationType.values, j['type'], ConsultationType.general),
    urgency: _enum(Urgency.values, j['urgency'], Urgency.normal),
    symptoms: j['symptoms'] as String? ?? '',
    durationKey: j['duration_key'] as String? ?? '',
    status: _enum(
      ConsultationStatus.values,
      j['status'],
      ConsultationStatus.pending,
    ),
    createdAt:
        DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    doctorId: j['doctor_id'] as String?,
    doctorName: j['doctor_name'] as String?,
    rating: (j['rating'] as num?)?.toInt(),
    reply: reply == null
        ? null
        : DoctorReply(
            findings: reply['findings'] as String? ?? '',
            diagnosis: reply['diagnosis'] as String? ?? '',
            recommendations: reply['recommendations'] as String? ?? '',
            needsVisit: reply['needs_visit'] as bool? ?? false,
            date:
                DateTime.tryParse(reply['date'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
          ),
    attachments: [
      for (final f in files)
        Attachment(
          f['name'] as String? ?? '',
          f['kind'] == 'pdf' ? AttachmentKind.pdf : AttachmentKind.image,
          category: _enum(
            AttachmentCategory.values,
            f['category'],
            AttachmentCategory.lab,
          ),
          remotePath: f['path'] as String?,
        ),
    ],
    messages: [
      for (final m in messages)
        ChatMessage(
          fromDoctor: m['from_doctor'] as bool? ?? false,
          text: m['text'] as String? ?? '',
          time:
              DateTime.tryParse(m['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
          call: switch (m['call_kind']) {
            'voice' => CallKind.voice,
            'video' => CallKind.video,
            _ => null,
          },
        ),
    ],
  );
}

class ConsultationsRemote {
  const ConsultationsRemote();

  static bool get enabled => AccountsRemote.enabled;

  SupabaseClient get _db => Supabase.instance.client;

  /// Live list of the consultations this person may see, with their files
  /// and messages (updated as soon as something changes).
  Stream<List<Consultation>> watch() {
    final controller = StreamController<List<Consultation>>();
    List<Map<String, dynamic>> cases = const [];
    List<Map<String, dynamic>> msgs = const [];
    List<Map<String, dynamic>> files = const [];
    var ready = 0;
    void emit() {
      if (ready < 2) return;
      final byCase = <String, List<Map<String, dynamic>>>{};
      for (final m in msgs) {
        (byCase[m['consultation_id'] as String] ??= []).add(m);
      }
      final filesByCase = <String, List<Map<String, dynamic>>>{};
      for (final f in files) {
        (filesByCase[f['consultation_id'] as String] ??= []).add(f);
      }
      final list = [
        for (final c in cases)
          consultationFromRows(
            c,
            files: filesByCase[c['id']] ?? const [],
            messages: (byCase[c['id']] ?? [])
              ..sort(
                (a, b) => (a['created_at'] as String).compareTo(
                  b['created_at'] as String,
                ),
              ),
          ),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(list);
    }

    Future<void> loadFiles() async {
      try {
        final List<dynamic> rows = await _db
            .from('consultation_files')
            .select();
        files = [for (final r in rows) r as Map<String, dynamic>];
        emit();
      } catch (_) {}
    }

    final subs = <StreamSubscription<dynamic>>[
      _db.from('consultations').stream(primaryKey: ['id']).listen((rows) {
        cases = rows;
        if (ready < 2) ready++;
        emit();
        // New consultations may bring new files.
        loadFiles();
      }, onError: controller.addError),
      _db.from('consultation_messages').stream(primaryKey: ['id']).listen((
        rows,
      ) {
        msgs = rows;
        if (ready < 2) ready++;
        emit();
      }, onError: controller.addError),
    ];
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }

  /// Sends a new request (then its files). [id] is made by the app.
  Future<void> create(Consultation c) async {
    await _db.from('consultations').insert({
      'id': c.id,
      'patient_name': c.patientName,
      'patient_age': c.patientAge,
      'patient_male': c.patientMale,
      'hide_name': c.hideName,
      'chronic': c.chronicDiseases,
      'specialty_id': c.specialtyId,
      'type': c.type.name,
      'urgency': c.urgency.name,
      'symptoms': c.symptoms,
      'duration_key': c.durationKey,
    });
    var n = 0;
    for (final a in c.attachments) {
      final bytes = a.bytes;
      if (bytes == null) continue;
      final ext = a.name.contains('.')
          ? a.name.split('.').last.toLowerCase()
          : (a.kind == AttachmentKind.pdf ? 'pdf' : 'jpg');
      final path =
          '${c.id}/${n++}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _db.storage.from('consultations').uploadBinary(path, bytes);
      await _db.from('consultation_files').insert({
        'consultation_id': c.id,
        'path': path,
        'name': a.name,
        'kind': a.kind.name,
        'category': a.category.name,
      });
    }
  }

  Future<void> accept(String id) =>
      _db.rpc('accept_consultation', params: {'p_id': id});

  Future<void> reply(String id, DoctorReply r) => _db.rpc(
    'reply_consultation',
    params: {
      'p_id': id,
      'p_reply': {
        'findings': r.findings,
        'diagnosis': r.diagnosis,
        'recommendations': r.recommendations,
        'needs_visit': r.needsVisit,
        'date': r.date.toUtc().toIso8601String(),
      },
    },
  );

  Future<void> rate(String id, int stars) =>
      _db.rpc('rate_consultation', params: {'p_id': id, 'p_stars': stars});

  Future<void> sendMessage(String id, ChatMessage m) async {
    await _db.from('consultation_messages').insert({
      'consultation_id': id,
      'text': m.text,
      if (m.call != null) 'call_kind': m.call!.name,
    });
  }

  /// Short-lived link to open a medical file.
  Future<String?> fileUrl(String path) async {
    try {
      return await _db.storage.from('consultations').createSignedUrl(path, 600);
    } catch (_) {
      return null;
    }
  }
}
