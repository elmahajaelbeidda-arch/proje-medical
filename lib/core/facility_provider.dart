import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/facility.dart';
import '../models/models.dart';

class FacilityState {
  final List<MedicalFacility> facilities;
  final List<Referral> referrals;
  const FacilityState({required this.facilities, required this.referrals});

  MedicalFacility? facility(String? id) {
    for (final f in facilities) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<Referral> referralsOf(String facilityId) =>
      referrals.where((r) => r.facilityId == facilityId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  FacilityState copyWith({
    List<MedicalFacility>? facilities,
    List<Referral>? referrals,
  }) => FacilityState(
    facilities: facilities ?? this.facilities,
    referrals: referrals ?? this.referrals,
  );
}

class FacilityNotifier extends Notifier<FacilityState> {
  @override
  FacilityState build() =>
      FacilityState(facilities: _seedFacilities(), referrals: _seedReferrals());

  /// New facility: waits for the association's approval.
  String register({
    required FacilityType type,
    required String name,
    required String managerName,
    required String licenseNumber,
    required String city,
    required String address,
    required String phone,
    String email = '',
    List<String> specialtyIds = const [],
    List<String> services = const [],
    required Set<CooperationType> cooperation,
    int? discountPercent,
    int? monthlyCapacity,
    String notes = '',
    Attachment? licenseDocument,
    List<Attachment> documents = const [],
  }) {
    final id = 'fac${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    state = state.copyWith(
      facilities: [
        MedicalFacility(
          id: id,
          type: type,
          name: name.trim(),
          managerName: managerName.trim(),
          licenseNumber: licenseNumber.trim(),
          city: city.trim(),
          address: address.trim(),
          phone: phone.trim(),
          email: email.trim(),
          specialtyIds: specialtyIds,
          services: [
            for (final s in services)
              if (s.trim().isNotEmpty) s.trim(),
          ],
          cooperation: cooperation,
          discountPercent: cooperation.contains(CooperationType.discounted)
              ? discountPercent
              : null,
          monthlyCapacity: cooperation.contains(CooperationType.referrals)
              ? monthlyCapacity
              : null,
          notes: notes.trim(),
          licenseDocument: licenseDocument,
          documents: documents,
          history: [
            FacilityEvent(FacilityStatus.pending, now, byFacility: true),
          ],
          createdAt: now,
        ),
        ...state.facilities,
      ],
    );
    return id;
  }

  MedicalFacility _update(
    String id,
    MedicalFacility Function(MedicalFacility f) change,
  ) {
    late MedicalFacility updated;
    state = state.copyWith(
      facilities: [
        for (final f in state.facilities)
          if (f.id == id) updated = change(f) else f,
      ],
    );
    return updated;
  }

  /// Association (step 6): tick a verification item.
  void toggleCheck(String id, VerificationCheck check) => _update(id, (f) {
    final checks = {...f.checks};
    checks.contains(check) ? checks.remove(check) : checks.add(check);
    return f.copyWith(checks: checks);
  });

  /// Association (steps 7-8): approve, reject or ask for missing documents.
  /// Rejection and requests need a reason; approval needs every check.
  void review(String id, FacilityStatus decision, {String note = ''}) {
    final f = state.facility(id);
    if (f == null) throw StateError('unknown facility');
    if (decision == FacilityStatus.pending) {
      throw ArgumentError('pending is not a decision');
    }
    if (decision != FacilityStatus.approved && note.trim().isEmpty) {
      throw ArgumentError('a reason is required');
    }
    if (decision == FacilityStatus.approved && !f.isVerified) {
      throw StateError('verification not complete');
    }
    _update(
      id,
      (f) => f.copyWith(
        status: decision,
        approvalSeen: false,
        history: [
          ...f.history,
          FacilityEvent(decision, DateTime.now(), note: note.trim()),
        ],
      ),
    );
  }

  /// Facility: send the missing documents and resubmit the request.
  void resubmit(
    String id, {
    List<Attachment> documents = const [],
    String note = '',
  }) => _update(id, (f) {
    if (f.status != FacilityStatus.needsInfo) {
      throw StateError('nothing requested');
    }
    return f.copyWith(
      status: FacilityStatus.pending,
      documents: [...f.documents, ...documents],
      history: [
        ...f.history,
        FacilityEvent(
          FacilityStatus.pending,
          DateTime.now(),
          note: note.trim(),
          byFacility: true,
        ),
      ],
    );
  });

  /// Facility: approval notice read.
  void markApprovalSeen(String id) =>
      _update(id, (f) => f.copyWith(approvalSeen: true));

  /// Association: refer a patient to an approved facility.
  String refer({
    required String facilityId,
    required String patientName,
    required String patientRef,
    required String service,
    String notes = '',
    bool urgent = false,
  }) {
    final f = state.facility(facilityId);
    if (f == null || !f.isApproved) {
      throw StateError('facility not approved');
    }
    final id = 'ref${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      referrals: [
        Referral(
          id: id,
          facilityId: facilityId,
          patientName: patientName.trim(),
          patientRef: patientRef.trim(),
          service: service.trim(),
          notes: notes.trim(),
          urgent: urgent,
          createdAt: DateTime.now(),
        ),
        ...state.referrals,
      ],
    );
    return id;
  }

  /// Facility: move a referral forward (accept, start, complete, decline).
  void updateReferral(String id, ReferralStatus status, {String? note}) {
    state = state.copyWith(
      referrals: [
        for (final r in state.referrals)
          if (r.id == id) ...[
            if (!nextReferralSteps(r.status).contains(status))
              throw StateError('invalid step ${r.status} -> $status'),
            r.copyWith(status: status, facilityNote: note),
          ] else
            r,
      ],
    );
  }

  static List<MedicalFacility> _seedFacilities() {
    final now = DateTime.now();
    return [
      MedicalFacility(
        id: 'f1',
        type: FacilityType.hospital,
        name: 'مستشفى الأمل الخاص',
        managerName: 'د. محمد الأمين ولد أحمد',
        licenseNumber: 'MS-NKC-2019-114',
        city: 'نواكشوط',
        address: 'تفرغ زينة، شارع جمال عبد الناصر',
        phone: '45 25 10 10',
        email: 'contact@amal-hospital.mr',
        specialtyIds: const ['internal', 'pediatrics', 'gyneco', 'cardio'],
        services: const ['استشارات تخصصية', 'عمليات بسيطة', 'متابعة الحمل'],
        cooperation: const {CooperationType.free, CooperationType.referrals},
        monthlyCapacity: 20,
        status: FacilityStatus.approved,
        checks: VerificationCheck.values.toSet(),
        approvalSeen: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      MedicalFacility(
        id: 'f2',
        type: FacilityType.lab,
        name: 'مختبر الشفاء للتحاليل الطبية',
        managerName: 'أحمد سالم',
        licenseNumber: 'LAB-NKC-2021-032',
        city: 'نواكشوط',
        address: 'لكصر، قرب السوق المركزي',
        phone: '45 29 33 44',
        specialtyIds: const ['general', 'endo'],
        services: const ['تحليل الدم الشامل', 'السكر التراكمي', 'وظائف الكلى'],
        cooperation: const {
          CooperationType.discounted,
          CooperationType.referrals,
        },
        discountPercent: 50,
        monthlyCapacity: 40,
        status: FacilityStatus.approved,
        checks: VerificationCheck.values.toSet(),
        approvalSeen: true,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
      MedicalFacility(
        id: 'f3',
        type: FacilityType.pharmacy,
        name: 'صيدلية النور',
        managerName: 'فاطمة محمد',
        licenseNumber: 'PH-NDB-2020-007',
        city: 'نواذيبو',
        address: 'الحي الإداري',
        phone: '46 11 22 33',
        services: const ['أدوية الأمراض المزمنة', 'أدوية الأطفال'],
        cooperation: const {CooperationType.discounted},
        discountPercent: 30,
        status: FacilityStatus.approved,
        checks: VerificationCheck.values.toSet(),
        approvalSeen: true,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      MedicalFacility(
        id: 'f4',
        type: FacilityType.radiology,
        name: 'مركز التصوير الطبي الحديث',
        managerName: 'د. سيدي محمد',
        licenseNumber: 'RAD-NKC-2018-021',
        city: 'نواكشوط',
        address: 'دار النعيم',
        phone: '45 24 55 66',
        specialtyIds: const ['radiology'],
        services: const ['أشعة سينية', 'إيكوغرافيا', 'سكانر'],
        cooperation: const {CooperationType.free, CooperationType.referrals},
        monthlyCapacity: 10,
        status: FacilityStatus.approved,
        checks: VerificationCheck.values.toSet(),
        approvalSeen: true,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      MedicalFacility(
        id: 'f5',
        type: FacilityType.clinic,
        name: 'عيادة السلام',
        managerName: 'د. مريم عبد الله',
        licenseNumber: 'CL-ROS-2023-004',
        city: 'روصو',
        address: 'وسط المدينة',
        phone: '46 77 88 99',
        specialtyIds: const ['general', 'pediatrics'],
        services: const ['استشارات عامة', 'تطعيم الأطفال'],
        cooperation: const {CooperationType.free, CooperationType.referrals},
        monthlyCapacity: 15,
        licenseDocument: const Attachment(
          'رخصة_العيادة.pdf',
          AttachmentKind.pdf,
        ),
        documents: const [Attachment('السجل_التجاري.pdf', AttachmentKind.pdf)],
        checks: const {VerificationCheck.data},
        history: [
          FacilityEvent(
            FacilityStatus.pending,
            now.subtract(const Duration(hours: 5)),
            byFacility: true,
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      MedicalFacility(
        id: 'f6',
        type: FacilityType.lab,
        name: 'مختبر الرحمة',
        managerName: 'محمد فال',
        licenseNumber: 'LAB-KIF-2022-011',
        city: 'كيفة',
        address: 'قرب المستشفى الجهوي',
        phone: '46 55 44 33',
        services: const ['تحاليل الملاريا', 'فصيلة الدم'],
        cooperation: const {CooperationType.discounted},
        discountPercent: 25,
        status: FacilityStatus.needsInfo,
        checks: const {VerificationCheck.data, VerificationCheck.contact},
        history: [
          FacilityEvent(
            FacilityStatus.pending,
            now.subtract(const Duration(days: 3)),
            byFacility: true,
          ),
          FacilityEvent(
            FacilityStatus.needsInfo,
            now.subtract(const Duration(days: 1)),
            note: 'يرجى رفع صورة واضحة من الترخيص الرسمي ساري المفعول.',
          ),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static List<Referral> _seedReferrals() {
    final now = DateTime.now();
    return [
      Referral(
        id: 'ref1',
        facilityId: 'f1',
        patientName: 'خديجة محمد',
        patientRef: 'P-011',
        service: 'استشارة قلب وتخطيط',
        notes: 'مسنة، ضغط مرتفع وخفقان.',
        urgent: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Referral(
        id: 'ref2',
        facilityId: 'f1',
        patientName: 'سيدي أحمد',
        patientRef: 'P-012',
        service: 'متابعة طفل (حمى متكررة)',
        status: ReferralStatus.inProgress,
        facilityNote: 'موعد مع طبيب الأطفال يوم الأحد 10 صباحاً.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Referral(
        id: 'ref3',
        facilityId: 'f1',
        patientName: 'محمد الأمين',
        patientRef: 'P-013',
        service: 'فحص نظر',
        status: ReferralStatus.completed,
        facilityNote: 'تم الفحص وصرف نظارة.',
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      Referral(
        id: 'ref4',
        facilityId: 'f2',
        patientName: 'مريم عبد الله',
        patientRef: 'P-014',
        service: 'السكر التراكمي ووظائف الكلى',
        status: ReferralStatus.accepted,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Referral(
        id: 'ref5',
        facilityId: 'f4',
        patientName: 'عبد الرحمن',
        patientRef: 'P-015',
        service: 'أشعة سينية لليد',
        status: ReferralStatus.completed,
        facilityNote: 'كسر بسيط، تم إرسال الصور للجمعية.',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}

final facilityProvider = NotifierProvider<FacilityNotifier, FacilityState>(
  FacilityNotifier.new,
);

/// The medical facility signed in on this device (its own account).
class FacilitySessionNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void signIn(String facilityId) => state = facilityId;
  void signOut() => state = null;
}

final facilitySessionProvider =
    NotifierProvider<FacilitySessionNotifier, String?>(
      FacilitySessionNotifier.new,
    );

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Finds the facility whose phone and licence number match (demo login).
MedicalFacility? findFacilityAccount(
  FacilityState state,
  String phone,
  String license,
) {
  final p = _digits(phone);
  final l = license.trim().toUpperCase();
  if (p.isEmpty || l.isEmpty) return null;
  for (final f in state.facilities) {
    final fp = _digits(f.phone);
    final samePhone = fp == p || '222$fp' == p;
    if (samePhone && f.licenseNumber.toUpperCase() == l) return f;
  }
  return null;
}
