import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/blood_provider.dart';
import 'package:shifa/models/blood.dart';

BloodDonor donor(
  String id,
  String type,
  String city, {
  DonorStatus status = DonorStatus.approved,
  bool available = true,
  bool share = true,
}) => BloodDonor(
  id: id,
  name: id,
  bloodType: type,
  city: city,
  phone: '0550000000',
  status: status,
  available: available,
  shareContact: share,
);

BloodRequest request(String type, String city) => BloodRequest(
  id: 'r-$type-$city',
  requesterId: 'p',
  patientName: 'x',
  bloodType: type,
  units: 1,
  hospital: 'h',
  city: city,
  phone: '0550000000',
  createdAt: DateTime(2026),
);

void main() {
  test('red-cell compatibility rules', () {
    for (final t in bloodTypes) {
      expect(canDonate('O-', t), isTrue, reason: 'O- -> $t');
      expect(canDonate(t, 'AB+'), isTrue, reason: '$t -> AB+');
    }
    expect(compatibleDonorTypes('O-'), ['O-']);
    expect(compatibleDonorTypes('A+'), ['O-', 'O+', 'A-', 'A+']);
    expect(compatibleDonorTypes('B-'), ['O-', 'B-']);
    expect(canDonate('A+', 'A-'), isFalse);
    expect(canDonate('A-', 'B+'), isFalse);
    expect(canDonate('AB+', 'O+'), isFalse);
  });

  test('only approved, available, consenting donors are suggested', () {
    final donors = [
      donor('far-exact', 'O+', 'Oran'),
      donor('near-universal', 'O-', 'Alger'),
      donor('near-exact', 'O+', 'Alger'),
      donor('incompatible', 'A+', 'Alger'),
      donor('pending', 'O+', 'Alger', status: DonorStatus.pending),
      donor('rejected', 'O+', 'Alger', status: DonorStatus.rejected),
      donor('unavailable', 'O+', 'Alger', available: false),
      donor('no-consent', 'O+', 'Alger', share: false),
    ];
    final ids = matchDonors(request('O+', 'alger '), donors).map((d) => d.id);
    expect(ids, ['near-exact', 'near-universal', 'far-exact']);
  });

  test('privacy helpers mask names and phone numbers', () {
    expect(maskPhone('0550 12 34 56'), '0550 •• •• 56');
    expect(maskName('عائشة بن موسى'), 'ع. ب. م.');
    expect(donor('bd7', 'O+', 'x').code, 'D-007');
  });

  test('donor registration goes to the committee for review', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final blood = c.read(bloodProvider.notifier);

    blood.saveMyDonor(
      name: 'Karim',
      bloodType: 'O-',
      city: 'Sétif',
      phone: '0550 44 55 66',
      shareContact: true,
      kind: DonorKind.doctor,
    );
    BloodDonor me() => c.read(bloodProvider).myDonor!;
    expect(me().status, DonorStatus.pending);
    expect(me().kind, DonorKind.doctor);
    expect(me().canBeContacted, isFalse); // not reviewed yet

    blood.reviewDonor(me().id, DonorStatus.approved);
    expect(me().canBeContacted, isTrue);

    // Any change of the registration is reviewed again.
    blood.saveMyDonor(
      name: 'Karim',
      bloodType: 'O-',
      city: 'Alger',
      phone: '0550 44 55 66',
      shareContact: true,
      kind: DonorKind.doctor,
    );
    expect(me().status, DonorStatus.pending);
    expect(me().city, 'Alger');
    expect(
      c.read(bloodProvider).donors.where((d) => d.id == me().id).length,
      1,
    );

    blood.reviewDonor(me().id, DonorStatus.rejected);
    expect(me().canBeContacted, isFalse);
  });

  test('patient blood request: committee links donors, status follows', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final blood = c.read(bloodProvider.notifier);
    final id = blood.addRequest(
      patientName: 'Salim',
      requesterName: 'Nadia',
      relation: RequesterRelation.family,
      bloodType: 'B+',
      units: 1,
      hospital: 'CHU',
      city: 'Oran',
      urgent: false,
      phone: '0550 11 22 33',
      contact: ContactMethod.call,
    );
    BloodRequest req() => c.read(bloodProvider).request(id)!;
    expect(req().status, BloodRequestStatus.submitted);

    blood.setStatus(id, BloodRequestStatus.inProgress);
    blood.assignDonor(id, 'bd4');
    blood.assignDonor(id, 'bd4');
    expect(req().assignedDonorIds, ['bd4']);
    expect(req().status, BloodRequestStatus.matched);

    blood.unassignDonor(id, 'bd4');
    expect(req().status, BloodRequestStatus.inProgress);

    blood.markFulfilled(id);
    expect(req().isOpen, isFalse);
  });
}
