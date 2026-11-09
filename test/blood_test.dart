import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/blood_provider.dart';
import 'package:shifa/models/blood.dart';

BloodDonor donor(
  String id,
  String type,
  String city, {
  bool available = true,
  DateTime? last,
  bool share = true,
}) => BloodDonor(
  id: id,
  name: id,
  bloodType: type,
  city: city,
  phone: '0550000000',
  available: available,
  lastDonation: last,
  shareContact: share,
);

BloodRequest request(String type, String city, {bool urgent = false}) =>
    BloodRequest(
      id: 'r-$type-$city',
      requesterId: 'p',
      patientName: 'x',
      bloodType: type,
      units: 1,
      hospital: 'h',
      city: city,
      phone: '0550000000',
      urgent: urgent,
      createdAt: DateTime(2026),
    );

void main() {
  test('red-cell compatibility rules', () {
    // O- gives to everyone, AB+ receives from everyone.
    for (final t in bloodTypes) {
      expect(canDonate('O-', t), isTrue, reason: 'O- -> $t');
      expect(canDonate(t, 'AB+'), isTrue, reason: '$t -> AB+');
    }
    expect(compatibleDonorTypes('O-'), ['O-']);
    expect(compatibleDonorTypes('A+'), ['O-', 'O+', 'A-', 'A+']);
    expect(compatibleDonorTypes('B-'), ['O-', 'B-']);
    expect(canDonate('A+', 'A-'), isFalse); // Rh+ to Rh-
    expect(canDonate('A-', 'B+'), isFalse); // A to B
    expect(canDonate('AB+', 'O+'), isFalse);
  });

  test('matching donors: compatible, contactable, same city first', () {
    final donors = [
      donor('far-exact', 'O+', 'Oran'),
      donor('near-universal', 'O-', 'Alger'),
      donor('near-exact', 'O+', 'Alger'),
      donor('incompatible', 'A+', 'Alger'),
      donor('unavailable', 'O+', 'Alger', available: false),
      donor(
        'too-soon',
        'O+',
        'Alger',
        last: DateTime.now().subtract(const Duration(days: 20)),
      ),
      donor('no-consent', 'O+', 'Alger', share: false),
    ];
    final ids = matchDonors(request('O+', 'alger '), donors).map((d) => d.id);
    expect(ids, ['near-exact', 'near-universal', 'far-exact']);
  });

  test('matching requests for a donor: urgent first', () {
    final me = donor('me', 'O-', 'Alger');
    final reqs = [
      request('A+', 'Oran'),
      request('AB-', 'Alger', urgent: true),
      request('B+', 'Alger'),
    ];
    final types = matchRequests(me, reqs).map((r) => r.bloodType).toList();
    expect(types.first, 'AB-');
    expect(types.length, 3);
    expect(matchRequests(donor('ab', 'AB+', 'Alger'), reqs), isEmpty);
  });

  test('request, register as donor, volunteer, fulfil', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final blood = c.read(bloodProvider.notifier);

    final id = blood.addRequest(
      patientName: 'Amina',
      bloodType: 'A-',
      units: 2,
      hospital: 'CHU',
      city: 'Sétif',
      urgent: true,
      phone: '0550 11 22 33',
      contact: ContactMethod.whatsapp,
    );
    blood.saveMyDonor(
      name: 'Karim',
      bloodType: 'O-',
      city: 'Sétif',
      phone: '0550 44 55 66',
      contact: ContactMethod.call,
      available: true,
      shareContact: true,
    );
    var s = c.read(bloodProvider);
    expect(s.myDonor?.bloodType, 'O-');
    expect(matchDonors(s.request(id)!, s.donors).first.id, s.myDonorId);

    blood.volunteer(id);
    blood.volunteer(id); // no duplicates
    s = c.read(bloodProvider);
    expect(s.request(id)!.volunteerIds, [s.myDonorId]);

    blood.markFulfilled(id);
    expect(c.read(bloodProvider).request(id)!.isOpen, isFalse);
  });
}
