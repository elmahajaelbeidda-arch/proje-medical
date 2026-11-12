import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/admin.dart';
import '../models/blood.dart';
import '../models/facility.dart';
import '../models/models.dart';
import '../models/psych.dart';
import '../models/registration.dart';
import 'admin_provider.dart';
import 'blood_provider.dart';
import 'facility_provider.dart';
import 'providers.dart';
import 'psych_provider.dart';
import 'summons_provider.dart';

enum CaseKind { consultation, blood, referral }

/// One medical case as seen by the administration (consultation, blood
/// request or referral to a facility).
class AdminCase {
  final String id;
  final String code;
  final CaseKind kind;
  final String patientName;

  /// Short need: specialty, blood type, service...
  final String need;

  /// Medical details (only with the medical records permission).
  final String details;
  final CaseStage stage;
  final String assignee;
  final bool urgent;
  final DateTime createdAt;
  final CaseDecision? decision;

  const AdminCase({
    required this.id,
    required this.code,
    required this.kind,
    required this.patientName,
    required this.need,
    required this.details,
    required this.stage,
    required this.assignee,
    required this.createdAt,
    this.urgent = false,
    this.decision,
  });
}

String consultationCode(String id) {
  var d = id.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty) d = '0';
  if (d.length > 4) d = d.substring(d.length - 4);
  return 'C-${d.padLeft(3, '0')}';
}

final adminCasesProvider = Provider<List<AdminCase>>((ref) {
  final decisions = ref.watch(adminProvider.select((s) => s.caseDecisions));
  final cases = <AdminCase>[];

  AdminCase withDecision(AdminCase c) {
    final d = decisions[c.id];
    if (d == null) return c;
    return AdminCase(
      id: c.id,
      code: c.code,
      kind: c.kind,
      patientName: c.patientName,
      need: c.need,
      details: c.details,
      stage: d.stage,
      assignee: c.assignee,
      urgent: c.urgent,
      createdAt: c.createdAt,
      decision: d,
    );
  }

  for (final c in ref.watch(consultationsProvider)) {
    cases.add(
      withDecision(
        AdminCase(
          id: c.id,
          code: consultationCode(c.id),
          kind: CaseKind.consultation,
          patientName: c.patientName,
          need: 'sp_${c.specialtyId}|type_${c.type.name}',
          details: c.symptoms,
          stage: switch (c.status) {
            ConsultationStatus.pending => CaseStage.pending,
            ConsultationStatus.accepted => CaseStage.accepted,
            _ => CaseStage.completed,
          },
          assignee: MockData.doctorById(c.doctorId)?.name ?? '',
          urgent: c.urgency == Urgency.urgent,
          createdAt: c.createdAt,
        ),
      ),
    );
  }
  for (final r in ref.watch(bloodProvider).requests) {
    cases.add(
      withDecision(
        AdminCase(
          id: r.id,
          code: r.code,
          kind: CaseKind.blood,
          patientName: r.patientName,
          need: '${r.bloodType} × ${r.units}',
          details: '${r.hospital} — ${r.note}',
          stage: switch (r.status) {
            BloodRequestStatus.submitted => CaseStage.pending,
            BloodRequestStatus.fulfilled => CaseStage.completed,
            BloodRequestStatus.cancelled => CaseStage.rejected,
            _ => CaseStage.accepted,
          },
          assignee: r.hospital,
          urgent: r.urgent,
          createdAt: r.createdAt,
        ),
      ),
    );
  }
  final facilities = ref.watch(facilityProvider);
  for (final r in facilities.referrals) {
    cases.add(
      withDecision(
        AdminCase(
          id: r.id,
          code: r.code,
          kind: CaseKind.referral,
          patientName: r.patientName,
          need: r.service,
          details: '${r.notes} ${r.facilityNote}'.trim(),
          stage: switch (r.status) {
            ReferralStatus.sent => CaseStage.pending,
            ReferralStatus.completed => CaseStage.completed,
            ReferralStatus.declined => CaseStage.rejected,
            _ => CaseStage.accepted,
          },
          assignee: facilities.facility(r.facilityId)?.name ?? '',
          urgent: r.urgent,
          createdAt: r.createdAt,
        ),
      ),
    );
  }
  cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return cases;
});

/// Activity and commitment of a volunteer doctor.
class DoctorActivity {
  final Doctor doctor;
  final int accepted;
  final int answered;

  /// Accepted but still without an answer after 48 hours.
  final int late;
  final double? patientRating;
  final int summons;

  /// Psychological sessions: counts only (content stays confidential).
  final int psychSessions;
  final DoctorEvaluation? evaluation;

  const DoctorActivity({
    required this.doctor,
    required this.accepted,
    required this.answered,
    required this.late,
    required this.patientRating,
    required this.summons,
    required this.psychSessions,
    this.evaluation,
  });

  /// 0..100: answered share, minus late cases.
  int get commitment {
    if (accepted == 0) return 100;
    final v = (answered / accepted * 100) - late * 15;
    return v.clamp(0, 100).round();
  }
}

final doctorActivityProvider = Provider<List<DoctorActivity>>((ref) {
  final consultations = ref.watch(consultationsProvider);
  final psych = ref.watch(psychProvider);
  final summons = ref.watch(summonsProvider);
  final evaluations = ref.watch(adminProvider.select((s) => s.evaluations));
  final now = DateTime.now();
  return [
    for (final d in MockData.doctors)
      () {
        final mine = consultations.where((c) => c.doctorId == d.id).toList();
        final rated = mine.where((c) => c.rating != null).toList();
        return DoctorActivity(
          doctor: d,
          accepted: mine.length,
          answered: mine
              .where((c) => c.status != ConsultationStatus.accepted)
              .length,
          late: mine
              .where(
                (c) =>
                    c.status == ConsultationStatus.accepted &&
                    now.difference(c.createdAt).inHours > 48,
              )
              .length,
          patientRating: rated.isEmpty
              ? null
              : rated.fold<int>(0, (s, c) => s + c.rating!) / rated.length,
          summons: summons.where((s) => s.issuerId == d.id).length,
          psychSessions: psych
              .where(
                (s) => s.doctorId == d.id && s.status == PsychStatus.completed,
              )
              .length,
          evaluation: evaluations[d.id],
        );
      }(),
  ];
});

/// Approved volunteer doctors: approved sign-ups plus the doctors already
/// active in the app (same person counted once).
final approvedDoctorsCountProvider = Provider<int>((ref) {
  final names = {
    for (final d in MockData.doctors) d.name,
    for (final r in ref.watch(registrationsProvider))
      if (r.isDoctor && r.status == ReviewStatus.approved) r.name,
  };
  return names.length;
});
