/// «خريطة المرضى»: aid requests with the patient's location, reviewed on a
/// map by the medical aid committee. Mirrors supabase/migrations/0001.
library;

enum AidUrgency {
  urgent('urgent'), // عاجل
  medium('medium'), // متوسط
  normal('normal'); // عادي

  const AidUrgency(this.db);
  final String db;
  static AidUrgency fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => normal);
}

enum AidStatus {
  newRequest('new'), // جديد
  verifying('verifying'), // قيد التحقق
  verified('verified'), // تم التحقق
  helped('helped'), // تمت المساعدة
  closed('closed'); // مغلق

  const AidStatus(this.db);
  final String db;
  static AidStatus fromDb(String v) =>
      values.firstWhere((e) => e.db == v, orElse: () => newRequest);
}

enum CommitteeRole { member, supervisor }

/// Default map centre: Nouakchott.
const nouakchottLat = 18.0735;
const nouakchottLng = -15.9582;

class AidRequest {
  final String id;
  final String userId;
  final String patientName;
  final String phone;
  final double latitude;
  final double longitude;
  final String addressNote;
  final String conditionDescription;
  final AidUrgency urgency;
  final AidStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final bool consentGiven;
  final DateTime createdAt;

  const AidRequest({
    required this.id,
    required this.userId,
    required this.patientName,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.conditionDescription,
    required this.createdAt,
    this.addressNote = '',
    this.urgency = AidUrgency.normal,
    this.status = AidStatus.newRequest,
    this.verifiedBy,
    this.verifiedAt,
    this.consentGiven = true,
  });

  bool get isOpen => status != AidStatus.closed;

  factory AidRequest.fromMap(Map<String, dynamic> m) => AidRequest(
    id: m['id'] as String,
    userId: (m['user_id'] ?? '') as String,
    patientName: m['patient_name'] as String,
    phone: m['phone'] as String,
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    addressNote: (m['address_note'] ?? '') as String,
    conditionDescription: m['condition_description'] as String,
    urgency: AidUrgency.fromDb(m['urgency'] as String),
    status: AidStatus.fromDb(m['status'] as String),
    verifiedBy: m['verified_by'] as String?,
    verifiedAt: m['verified_at'] == null
        ? null
        : DateTime.parse(m['verified_at'] as String).toLocal(),
    consentGiven: (m['consent_given'] ?? false) as bool,
    createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
  );

  AidRequest copyWith({AidStatus? status, String? verifiedBy}) => AidRequest(
    id: id,
    userId: userId,
    patientName: patientName,
    phone: phone,
    latitude: latitude,
    longitude: longitude,
    addressNote: addressNote,
    conditionDescription: conditionDescription,
    urgency: urgency,
    status: status ?? this.status,
    verifiedBy: status == AidStatus.verified ? verifiedBy : this.verifiedBy,
    verifiedAt: status == AidStatus.verified ? DateTime.now() : verifiedAt,
    consentGiven: consentGiven,
    createdAt: createdAt,
  );
}

/// Data entered by the patient (or a relative) in the request form.
class AidRequestDraft {
  final String patientName;
  final String phone;
  final double latitude;
  final double longitude;
  final String addressNote;
  final String conditionDescription;
  final AidUrgency urgency;
  final bool consentGiven;

  const AidRequestDraft({
    required this.patientName,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.addressNote,
    required this.conditionDescription,
    required this.urgency,
    required this.consentGiven,
  });

  /// Row for `insert` (status, user_id and dates are set by the database).
  Map<String, dynamic> toInsertMap() => {
    'patient_name': patientName.trim(),
    'phone': phone.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'address_note': addressNote.trim(),
    'condition_description': conditionDescription.trim(),
    'urgency': urgency.db,
    'consent_given': consentGiven,
  };
}

class CommitteeMember {
  final String userId;
  final String name;
  final CommitteeRole role;
  const CommitteeMember({
    required this.userId,
    required this.name,
    required this.role,
  });

  factory CommitteeMember.fromMap(Map<String, dynamic> m) => CommitteeMember(
    userId: m['user_id'] as String,
    name: m['name'] as String,
    role: m['role'] == 'supervisor'
        ? CommitteeRole.supervisor
        : CommitteeRole.member,
  );
}
