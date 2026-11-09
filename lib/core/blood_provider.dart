import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/blood.dart';

class BloodState {
  final List<BloodRequest> requests;
  final List<BloodDonor> donors;

  /// Donor profile of the current user, if they registered as a donor.
  final String? myDonorId;

  const BloodState({
    required this.requests,
    required this.donors,
    this.myDonorId,
  });

  BloodDonor? get myDonor {
    for (final d in donors) {
      if (d.id == myDonorId) return d;
    }
    return null;
  }

  BloodRequest? request(String id) {
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  BloodDonor? donor(String id) {
    for (final d in donors) {
      if (d.id == id) return d;
    }
    return null;
  }

  BloodState copyWith({
    List<BloodRequest>? requests,
    List<BloodDonor>? donors,
    String? myDonorId,
  }) => BloodState(
    requests: requests ?? this.requests,
    donors: donors ?? this.donors,
    myDonorId: myDonorId ?? this.myDonorId,
  );
}

class BloodNotifier extends Notifier<BloodState> {
  @override
  BloodState build() => BloodState(
    requests: MockData.bloodRequests(),
    donors: MockData.bloodDonors(),
  );

  String addRequest({
    required String patientName,
    required String bloodType,
    required int units,
    required String hospital,
    required String city,
    required bool urgent,
    required String phone,
    required ContactMethod contact,
    String note = '',
  }) {
    final id = 'b${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      requests: [
        BloodRequest(
          id: id,
          requesterId: MockData.currentPatientId,
          patientName: patientName.trim(),
          bloodType: bloodType,
          units: units,
          hospital: hospital.trim(),
          city: city.trim(),
          urgent: urgent,
          phone: phone.trim(),
          contact: contact,
          note: note.trim(),
          createdAt: DateTime.now(),
        ),
        ...state.requests,
      ],
    );
    return id;
  }

  /// Creates or updates the current user's donor profile.
  void saveMyDonor({
    required String name,
    required String bloodType,
    required String city,
    required String phone,
    required ContactMethod contact,
    required bool available,
    required bool shareContact,
    DateTime? lastDonation,
  }) {
    final id = state.myDonorId ?? 'donor_me';
    final me = BloodDonor(
      id: id,
      name: name.trim(),
      bloodType: bloodType,
      city: city.trim(),
      phone: phone.trim(),
      contact: contact,
      available: available,
      shareContact: shareContact,
      lastDonation: lastDonation,
    );
    state = state.copyWith(
      donors: [me, ...state.donors.where((d) => d.id != id)],
      myDonorId: id,
    );
  }

  void setMyAvailability(bool available) {
    final id = state.myDonorId;
    if (id == null) return;
    state = state.copyWith(
      donors: [
        for (final d in state.donors)
          d.id == id ? d.copyWith(available: available) : d,
      ],
    );
  }

  /// The current donor answers "I can donate" to a request.
  void volunteer(String requestId) {
    final me = state.myDonorId;
    if (me == null) return;
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          if (r.id == requestId && !r.volunteerIds.contains(me))
            r.copyWith(volunteerIds: [...r.volunteerIds, me])
          else
            r,
      ],
    );
  }

  void markFulfilled(String requestId) {
    state = state.copyWith(
      requests: [
        for (final r in state.requests)
          r.id == requestId
              ? r.copyWith(status: BloodRequestStatus.fulfilled)
              : r,
      ],
    );
  }
}

final bloodProvider = NotifierProvider<BloodNotifier, BloodState>(
  BloodNotifier.new,
);
