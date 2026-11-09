/// Blood donation: requests from people in need, registered donors, and the
/// red-cell compatibility rules used to match them.
library;

const bloodTypes = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];

/// Red-cell compatibility: can a donor of [donor] give to a [recipient]?
///
/// O- is the universal donor, AB+ the universal recipient. The Rh- recipients
/// can only receive Rh- blood.
bool canDonate(String donor, String recipient) {
  const receivesFrom = {
    'O-': ['O-'],
    'O+': ['O-', 'O+'],
    'A-': ['O-', 'A-'],
    'A+': ['O-', 'O+', 'A-', 'A+'],
    'B-': ['O-', 'B-'],
    'B+': ['O-', 'O+', 'B-', 'B+'],
    'AB-': ['O-', 'A-', 'B-', 'AB-'],
    'AB+': bloodTypes,
  };
  return receivesFrom[recipient]?.contains(donor) ?? false;
}

/// Blood types that can give to [recipient].
List<String> compatibleDonorTypes(String recipient) => [
  for (final t in bloodTypes)
    if (canDonate(t, recipient)) t,
];

enum ContactMethod { call, whatsapp, sms }

enum BloodRequestStatus { open, fulfilled }

class BloodDonor {
  final String id;
  final String name;
  final String bloodType;
  final String city;
  final String phone;
  final ContactMethod contact;
  final bool available;
  final DateTime? lastDonation;

  /// The donor accepted that compatible people in need can see the number.
  final bool shareContact;

  const BloodDonor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.city,
    required this.phone,
    this.contact = ContactMethod.call,
    this.available = true,
    this.lastDonation,
    this.shareContact = true,
  });

  /// Whole blood: about 3 months between two donations.
  static const minInterval = Duration(days: 90);

  DateTime? get nextEligibleDate => lastDonation?.add(minInterval);

  bool get eligibleNow {
    final next = nextEligibleDate;
    return next == null || !next.isAfter(DateTime.now());
  }

  /// Donor who can be contacted right now.
  bool get canBeContacted => available && eligibleNow && shareContact;

  BloodDonor copyWith({bool? available}) => BloodDonor(
    id: id,
    name: name,
    bloodType: bloodType,
    city: city,
    phone: phone,
    contact: contact,
    available: available ?? this.available,
    lastDonation: lastDonation,
    shareContact: shareContact,
  );
}

class BloodRequest {
  final String id;
  final String requesterId;
  final String patientName;
  final String bloodType;
  final int units;
  final String hospital;
  final String city;
  final bool urgent;
  final String phone;
  final ContactMethod contact;
  final String note;
  final DateTime createdAt;
  final BloodRequestStatus status;

  /// Donors who answered "I can donate".
  final List<String> volunteerIds;

  const BloodRequest({
    required this.id,
    required this.requesterId,
    required this.patientName,
    required this.bloodType,
    required this.units,
    required this.hospital,
    required this.city,
    required this.phone,
    required this.createdAt,
    this.urgent = false,
    this.contact = ContactMethod.call,
    this.note = '',
    this.status = BloodRequestStatus.open,
    this.volunteerIds = const [],
  });

  bool get isOpen => status == BloodRequestStatus.open;

  BloodRequest copyWith({
    BloodRequestStatus? status,
    List<String>? volunteerIds,
  }) => BloodRequest(
    id: id,
    requesterId: requesterId,
    patientName: patientName,
    bloodType: bloodType,
    units: units,
    hospital: hospital,
    city: city,
    phone: phone,
    createdAt: createdAt,
    urgent: urgent,
    contact: contact,
    note: note,
    status: status ?? this.status,
    volunteerIds: volunteerIds ?? this.volunteerIds,
  );
}

String _norm(String s) => s.trim().toLowerCase();

/// Donors who can give to [request], best first: same city, then exact blood
/// type, then the others. Unavailable / not yet eligible donors are excluded.
List<BloodDonor> matchDonors(BloodRequest request, List<BloodDonor> donors) {
  final list = donors
      .where(
        (d) => d.canBeContacted && canDonate(d.bloodType, request.bloodType),
      )
      .toList();
  int score(BloodDonor d) =>
      (_norm(d.city) == _norm(request.city) ? 2 : 0) +
      (d.bloodType == request.bloodType ? 1 : 0);
  list.sort((a, b) => score(b).compareTo(score(a)));
  return list;
}

/// Open requests that [donor] can answer: urgent first, then same city.
List<BloodRequest> matchRequests(
  BloodDonor donor,
  List<BloodRequest> requests,
) {
  final list = requests
      .where((r) => r.isOpen && canDonate(donor.bloodType, r.bloodType))
      .toList();
  int score(BloodRequest r) =>
      (r.urgent ? 2 : 0) + (_norm(r.city) == _norm(donor.city) ? 1 : 0);
  list.sort((a, b) {
    final s = score(b).compareTo(score(a));
    return s != 0 ? s : b.createdAt.compareTo(a.createdAt);
  });
  return list;
}
