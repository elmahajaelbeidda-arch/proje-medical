import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/summons.dart';

class SummonsNotifier extends Notifier<List<Summons>> {
  int _seq = 0;

  @override
  List<Summons> build() => _seed();

  Summons? byId(String id) {
    for (final s in state) {
      if (s.id == id) return s;
    }
    return null;
  }

  Summons? bySource(String sourceId) {
    for (final s in state) {
      if (s.sourceId == sourceId) return s;
    }
    return null;
  }

  List<Summons> forPatient(String patientId) =>
      state.where((s) => s.patientId == patientId).toList()
        ..sort((a, b) => a.appointment.compareTo(b.appointment));

  /// Issues a card (or replaces the card of the same consultation/referral,
  /// e.g. when the appointment changes).
  String issue({
    required String patientId,
    required String patientName,
    String patientRef = '',
    required SummonsIssuer issuer,
    required String issuerId,
    required String issuerName,
    required String issuerDetailKey,
    required String issuerPhone,
    required String place,
    required String city,
    required DateTime appointment,
    String instructions = '',
    required String sourceId,
  }) {
    if (place.trim().isEmpty) throw ArgumentError('place is required');
    final id = 'cv${DateTime.now().millisecondsSinceEpoch}${_seq++}';
    state = [
      Summons(
        id: id,
        patientId: patientId,
        patientName: patientName.trim(),
        patientRef: patientRef.trim(),
        issuer: issuer,
        issuerId: issuerId,
        issuerName: issuerName,
        issuerDetailKey: issuerDetailKey,
        issuerPhone: issuerPhone,
        place: place.trim(),
        city: city.trim(),
        appointment: appointment,
        instructions: instructions.trim(),
        sourceId: sourceId,
        issuedAt: DateTime.now(),
      ),
      for (final s in state)
        if (s.sourceId != sourceId) s,
    ];
    return id;
  }

  static List<Summons> _seed() {
    final now = DateTime.now();
    final d = MockData.doctorById('d2')!;
    return [
      Summons(
        id: 'cv1001',
        patientId: MockData.currentPatientId,
        patientName: 'محمد الأمين',
        patientRef: 'P-001',
        issuer: SummonsIssuer.doctor,
        issuerId: d.id,
        issuerName: d.name,
        issuerDetailKey: 'sp_${d.specialtyId}',
        issuerPhone: '22 45 67 89',
        place: 'عيادة القلب، مستشفى الصداقة، الطابق الأول',
        city: d.city,
        appointment: DateTime(now.year, now.month, now.day + 3, 10, 30),
        instructions: 'إحضار تخطيط القلب السابق وقائمة الأدوية، والحضور قبل الموعد بـ 15 دقيقة.',
        sourceId: 'demo-summons',
        issuedAt: now.subtract(const Duration(hours: 20)),
      ),
    ];
  }
}

final summonsProvider = NotifierProvider<SummonsNotifier, List<Summons>>(
  SummonsNotifier.new,
);
