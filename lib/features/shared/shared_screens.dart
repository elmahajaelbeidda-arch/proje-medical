import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/admin.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../onboarding/onboarding_screens.dart';

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(bool asDoctor) {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    ref
        .read(consultationsProvider.notifier)
        .sendMessage(
          widget.id,
          ChatMessage(fromDoctor: asDoctor, text: value, time: DateTime.now()),
        );
    _input.clear();
  }

  Future<void> _recordVoice(bool asDoctor) async {
    VoiceNote? note;
    final send = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ctx.tr('voice_note'),
                  style: Theme.of(ctx).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                VoiceRecorderField(onChanged: (v) => setSheet(() => note = v)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: note == null
                      ? null
                      : () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.send),
                  label: Text(ctx.tr('send_voice')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (send != true || note == null) return;
    ref
        .read(consultationsProvider.notifier)
        .sendMessage(
          widget.id,
          ChatMessage(
            fromDoctor: asDoctor,
            text: '',
            voice: note,
            time: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(consultationProvider(widget.id));
    final isDoctor = ref.watch(authProvider).isDoctor;
    final scheme = Theme.of(context).colorScheme;
    if (c == null) return Scaffold(appBar: AppBar());

    final doctor = MockData.doctorById(c.doctorId);
    final otherName = isDoctor ? c.displayPatientName : (doctor?.name ?? '');
    final messages = c.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(otherName),
            Text(
              context.tr(Specialty.byId(c.specialtyId).key),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('chat_notice'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final mine = m.fromDoctor == isDoctor;
                return Align(
                  alignment: mine
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .75,
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: const Radius.circular(18),
                        topEnd: const Radius.circular(18),
                        bottomStart: Radius.circular(mine ? 4 : 18),
                        bottomEnd: Radius.circular(mine ? 18 : 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (m.voice != null)
                          VoiceNotePlayer(note: m.voice!, compact: true)
                        else
                          Text(
                            m.text,
                            style: TextStyle(
                              color: mine ? scheme.onPrimary : scheme.onSurface,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          context.timeAgo(m.time),
                          style: TextStyle(
                            fontSize: 11,
                            color: (mine ? scheme.onPrimary : scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.tr('voice_note'),
                    onPressed: () => _recordVoice(isDoctor),
                    icon: const Icon(Icons.mic_none),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(isDoctor),
                      decoration: InputDecoration(
                        hintText: context.tr('type_message'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(isDoctor),
                    icon: const Icon(Icons.send),
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

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final me =
        auth.registrationId ??
        MockData.demoRegistrationId(
          doctor: auth.isDoctor,
          psych: auth.isPsychDoctor,
        );
    // Messages sent from the admin dashboard to this user.
    final fromAdmin = [
      for (final m in ref.watch(adminProvider).messages)
        if (m.audience == MessageAudience.all ||
            (m.audience == MessageAudience.patients && !auth.isDoctor) ||
            (m.audience == MessageAudience.doctors && auth.isDoctor) ||
            (m.audience == MessageAudience.user && m.targetId == me))
          AppNotification(
            icon: Icons.campaign_outlined,
            title: m.title,
            body: m.body,
            time: m.at,
          ),
    ];
    final items = [...fromAdmin, ...MockData.notifications(auth.isDoctor)];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notifications'))),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = items[i];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: n.read ? scheme.outlineVariant : AppColors.primary,
                width: n.read ? 1 : 2.5,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: n.read ? AppColors.border : AppColors.ink,
                child: Icon(
                  n.icon,
                  color: n.read ? AppColors.ink : AppColors.mint,
                ),
              ),
              title: Text(
                n.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${n.body}\n${context.timeAgo(n.time)}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(context.tr('language')),
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: 'ar', label: Text('العربية')),
              if (ref.watch(appSettingsProvider).frenchEnabled)
                const ButtonSegment(value: 'fr', label: Text('Français')),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) =>
                ref.read(localeProvider.notifier).set(Locale(s.first)),
          ),
          const SizedBox(height: 12),
          SectionHeader(context.tr('theme')),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(context.tr('theme_light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(context.tr('theme_dark')),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined),
                label: Text(context.tr('theme_system')),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(context.tr('about_association')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/about'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(context.tr('about')),
              subtitle: BrandRichText(
                '${context.tr('app_name')} — ${context.tr('app_slogan')}\n${context.tr('association')} • ${context.tr('version')} 1.0.0',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Disclaimer
// ---------------------------------------------------------------------------

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('disclaimer'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: AppLogo(size: 96)),
          const Center(child: BrandName(fontSize: 32)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: BrandRichText(
                context.tr('disclaimer_body'),
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(height: 1.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the administration has switched a service off.
class SectionOffScreen extends StatelessWidget {
  const SectionOffScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: EmptyState(
      icon: Icons.pause_circle_outline,
      message: context.tr('section_disabled'),
    ),
  );
}
