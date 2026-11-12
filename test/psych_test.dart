import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/providers.dart';
import 'package:shifa/core/psych_provider.dart';
import 'package:shifa/data/mock_data.dart';
import 'package:shifa/models/models.dart';
import 'package:shifa/models/psych.dart';

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  PsychNotifier n() => c.read(psychProvider.notifier);

  String book(DateTime slot, {String doctor = 'd10'}) => n().book(
    patientId: MockData.currentPatientId,
    patientName: 'محمد الأمين',
    alias: ' م. أ ',
    shareName: false,
    age: 54,
    male: true,
    topics: {PsychTopic.anxiety},
    description: 'قلق',
    riskFlag: false,
    doctorId: doctor,
    slot: slot,
    mode: SessionMode.chat,
  );

  test('demo doctor ids are unique', () {
    final ids = MockData.doctors.map((d) => d.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('psychiatry is a specialty with volunteer doctors', () {
    expect(Specialty.all.any((s) => s.id == 'psych'), isTrue);
    expect(
      MockData.doctors.where((d) => d.specialtyId == 'psych'),
      hasLength(2),
    );
  });

  test('free slots follow the weekly hours and skip booked ones', () {
    final from = DateTime(2026, 11, 14, 8); // Saturday morning
    final slots = freeSlots('d9', const [], from: from, days: 6);
    // Saturday 17,18,19 + Monday 20,21 + Wednesday 18,19,20
    expect(slots, hasLength(8));
    expect(slots.first, DateTime(2026, 11, 14, 17));
    final taken = PsychSession(
      id: 'x',
      patientId: 'p',
      patientName: 'n',
      alias: 'a',
      age: 30,
      male: true,
      topics: const {},
      description: '',
      doctorId: 'd9',
      slot: DateTime(2026, 11, 14, 17),
      mode: SessionMode.chat,
      createdAt: from,
    );
    expect(
      freeSlots('d9', [taken], from: from, days: 6),
      isNot(contains(DateTime(2026, 11, 14, 17))),
    );
    // Slots less than 2 hours away are not offered.
    expect(
      freeSlots('d9', const [], from: DateTime(2026, 11, 14, 16), days: 0),
      [DateTime(2026, 11, 14, 18), DateTime(2026, 11, 14, 19)],
    );
  });

  test('booking, double booking and the session life cycle', () {
    final slot = freeSlots('d10', c.read(psychProvider)).first;
    final id = book(slot);
    final s = n().byId(id)!;
    expect(s.status, PsychStatus.requested);
    expect(s.alias, 'م. أ');
    expect(s.nameForDoctor, 'م. أ'); // real name hidden by default
    expect(() => book(slot), throwsStateError); // slot already taken

    expect(() => n().complete(id), throwsStateError); // not confirmed yet
    n().confirm(id);
    n().saveNotes(id, 'سري');
    n().complete(id, recommendations: 'تمارين تنفس');
    final done = n().byId(id)!;
    expect(done.status, PsychStatus.completed);
    expect(done.recommendations, 'تمارين تنفس');

    final next = freeSlots('d10', c.read(psychProvider)).first;
    final f = n().byId(n().scheduleFollowUp(id, next))!;
    expect(f.followUpOf, id);
    expect(f.status, PsychStatus.confirmed);
    expect(f.privateNotes, 'سري');
  });

  test('patient can cancel, doctor can decline', () {
    final slots = freeSlots('d10', c.read(psychProvider));
    final a = book(slots[0]);
    final b = book(slots[1]);
    n().cancel(a);
    n().decline(b);
    expect(n().byId(a)!.status, PsychStatus.cancelled);
    expect(n().byId(b)!.status, PsychStatus.declined);
    // A cancelled slot is free again.
    expect(freeSlots('d10', c.read(psychProvider)), contains(slots[0]));
  });

  test('psychiatrist account opens the psychiatrist workspace', () {
    final auth = c.read(authProvider.notifier);
    auth.selectRole(UserRole.doctor);
    auth.login(specialtyId: 'psych');
    expect(c.read(authProvider).isPsychDoctor, isTrue);
    expect(c.read(authProvider).doctorId, MockData.psychDoctorId);
    auth.selectRole(UserRole.patient);
    auth.login(specialtyId: 'psych');
    expect(c.read(authProvider).isPsychDoctor, isFalse);
  });
}
