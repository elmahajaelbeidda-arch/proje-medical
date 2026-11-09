/// Blood donation: requests from people in need, registered donors, and the
/// red-cell compatibility rules the committee uses to link them.
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

/// Who the donor is on the platform.
enum DonorKind { patient, doctor, other }

/// Who posted a request, relative to the patient.
enum RequesterRelation { self, family, other }

/// Request life cycle, handled by the donation committee.
enum BloodRequestStatus {
  submitted, // new, not yet reviewed
  inProgress, // the committee is looking for donors
  matched, // donors linked to the request
  fulfilled, // blood secured
  cancelled,
}

/// Short reference shown instead of personal data, e.g. "D-007" / "R-012".
String _code(String prefix, String id) {
  var digits = id.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) digits = '0';
  if (digits.length > 4) digits = digits.substring(digits.length - 4);
  return '$prefix-${digits.padLeft(3, '0')}';
}

/// "0550 12 34 56" -> "0550 •• •• 56" (only the committee sees full numbers).
String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6) return '•••';
  return '${digits.substring(0, 4)} •• •• ${digits.substring(digits.length - 2)}';
}

/// "عائشة بن موسى" -> "ع. ب. م."
String maskName(String name) => name
    .split(RegExp(r'\s+'))
    .where((p) => p.isNotEmpty)
    .map((p) => '${p.characters.first}.')
    .join(' ');

extension on String {
  Iterable<String> get characters => runes.map(String.fromCharCode);
}

class BloodDonor {
  final String id;
  final String name;
  final String bloodType;
  final String city;
  final String phone;
  final ContactMethod contact;
  final DonorKind kind;
  final bool male;
  final int age;
  final bool available;
  final DateTime? lastDonation;
  final DateTime registeredAt;

  /// The donor accepted that the committee shares the number with a
  /// compatible person in need.
  final bool shareContact;

  BloodDonor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.city,
    required this.phone,
    this.contact = ContactMethod.call,
    this.kind = DonorKind.other,
    this.male = true,
    this.age = 30,
    this.available = true,
    this.lastDonation,
    this.shareContact = true,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime(2026);

  String get code => _code('D', id);

  /// Usual donor age range.
  static const minAge = 18;
  static const maxAge = 65;

  /// Whole blood: about 3 months between two donations.
  static const minInterval = Duration(days: 90);

  DateTime? get nextEligibleDate => lastDonation?.add(minInterval);

  bool get eligibleNow {
    final next = nextEligibleDate;
    return next == null || !next.isAfter(DateTime.now());
  }

  /// Donor the committee can call on right now.
  bool get canBeContacted =>
      available &&
      eligibleNow &&
      shareContact &&
      age >= minAge &&
      age <= maxAge;

  BloodDonor copyWith({bool? available}) => BloodDonor(
    id: id,
    name: name,
    bloodType: bloodType,
    city: city,
    phone: phone,
    contact: contact,
    kind: kind,
    male: male,
    age: age,
    available: available ?? this.available,
    lastDonation: lastDonation,
    shareContact: shareContact,
    registeredAt: registeredAt,
  );
}

class BloodRequest {
  final String id;
  final String requesterId;
  final String patientName;

  /// Person who posted the request (the patient or a relative).
  final String requesterName;
  final RequesterRelation relation;
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

  /// Donors who answered "I can donate" (the committee confirms them).
  final List<String> volunteerIds;

  /// Donors the committee linked to this request.
  final List<String> assignedDonorIds;

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
    String? requesterName,
    this.relation = RequesterRelation.self,
    this.urgent = false,
    this.contact = ContactMethod.call,
    this.note = '',
    this.status = BloodRequestStatus.submitted,
    this.volunteerIds = const [],
    this.assignedDonorIds = const [],
  }) : requesterName = requesterName ?? patientName;

  String get code => _code('R', id);

  bool get isOpen =>
      status != BloodRequestStatus.fulfilled &&
      status != BloodRequestStatus.cancelled;

  BloodRequest copyWith({
    BloodRequestStatus? status,
    List<String>? volunteerIds,
    List<String>? assignedDonorIds,
  }) => BloodRequest(
    id: id,
    requesterId: requesterId,
    patientName: patientName,
    requesterName: requesterName,
    relation: relation,
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
    assignedDonorIds: assignedDonorIds ?? this.assignedDonorIds,
  );
}

String _norm(String s) => s.trim().toLowerCase();

/// Donors who can give to [request], best first: volunteers for this request,
/// then same city, then exact blood type. Unavailable / not yet eligible
/// donors are excluded.
List<BloodDonor> matchDonors(BloodRequest request, List<BloodDonor> donors) {
  final list = donors
      .where(
        (d) => d.canBeContacted && canDonate(d.bloodType, request.bloodType),
      )
      .toList();
  int score(BloodDonor d) =>
      (request.volunteerIds.contains(d.id) ? 4 : 0) +
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
