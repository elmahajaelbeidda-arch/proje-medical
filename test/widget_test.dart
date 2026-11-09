import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/models/models.dart';

void main() {
  test('translations exist for Arabic and French', () {
    expect(AppStrings.of('ar', 'app_name'), 'شِفاءٌ لِلنّاس');
    expect(AppStrings.of('fr', 'app_name'), 'Chifa Linnas');
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

  test('voice-only request keeps the voice note and file categories', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repo = container.read(consultationsProvider.notifier);

    final id = repo.create(
      specialtyId: 'internal',
      type: ConsultationType.lab,
      urgency: Urgency.soon,
      symptoms: '',
      durationKey: 'dur_weeks',
      attachments: const [
        Attachment(
          'ordonnance.jpg',
          AttachmentKind.image,
          category: AttachmentCategory.prescription,
        ),
        Attachment('bilan.pdf', AttachmentKind.pdf),
      ],
      voiceNote: const VoiceNote('blob:demo', Duration(seconds: 42)),
      hideName: false,
      patientName: 'Amina',
      profile: container.read(healthProfileProvider),
    );

    final c = container.read(consultationProvider(id))!;
    expect(c.voiceNote?.duration, const Duration(seconds: 42));
    expect(c.voiceNote?.playable, isTrue);
    expect(c.attachments.first.category, AttachmentCategory.prescription);
    expect(c.attachments.last.category, AttachmentCategory.lab);

    // Status changes must not drop the voice note.
    repo.accept(id, MockData.currentDoctorId);
    expect(container.read(consultationProvider(id))!.voiceNote, isNotNull);
  });

  test('sign-up stores the ID card and logs in only after verification', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final auth = container.read(authProvider.notifier);

    auth.selectRole(UserRole.patient);
    auth.register(
      name: 'Amina',
      phone: '22 11 22 33',
      idNumber: '109870512304821',
    );
    var state = container.read(authProvider);
    expect(state.loggedIn, isFalse);
    expect(state.maskedId, '•••• 4821');

    auth.verifyPhone();
    state = container.read(authProvider);
    expect(state.loggedIn, isTrue);
    expect(state.phoneVerified, isTrue);
    expect(state.idNumber, '109870512304821');
  });
}
