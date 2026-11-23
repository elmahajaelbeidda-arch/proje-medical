import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/consultations_remote.dart';
import 'package:shifa/models/models.dart';

void main() {
  test('a server consultation becomes the app consultation', () {
    final c = consultationFromRows(
      {
        'id': 'c-1',
        'patient_id': 'u-p',
        'patient_name': 'زينب محمد',
        'patient_age': 41,
        'patient_male': false,
        'hide_name': true,
        'chronic': ['cd_diabetes'],
        'specialty_id': 'internal',
        'type': 'lab',
        'urgency': 'soon',
        'symptoms': 'تعب مستمر',
        'duration_key': 'dur_week',
        'status': 'answered',
        'doctor_id': 'u-d',
        'doctor_name': 'د. مريم',
        'rating': 5,
        'created_at': '2026-11-23T10:00:00Z',
        'reply': {
          'findings': 'f',
          'diagnosis': 'd',
          'recommendations': 'r',
          'needs_visit': true,
          'date': '2026-11-23T12:00:00Z',
        },
      },
      files: [
        {
          'path': 'c-1/0.pdf',
          'name': 'cbc.pdf',
          'kind': 'pdf',
          'category': 'lab',
        },
      ],
      messages: [
        {
          'from_doctor': true,
          'text': 'مرحبًا',
          'created_at': '2026-11-23T12:01:00Z',
        },
        {
          'from_doctor': false,
          'text': '',
          'call_kind': 'video',
          'created_at': '2026-11-23T12:02:00Z',
        },
      ],
    );
    expect(c.type, ConsultationType.lab);
    expect(c.urgency, Urgency.soon);
    expect(c.status, ConsultationStatus.answered);
    expect(c.displayPatientName, 'ز. م.');
    expect(c.doctorName, 'د. مريم');
    expect(c.reply!.needsVisit, isTrue);
    expect(c.attachments.single.remotePath, 'c-1/0.pdf');
    expect(c.attachments.single.kind, AttachmentKind.pdf);
    expect(c.messages.first.fromDoctor, isTrue);
    expect(c.messages.last.call, CallKind.video);
  });

  test('new ids are valid random UUIDs', () {
    final a = newUuid(), b = newUuid();
    expect(a, isNot(b));
    expect(
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      ).hasMatch(a),
      isTrue,
    );
  });
}
