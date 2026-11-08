import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const maxFileBytes = 10 * 1024 * 1024; // 10 MB
const maxVoiceDuration = Duration(minutes: 3);

String formatBytes(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

String categoryKey(AttachmentCategory c) => 'cat_${c.name}';

IconData categoryIcon(AttachmentCategory c) => switch (c) {
  AttachmentCategory.exam => Icons.monitor_heart_outlined,
  AttachmentCategory.lab => Icons.biotech_outlined,
  AttachmentCategory.prescription => Icons.receipt_long_outlined,
  AttachmentCategory.other => Icons.description_outlined,
};

Color categoryColor(AttachmentCategory c) => switch (c) {
  AttachmentCategory.exam => AppColors.info,
  AttachmentCategory.lab => AppColors.teal,
  AttachmentCategory.prescription => AppColors.green,
  AttachmentCategory.other => AppColors.grey,
};

// ---------------------------------------------------------------------------
// File picking (camera / gallery / files)
// ---------------------------------------------------------------------------

enum PickSource { camera, gallery, files }

/// Opens the requested picker and returns the chosen files as attachments.
/// Files over 10 MB are skipped and reported to the user.
Future<List<Attachment>> pickAttachments(
  BuildContext context,
  PickSource source, {
  AttachmentCategory category = AttachmentCategory.lab,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final tooLarge = context.tr('file_too_large');
  final failed = context.tr('pick_failed');
  final result = <Attachment>[];
  var skipped = false;

  Future<void> add(String rawName, Future<Uint8List> Function() read) async {
    // image_picker on the web prefixes resized images with "scaled_".
    final name = rawName.startsWith('scaled_') ? rawName.substring(7) : rawName;
    final bytes = await read();
    if (bytes.length > maxFileBytes) {
      skipped = true;
      return;
    }
    final isPdf = name.toLowerCase().endsWith('.pdf');
    result.add(
      Attachment(
        name,
        isPdf ? AttachmentKind.pdf : AttachmentKind.image,
        category: category,
        bytes: bytes,
        size: bytes.length,
      ),
    );
  }

  try {
    switch (source) {
      case PickSource.camera:
        final x = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2400,
        );
        if (x != null) await add(x.name, x.readAsBytes);
      case PickSource.gallery:
        final xs = await ImagePicker().pickMultiImage(
          imageQuality: 85,
          maxWidth: 2400,
        );
        for (final x in xs) {
          await add(x.name, x.readAsBytes);
        }
      case PickSource.files:
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        );
        for (final f in files) {
          await add(f.name, f.readAsBytes);
        }
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
  if (skipped) messenger.showSnackBar(SnackBar(content: Text(tooLarge)));
  return result;
}

/// Bottom sheet: take a photo or choose one from the gallery.
Future<PickSource?> askImageSource(BuildContext context) {
  return showModalBottomSheet<PickSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(ctx.tr('camera')),
            onTap: () => Navigator.pop(ctx, PickSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(ctx.tr('gallery')),
            onTap: () => Navigator.pop(ctx, PickSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Attachment thumbnail / preview
// ---------------------------------------------------------------------------

class AttachmentThumb extends StatelessWidget {
  const AttachmentThumb(this.attachment, {super.key, this.size = 52});
  final Attachment attachment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = attachment.bytes;
    if (attachment.kind == AttachmentKind.image && bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final isPdf = attachment.kind == AttachmentKind.pdf;
    final color = isPdf ? AppColors.danger : categoryColor(attachment.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
        color: Colors.white,
      ),
    );
  }
}

void showAttachmentPreview(BuildContext context, Attachment a) {
  final bytes = a.bytes;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              [
                ctx.tr(categoryKey(a.category)),
                formatBytes(a.size),
              ].where((e) => e.isNotEmpty).join(' • '),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Flexible(
            child: a.kind == AttachmentKind.image && bytes != null
                ? InteractiveViewer(
                    maxScale: 5,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  )
                : Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AttachmentThumb(a, size: 96),
                        const SizedBox(height: 16),
                        Text(
                          ctx.tr('preview_placeholder'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Voice recording
// ---------------------------------------------------------------------------

/// Record / re-record / delete a voice note. Calls [onChanged] with the new
/// note, or null when it is deleted.
class VoiceRecorderField extends StatefulWidget {
  const VoiceRecorderField({super.key, this.initial, required this.onChanged});
  final VoiceNote? initial;
  final ValueChanged<VoiceNote?> onChanged;

  @override
  State<VoiceRecorderField> createState() => _VoiceRecorderFieldState();
}

class _VoiceRecorderFieldState extends State<VoiceRecorderField> {
  final _recorder = AudioRecorder();
  late VoiceNote? _note = widget.initial;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  double _level = 0; // 0..1

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final messenger = ScaffoldMessenger.of(context);
    final denied = context.tr('mic_denied');
    final failed = context.tr('record_failed');
    try {
      if (!await _recorder.hasPermission()) {
        messenger.showSnackBar(SnackBar(content: Text(denied)));
        return;
      }
      final path = kIsWeb
          ? ''
          : '${(await getTemporaryDirectory()).path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
        path: path,
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((a) {
          // dBFS: about -45 (silence) .. 0 (loud)
          final v = ((a.current + 45) / 45).clamp(0.0, 1.0);
          if (mounted) setState(() => _level = v);
        });
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= maxVoiceDuration) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _ampSub?.cancel();
    final source = await _recorder.stop();
    setState(() {
      _recording = false;
      _level = 0;
      if (source != null && source.isNotEmpty) {
        _note = VoiceNote(source, _elapsed);
      }
    });
    widget.onChanged(_note);
  }

  void _delete() {
    setState(() => _note = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (_recording) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44 + 16 * _level,
              height: 44 + 16 * _level,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: AppColors.danger),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('recording'),
                    style: text.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${formatDuration(_elapsed)} / ${formatDuration(maxVoiceDuration)}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.danger,
                minimumSize: const Size(0, 44),
              ),
              onPressed: _stop,
              icon: const Icon(Icons.stop_rounded),
              label: Text(context.tr('stop')),
            ),
          ],
        ),
      );
    }

    if (_note != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VoiceNotePlayer(note: _note!),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('record_again')),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      );
    }

    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _start,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.mic, color: AppColors.teal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('tap_to_record'),
                      style: text.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.tr('max_duration'),
                      style: text.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voice playback
// ---------------------------------------------------------------------------

class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key, required this.note, this.compact = false});
  final VoiceNote note;

  /// Smaller variant used inside chat bubbles.
  final bool compact;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription<dynamic>>[];
  bool _playing = false;
  Duration _position = Duration.zero;
  late Duration _duration = widget.note.duration;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _playing = s == PlayerState.playing);
      }),
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
      _player.onDurationChanged.listen((d) {
        if (mounted && d > Duration.zero) setState(() => _duration = d);
      }),
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _position = Duration.zero);
      }),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final src = widget.note.source;
    final isUrl = kIsWeb || src.startsWith('blob:') || src.startsWith('http');
    await _player.play(isUrl ? UrlSource(src) : DeviceFileSource(src));
  }

  @override
  Widget build(BuildContext context) {
    final playable = widget.note.playable;
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    final fg = widget.compact ? AppColors.ink : Colors.white;
    final bg = widget.compact ? AppColors.mint : AppColors.ink;

    return Container(
      padding: EdgeInsets.all(widget.compact ? 8 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
      ),
      child: Row(
        mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: widget.compact ? AppColors.ink : AppColors.mint,
              foregroundColor: widget.compact ? Colors.white : AppColors.ink,
              disabledBackgroundColor: AppColors.grey,
            ),
            onPressed: playable ? _toggle : null,
            icon: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: SizedBox(
              width: widget.compact ? 130 : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.compact)
                    Row(
                      children: [
                        Icon(Icons.graphic_eq, color: fg, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          context.tr('voice_note'),
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: widget.compact ? AppColors.ink : AppColors.mint,
                      backgroundColor: widget.compact
                          ? Colors.white
                          : AppColors.inkLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playable
                        ? '${formatDuration(_position)} / ${formatDuration(_duration)}'
                        : '${formatDuration(_duration)} • ${context.tr('demo_audio')}',
                    textDirection: playable ? TextDirection.ltr : null,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
