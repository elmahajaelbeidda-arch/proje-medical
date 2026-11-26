import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/models.dart' show CallKind;
import '../../widgets/brand.dart';

/// Ticket to the private room of a consultation (see 0008_calls.sql).
class CallTicket {
  final String url;
  final String token;
  const CallTicket(this.url, this.token);
}

enum CallTicketError { notConfigured, notAllowed, network }

Future<CallTicket> fetchCallTicket(String consultationId) async {
  try {
    final r = await Supabase.instance.client.rpc(
      'call_token',
      params: {'p_consultation': consultationId},
    );
    final j = r as Map<String, dynamic>;
    return CallTicket(j['url'] as String, j['token'] as String);
  } on PostgrestException catch (e) {
    throw e.message.contains('not configured')
        ? CallTicketError.notConfigured
        : CallTicketError.notAllowed;
  } catch (_) {
    throw CallTicketError.network;
  }
}

enum _Phase { connecting, waiting, inCall, ended, failed }

/// Voice or video call inside the app (LiveKit), in the app's colours.
class LiveCallScreen extends StatefulWidget {
  const LiveCallScreen({
    super.key,
    required this.consultationId,
    required this.kind,
    required this.otherName,
  });
  final String consultationId;
  final CallKind kind;
  final String otherName;

  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _events;
  _Phase _phase = _Phase.connecting;
  String? _errorKey;
  bool _muted = false;
  bool _cameraOff = false;
  bool _speaker = true;
  bool _front = true;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  bool get _video => widget.kind == CallKind.video;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Technical reason of a failure (small, to help find the cause).
  String? _detail;

  /// The browser blocked the sound until a tap (Safari): button shown.
  bool _needsAudioTap = false;

  /// Microphone or camera refused: the call goes on, a notice is shown.
  String? _warningKey;

  Future<void> _start() async {
    // 1. Ticket from the server.
    final CallTicket ticket;
    try {
      ticket = await fetchCallTicket(widget.consultationId);
    } on CallTicketError catch (e) {
      _fail(switch (e) {
        CallTicketError.notConfigured => 'lc_not_configured',
        CallTicketError.notAllowed => 'lc_not_allowed',
        CallTicketError.network => 'lc_network',
      });
      return;
    }
    // 2. Join the room.
    final room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
    _room = room;
    room.addListener(_onRoomChanged);
    _events = room.createListener()
      ..on<RoomDisconnectedEvent>((_) => _finish())
      ..on<ParticipantDisconnectedEvent>((_) {
        if (room.remoteParticipants.isEmpty && _phase == _Phase.inCall) {
          _finish();
        }
      })
      ..on<AudioPlaybackStatusChanged>((e) {
        if (mounted) setState(() => _needsAudioTap = !e.isPlaying);
      });
    try {
      await room.connect(ticket.url, ticket.token);
    } catch (e) {
      _detail = e.toString();
      _fail('lc_connect_failed');
      return;
    }
    // 3. Microphone, then camera: a refusal does not end the call.
    try {
      await room.localParticipant?.setMicrophoneEnabled(true);
    } catch (e) {
      _detail = e.toString();
      _muted = true;
      _warningKey = 'lc_mic_denied';
    }
    if (_video) {
      try {
        await room.localParticipant?.setCameraEnabled(true);
      } catch (e) {
        _detail = e.toString();
        _cameraOff = true;
        _warningKey ??= 'lc_camera_denied';
      }
    }
    if (!kIsWeb) {
      try {
        await AudioManager.instance.setSpeakerOutputPreferred(_speaker);
      } catch (_) {}
    }
    if (mounted) setState(() => _needsAudioTap = !room.canPlaybackAudio);
    _onRoomChanged();
  }

  void _onRoomChanged() {
    if (!mounted || _phase == _Phase.ended || _phase == _Phase.failed) return;
    final other = _room?.remoteParticipants.isNotEmpty ?? false;
    final next = other ? _Phase.inCall : _Phase.waiting;
    if (next == _Phase.inCall && _clock == null) {
      HapticFeedback.mediumImpact();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
    setState(() => _phase = next);
  }

  void _fail(String key) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.failed;
      _errorKey = key;
    });
  }

  Future<void> _finish() async {
    if (_phase == _Phase.ended) return;
    _clock?.cancel();
    if (mounted) setState(() => _phase = _Phase.ended);
    await _room?.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && context.canPop()) context.pop();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _events?.dispose();
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _room?.localParticipant?.setMicrophoneEnabled(!_muted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraOff = !_cameraOff);
    await _room?.localParticipant?.setCameraEnabled(!_cameraOff);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _speaker = !_speaker);
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_speaker);
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    final track = _localVideo;
    if (track == null) return;
    _front = !_front;
    try {
      await track.setCameraPosition(
        _front ? CameraPosition.front : CameraPosition.back,
      );
    } catch (_) {}
  }

  VideoTrack? get _remoteVideo {
    final people = _room?.remoteParticipants.values;
    if (people == null) return null;
    for (final p in people) {
      for (final pub in p.videoTrackPublications) {
        final t = pub.track;
        if (pub.subscribed && !pub.muted && t != null) return t;
      }
    }
    return null;
  }

  LocalVideoTrack? get _localVideo {
    final pubs = _room?.localParticipant?.videoTrackPublications ?? const [];
    for (final p in pubs) {
      if (p.track != null && !p.muted) return p.track;
    }
    return null;
  }

  String _statusText(BuildContext context) => switch (_phase) {
    _Phase.connecting => context.tr('lc_connecting'),
    _Phase.waiting => context.tr('lc_waiting'),
    _Phase.inCall =>
      '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
    _Phase.ended => context.tr('lc_ended'),
    _Phase.failed => context.tr(_errorKey ?? 'lc_media_failed'),
  };

  @override
  Widget build(BuildContext context) {
    final remote = _video ? _remoteVideo : null;
    final local = _video ? _localVideo : null;
    final onDark = Colors.white;
    return PopScope(
      canPop: _phase == _Phase.failed || _phase == _Phase.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: AppColors.isDark
            ? AppColors.background
            : const Color(0xFF123F31),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (remote != null)
              VideoTrackRenderer(remote, fit: VideoViewFit.cover)
            else
              _AvatarStage(
                name: widget.otherName,
                pulsing: _phase == _Phase.waiting,
              ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: Space.l),
                  Text(
                    widget.otherName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xxs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _video ? LucideIcons.video : LucideIcons.phone,
                        size: 16,
                        color: onDark.withValues(alpha: .85),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _statusText(context),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: onDark.withValues(alpha: .85),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_warningKey != null && _phase != _Phase.failed)
                    _Notice(context.tr(_warningKey!)),
                  if (_needsAudioTap && _phase != _Phase.failed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.m),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: () async {
                          await _room?.startAudio();
                          if (mounted) setState(() => _needsAudioTap = false);
                        },
                        icon: const Icon(LucideIcons.volume2),
                        label: Text(context.tr('lc_tap_for_sound')),
                      ),
                    ),
                  if (_phase == _Phase.failed && _detail != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.l),
                      child: Text(
                        _detail!,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: onDark.withValues(alpha: .6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (_phase == _Phase.failed)
                    Padding(
                      padding: const EdgeInsets.all(Space.l),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: onDark,
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: () => context.pop(),
                        child: Text(context.tr('back')),
                      ),
                    )
                  else
                    _Controls(
                      video: _video,
                      muted: _muted,
                      cameraOff: _cameraOff,
                      speaker: _speaker,
                      onMute: _toggleMute,
                      onCamera: _toggleCamera,
                      onSpeaker: kIsWeb ? null : _toggleSpeaker,
                      onFlip: kIsWeb ? null : _flipCamera,
                      onHangUp: _finish,
                    ),
                  const SizedBox(height: Space.l),
                ],
              ),
            ),
            // My own picture, small, in a corner.
            if (local != null)
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + 96,
                end: Space.m,
                width: 104,
                height: 148,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.card),
                  child: VideoTrackRenderer(
                    local,
                    fit: VideoViewFit.cover,
                    mirrorMode: VideoViewMirrorMode.mirror,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStage extends StatelessWidget {
  const _AvatarStage({required this.name, required this.pulsing});
  final String name;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    // First letter of the name, without the «د.» title of doctors.
    final bare = name.trim().replaceFirst(RegExp(r'^(د\.|Dr\.?)\s*'), '');
    final initial = bare.isEmpty ? '' : bare.characters.first;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pulse(
            active: pulsing,
            child: Container(
              width: 132,
              height: 132,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .35),
                  width: 2,
                ),
              ),
              child: initial.isEmpty
                  ? const LogoDisc(size: 96)
                  : Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft breathing ring while waiting for the other person.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didUpdateWidget(covariant _Pulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  void _sync() {
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Stack(
      alignment: Alignment.center,
      children: [
        if (widget.active)
          Container(
            width: 132 + 60 * _c.value,
            height: 132 + 60 * _c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .12 * (1 - _c.value)),
            ),
          ),
        child!,
      ],
    ),
    child: widget.child,
  );
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.video,
    required this.muted,
    required this.cameraOff,
    required this.speaker,
    required this.onMute,
    required this.onCamera,
    required this.onSpeaker,
    required this.onFlip,
    required this.onHangUp,
  });
  final bool video, muted, cameraOff, speaker;
  final VoidCallback onMute, onCamera, onHangUp;
  final VoidCallback? onSpeaker, onFlip;

  @override
  Widget build(BuildContext context) {
    Widget round(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      bool on = false,
      Color? color,
    }) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: label,
          child: Material(
            color:
                color ??
                (on ? Colors.white : Colors.white.withValues(alpha: .16)),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onTap();
                    },
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  icon,
                  size: 26,
                  color: on ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.xs),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .9),
            fontSize: 12,
          ),
        ),
      ],
    );

    final items = <Widget>[
      round(
        muted ? LucideIcons.micOff : LucideIcons.mic,
        context.tr(muted ? 'lc_unmute' : 'lc_mute'),
        onMute,
        on: muted,
      ),
      if (video)
        round(
          cameraOff ? LucideIcons.videoOff : LucideIcons.video,
          context.tr(cameraOff ? 'lc_camera_on' : 'lc_camera_off'),
          onCamera,
          on: cameraOff,
        ),
      if (video && onFlip != null)
        round(LucideIcons.switchCamera, context.tr('lc_flip'), onFlip),
      if (!video && onSpeaker != null)
        round(
          speaker ? LucideIcons.volume2 : LucideIcons.volume1,
          context.tr('lc_speaker'),
          onSpeaker,
          on: speaker,
        ),
      round(
        LucideIcons.phoneOff,
        context.tr('lc_hang_up'),
        onHangUp,
        color: AppColors.emergency,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
    padding: const EdgeInsets.all(Space.s),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(Radii.button),
    ),
    child: Row(
      children: [
        const Icon(LucideIcons.info, color: Colors.white, size: 18),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
