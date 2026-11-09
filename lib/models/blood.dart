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

/// Who the donor is: a registered patient or doctor, or someone without an
/// account who registered from the "Blood donor" entry.
enum DonorKind { patient, doctor, other }

/// Review of a donor registration by the donation committee.
enum DonorStatus { pending, approved, rejected }

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

  /// Platform account of the donor (patient or doctor).
  final String userId;
  final String name;
  final String bloodType;
  final String city;
  final String phone;
  final DonorKind kind;
  final DonorStatus status;

  /// The donor can be called at the moment (set by the donor).
  final bool available;

  /// The donor accepted that the committee contacts them and shares the
  /// number with a compatible patient when needed.
  final bool shareContact;
  final DateTime registeredAt;

  BloodDonor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.city,
    required this.phone,
    this.userId = '',
    this.kind = DonorKind.patient,
    this.status = DonorStatus.approved,
    this.available = true,
    this.shareContact = true,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime(2026);

  String get code => _code('D', id);

  bool get isApproved => status == DonorStatus.approved;

  /// Approved donor the committee can call on right now.
  bool get canBeContacted => isApproved && available && shareContact;

  /// The committee always calls (no other contact preference is asked).
  ContactMethod get contact => ContactMethod.call;

  BloodDonor copyWith({bool? available, DonorStatus? status}) => BloodDonor(
    id: id,
    userId: userId,
    name: name,
    bloodType: bloodType,
    city: city,
    phone: phone,
    kind: kind,
    status: status ?? this.status,
    available: available ?? this.available,
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
/// then same city, then exact blood type. Only approved, available donors.
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
