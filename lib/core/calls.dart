import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart' show CallKind;
import 'admin_provider.dart';

export '../models/models.dart' show CallKind;

// ---------------------------------------------------------------------------
// Voice and video calls between a doctor and a patient (Jitsi Meet).
//
// Every consultation / psych session gets its own private room, named with
// a long random code that only the two parties' screens know. The call
// itself runs on the Jitsi server set by the association (default: the
// public meet.jit.si). Nothing of the call is recorded: the app only keeps
// when a call was started, by whom, and of which kind.
// ---------------------------------------------------------------------------

/// Server used when the dashboard sets none (build option CALL_SERVER).
const defaultCallServer = String.fromEnvironment(
  'CALL_SERVER',
  defaultValue: 'https://meet.jit.si',
);

class CallRecord {
  /// Consultation or psych session id.
  final String contextId;
  final CallKind kind;
  final bool byDoctor;
  final DateTime at;
  const CallRecord(this.contextId, this.kind, this.byDoctor, this.at);
}

class CallsState {
  /// Context id → private room code.
  final Map<String, String> rooms;
  final List<CallRecord> log;
  const CallsState({this.rooms = const {}, this.log = const []});

  CallRecord? lastCall(String contextId) {
    for (final r in log.reversed) {
      if (r.contextId == contextId) return r;
    }
    return null;
  }
}

/// How long a patient can join after the doctor started a call.
const callJoinWindow = Duration(minutes: 60);

String newRoomCode([math.Random? rnd]) {
  final r = rnd ?? math.Random.secure();
  const chars = 'abcdefghijkmnpqrstuvwxyz23456789';
  return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
}

class CallsNotifier extends Notifier<CallsState> {
  @override
  CallsState build() => const CallsState();

  /// The private room of a consultation (created on first use).
  String roomFor(String contextId) {
    final existing = state.rooms[contextId];
    if (existing != null) return existing;
    final code = 'shifa-${newRoomCode()}';
    state = CallsState(
      rooms: {...state.rooms, contextId: code},
      log: state.log,
    );
    return code;
  }

  CallRecord start(String contextId, CallKind kind, {required bool byDoctor}) {
    roomFor(contextId);
    final r = CallRecord(contextId, kind, byDoctor, DateTime.now());
    state = CallsState(rooms: state.rooms, log: [...state.log, r]);
    return r;
  }

  /// The doctor started a call recently: the patient may join it.
  bool patientCanJoin(String contextId, {DateTime? now}) {
    final last = state.lastCall(contextId);
    if (last == null || !last.byDoctor) return false;
    return (now ?? DateTime.now()).difference(last.at) <= callJoinWindow;
  }
}

final callsProvider = NotifierProvider<CallsNotifier, CallsState>(
  CallsNotifier.new,
);

/// Jitsi server in use (dashboard setting, else the build default).
final callServerProvider = Provider<String>((ref) {
  final s = ref.watch(appSettingsProvider).callServer.trim();
  return s.isEmpty ? defaultCallServer : s;
});

/// Address that opens the room directly (no pre-join screen), with the
/// camera off for a voice call.
Uri callUri({
  required String server,
  required String room,
  required CallKind kind,
  required String displayName,
}) {
  final base = server.endsWith('/')
      ? server.substring(0, server.length - 1)
      : server;
  final voice = kind == CallKind.voice;
  final name = Uri.encodeComponent('"${displayName.replaceAll('"', '')}"');
  final config = [
    'config.prejoinPageEnabled=false',
    'config.startWithVideoMuted=$voice',
    'config.startAudioOnly=$voice',
    'config.disableDeepLinking=false',
    'userInfo.displayName=$name',
  ].join('&');
  return Uri.parse('$base/$room#$config');
}
