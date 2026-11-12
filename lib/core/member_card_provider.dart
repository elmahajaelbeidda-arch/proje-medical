import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/facility.dart';
import '../models/member_card.dart';
import '../models/models.dart';
import '../models/registration.dart';
import 'facility_provider.dart';
import 'providers.dart';

/// Card numbers suspended by the association (misuse, duplicate account...).
class SuspendedCardsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void suspend(String number) => state = {...state, number};
  void reactivate(String number) => state = {...state}..remove(number);
}

final suspendedCardsProvider =
    NotifierProvider<SuspendedCardsNotifier, Set<String>>(
      SuspendedCardsNotifier.new,
    );

/// Every approved patient, doctor and facility has a card.
final memberCardsProvider = Provider<List<MemberCard>>((ref) {
  final suspended = ref.watch(suspendedCardsProvider);
  final cards = <MemberCard>[];

  for (final r in ref.watch(registrationsProvider)) {
    if (r.status != ReviewStatus.approved) continue;
    final kind = r.isDoctor ? MemberKind.doctor : MemberKind.patient;
    final issued = r.reviewedAt ?? r.createdAt;
    final number = memberNumber(kind, r.id, issued);
    cards.add(
      MemberCard(
        number: number,
        kind: kind,
        holderId: r.id,
        name: r.name,
        idValue: r.idNumber,
        detailKey: r.isDoctor && r.specialtyId != null
            ? Specialty.byId(r.specialtyId!).key
            : 'role_patient',
        city: _cityOf(r),
        issuedAt: issued,
        suspended: suspended.contains(number),
      ),
    );
  }

  for (final f in ref.watch(facilityProvider).facilities) {
    if (!f.isApproved) continue;
    final issued =
        f.history
            .where((e) => e.status == FacilityStatus.approved)
            .map((e) => e.at)
            .lastOrNull ??
        f.createdAt;
    final number = memberNumber(MemberKind.facility, f.id, issued);
    cards.add(
      MemberCard(
        number: number,
        kind: MemberKind.facility,
        holderId: f.id,
        name: f.name,
        idValue: f.licenseNumber,
        detailKey: 'ft_${f.type.name}',
        city: f.city,
        issuedAt: issued,
        suspended: suspended.contains(number),
      ),
    );
  }
  return cards;
});

String _cityOf(Registration r) {
  for (final d in MockData.doctors) {
    if (d.name == r.name) return d.city;
  }
  return '';
}

/// Card of the signed-in user (patient, doctor or facility), if approved.
final myMemberCardProvider = Provider<MemberCard?>((ref) {
  final cards = ref.watch(memberCardsProvider);
  final facility = ref.watch(facilitySessionProvider);
  final auth = ref.watch(authProvider);
  String? holder;
  if (facility != null) {
    holder = facility;
  } else if (auth.loggedIn && !auth.isCommittee) {
    holder =
        auth.registrationId ??
        MockData.demoRegistrationId(
          doctor: auth.isDoctor,
          psych: auth.isPsychDoctor,
        );
  }
  if (holder == null) return null;
  for (final c in cards) {
    if (c.holderId == holder) return c;
  }
  return null;
});
