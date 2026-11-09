import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/features/aid/aid_models.dart';
import 'package:shifa/features/aid/aid_repository.dart';

AidRequestDraft draft({bool consent = true}) => AidRequestDraft(
  patientName: 'Khadija',
  phone: '22 11 22 33',
  latitude: 18.09,
  longitude: -15.97,
  addressNote: 'Tevragh Zeina',
  conditionDescription: 'Besoin d’une visite',
  urgency: AidUrgency.urgent,
  consentGiven: consent,
);

void main() {
  test('database rows map to the enums used in the SQL migration', () {
    final r = AidRequest.fromMap({
      'id': 'x',
      'user_id': 'u',
      'patient_name': 'Ali',
      'phone': '22 11 22 33',
      'latitude': 18.07,
      'longitude': -15.95,
      'address_note': null,
      'condition_description': 'fièvre',
      'urgency': 'medium',
      'status': 'verifying',
      'verified_by': null,
      'verified_at': null,
      'consent_given': true,
      'created_at': '2026-11-09T10:00:00Z',
    });
    expect(r.urgency, AidUrgency.medium);
    expect(r.status, AidStatus.verifying);
    expect(r.addressNote, '');
    expect(AidStatus.newRequest.db, 'new');

    final row = draft().toInsertMap();
    expect(row['urgency'], 'urgent');
    expect(row['consent_given'], isTrue);
    // Status, owner and dates are decided by the database, not the client.
    expect(row.containsKey('status'), isFalse);
    expect(row.containsKey('user_id'), isFalse);
  });

  test('patient: consent required, sees only own requests', () async {
    final patient = DemoAidRepository(role: null, userId: 'patient-test');
    expect(() => patient.submit(draft(consent: false)), throwsStateError);

    final id = await patient.submit(draft());
    final mine = await patient.watchMine().first;
    expect(mine.map((r) => r.id), contains(id));
    expect(mine.every((r) => r.userId == 'patient-test'), isTrue);
    // A patient cannot change statuses.
    expect(() => patient.setStatus(id, AidStatus.verified), throwsStateError);
  });

  test('member verifies but cannot close or delete; supervisor can', () async {
    final patient = DemoAidRepository(role: null, userId: 'patient-2');
    final id = await patient.submit(draft());

    final member = DemoAidRepository(
      role: CommitteeRole.member,
      userId: 'member-1',
    );
    final all = await member.watchAll().first;
    expect(all.length, greaterThan(1)); // committee sees every request

    await member.setStatus(id, AidStatus.verified);
    var r = (await member.watchAll().first).firstWhere((e) => e.id == id);
    expect(r.status, AidStatus.verified);
    expect(r.verifiedBy, 'member-1');
    expect(r.verifiedAt, isNotNull);

    expect(() => member.setStatus(id, AidStatus.closed), throwsStateError);
    expect(() => member.delete(id), throwsStateError);

    final supervisor = DemoAidRepository(
      role: CommitteeRole.supervisor,
      userId: 'sup-1',
    );
    await supervisor.setStatus(id, AidStatus.closed);
    r = (await supervisor.watchAll().first).firstWhere((e) => e.id == id);
    expect(r.status, AidStatus.closed);
    await supervisor.delete(id);
    expect((await supervisor.watchAll().first).any((e) => e.id == id), isFalse);
  });
}
