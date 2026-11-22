import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calls.dart';
import '../../widgets/call_buttons.dart';
import '../../widgets/shifa_ui.dart' show StatusDot;

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
                  icon: const Icon(LucideIcons.sendHorizontal),
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
    if (c == null) return Scaffold(appBar: AppBar());

    final doctor = MockData.doctorById(c.doctorId);
    final otherName = isDoctor ? c.displayPatientName : (doctor?.name ?? '');
    final messages = c.messages.reversed.toList();
    // Calls: the assigned doctor starts them; the patient joins a call the
    // doctor started within the last hour.
    final auth = ref.watch(authProvider);
    ref.watch(callsProvider);
    final calls = ref.read(callsProvider.notifier);
    final open = c.status != ConsultationStatus.closed;
    final canCall = isDoctor
        ? open && c.doctorId == auth.doctorId
        : open && calls.patientCanJoin(c.id);
    Future<void> call(CallKind kind) async {
      final opened = await openCall(
        context,
        ref,
        contextId: c.id,
        kind: kind,
        byDoctor: isDoctor,
        displayName: isDoctor
            ? (doctor?.name ?? auth.displayName)
            : c.displayPatientName,
      );
      if (opened && isDoctor) {
        ref
            .read(consultationsProvider.notifier)
            .sendMessage(
              c.id,
              ChatMessage(
                fromDoctor: true,
                text: '',
                time: DateTime.now(),
                call: kind,
              ),
            );
      }
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(92),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: IconTheme(
                data: IconThemeData(color: AppColors.onPrimary),
                child: Row(
                  children: [
                    BackButton(color: AppColors.onPrimary),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              otherName.isEmpty
                                  ? '؟'
                                  : (isDoctor
                                        ? otherName.characters.first
                                        : (doctor?.initials ?? '')),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        if (!isDoctor && doctor != null)
                          PositionedDirectional(
                            start: 0,
                            bottom: 0,
                            child: StatusDot(on: doctor.available, size: 12),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.briefcaseMedical,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  context.tr(Specialty.byId(c.specialtyId).key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CallActions(
                      onDark: true,
                      enabled: canCall,
                      disabledKey: isDoctor
                          ? 'call_closed'
                          : 'call_wait_doctor',
                      onCall: call,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                Icon(LucideIcons.info, size: 18, color: AppColors.ink),
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
                if (m.call != null) {
                  return CallBubble(
                    kind: m.call!,
                    time: m.time,
                    canJoin: !isDoctor && canCall,
                    onJoin: () => call(m.call!),
                  );
                }
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
                      color: mine ? AppColors.primary : AppColors.secondary,
                      borderRadius: BorderRadiusDirectional.only(
                        topStart: const Radius.circular(20),
                        topEnd: const Radius.circular(20),
                        bottomStart: Radius.circular(mine ? 6 : 20),
                        bottomEnd: Radius.circular(mine ? 20 : 6),
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
                              color: mine
                                  ? AppColors.onPrimary
                                  : AppColors.text,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          context.timeAgo(m.time),
                          style: TextStyle(
                            fontSize: 11,
                            color: mine ? Color(0xB3FFFFFF) : AppColors.grey,
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
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(isDoctor),
                      decoration: InputDecoration(
                        hintText: context.tr('type_message'),
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(color: AppColors.vivid),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: context.tr('voice_note'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      fixedSize: const Size(50, 50),
                    ),
                    onPressed: () => _recordVoice(isDoctor),
                    icon: const Icon(LucideIcons.mic),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: context.tr('send'),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      fixedSize: const Size(50, 50),
                    ),
                    onPressed: () => _send(isDoctor),
                    icon: const Icon(LucideIcons.sendHorizontal),
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
            icon: LucideIcons.megaphone,
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
              for (final l in ref.watch(appSettingsProvider).languages)
                ButtonSegment(
                  value: l,
                  label: Text(AppStrings.languageNames[l]!),
                ),
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
                icon: const Icon(LucideIcons.sun),
                label: Text(context.tr('theme_light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(LucideIcons.moon),
                label: Text(context.tr('theme_dark')),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(LucideIcons.sunMoon),
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
              leading: const Icon(LucideIcons.users),
              title: Text(context.tr('about_association')),
              trailing: const Icon(LucideIcons.chevronRightDir),
              onTap: () => context.push('/about'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(LucideIcons.info),
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
      icon: LucideIcons.circlePause,
      message: context.tr('section_disabled'),
    ),
  );
}
