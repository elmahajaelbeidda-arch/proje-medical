import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// One speech recognizer for the whole app (it can only be initialised once).
final SpeechToText _speech = SpeechToText();

/// Search box with a microphone: the user can type, or tap the mic and say
/// what they are looking for (e.g. "طبيب قلب في نواكشوط").
class VoiceSearchField extends StatefulWidget {
  const VoiceSearchField({
    super.key,
    required this.onChanged,
    this.hintKey = 'search',
    this.exampleKey = 'voice_search_example_doctor',
  });

  final ValueChanged<String> onChanged;
  final String hintKey;

  /// Translation key of an example phrase shown while listening.
  final String exampleKey;

  @override
  State<VoiceSearchField> createState() => _VoiceSearchFieldState();
}

class _VoiceSearchFieldState extends State<VoiceSearchField> {
  final _controller = TextEditingController();
  bool _listening = false;
  double _level = 0;

  @override
  void dispose() {
    if (_listening) _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  void _setText(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged(value);
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = context.tr('voice_search_unavailable');
    final denied = context.tr('mic_denied');
    final failed = context.tr('voice_search_error');
    final lang = Localizations.localeOf(context).languageCode;

    bool ok;
    try {
      ok = await _speech.initialize(
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            setState(() {
              _listening = false;
              _level = 0;
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _listening = false);
          if (e.errorMsg.contains('permission') ||
              e.errorMsg.contains('not-allowed')) {
            messenger.showSnackBar(SnackBar(content: Text(denied)));
          } else {
            // e.g. nothing heard, or no internet for the recognizer.
            messenger.showSnackBar(SnackBar(content: Text(failed)));
          }
        },
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
      return;
    }

    setState(() => _listening = true);
    _setText('');
    await _speech.listen(
      onResult: (r) {
        if (mounted) _setText(r.recognizedWords);
      },
      onSoundLevelChange: (level) {
        // level is roughly -2..10 depending on the platform.
        if (mounted) setState(() => _level = ((level + 2) / 12).clamp(0, 1));
      },
      listenOptions: SpeechListenOptions(
        localeId: lang == 'fr' ? 'fr-FR' : 'ar-SA',
        listenMode: ListenMode.search,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.tr(
              _listening ? 'voice_search_listening' : widget.hintKey,
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty && !_listening)
                  IconButton(
                    tooltip: context.tr('clear'),
                    icon: const Icon(Icons.close),
                    onPressed: () => _setText(''),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: IconButton.filled(
                    tooltip: context.tr('voice_search'),
                    style: IconButton.styleFrom(
                      backgroundColor: _listening
                          ? AppColors.primaryDark
                          : AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _toggle,
                    icon: Icon(_listening ? Icons.stop_rounded : Icons.mic),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: !_listening
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 26 + 10 * _level,
                        height: 26 + 10 * _level,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: AppColors.primaryDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('voice_search_listening'),
                              style: text.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              context.tr(widget.exampleKey),
                              style: text.bodySmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
