import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/models/models.dart';

void main() {
  test('translations exist for Arabic and French', () {
    expect(AppStrings.of('ar', 'app_name'), 'شفاء');
    expect(AppStrings.of('fr', 'app_name'), 'Chifa');
    expect(AppStrings.of('ar', 'missing_key'), 'missing_key');
  });

  test('patient can create a consultation and doctor can answer it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(consultationsProvider.notifier);

    final id = repo.create(
      specialtyId: 'cardio',
      type: ConsultationType.general,
      urgency: Urgency.normal,
      symptoms: 'Douleur thoracique légère',
      durationKey: 'dur_days',
      attachments: const [],
      hideName: true,
      patientName: 'Ali Ben Salah',
      profile: container.read(healthProfileProvider),
    );

    var c = container.read(consultationProvider(id))!;
    expect(c.status, ConsultationStatus.pending);
    expect(c.displayPatientName, 'A. B. S.');

    repo.accept(id, MockData.currentDoctorId);
    c = container.read(consultationProvider(id))!;
    expect(c.status, ConsultationStatus.accepted);
    expect(c.doctorId, MockData.currentDoctorId);

    repo.reply(
      id,
      DoctorReply(
        findings: 'f',
        diagnosis: 'd',
        recommendations: 'r',
        needsVisit: true,
        date: DateTime.now(),
      ),
    );
    c = container.read(consultationProvider(id))!;
    expect(c.status, ConsultationStatus.answered);
    expect(c.reply?.needsVisit, isTrue);
  });
}
