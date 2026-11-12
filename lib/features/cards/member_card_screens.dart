import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/l10n.dart';
import '../../core/member_card_provider.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/blood.dart' show maskName;
import '../../models/member_card.dart';
import '../../widgets/common.dart';
import '../summons/summons_screens.dart' show loadPdfAssets;
import 'member_card_pdf.dart';

/// Public address of the app, used in the QR code so any phone camera opens
/// the verification page.
const _publicSite = 'https://elmahajaelbeidda-arch.github.io/proje-medical/';

String verifyUrl(MemberCard c) {
  final base = Uri.base;
  final site = (base.scheme == 'http' || base.scheme == 'https')
      ? '${base.origin}${base.path}'
      : _publicSite;
  return '$site#/verify-card?n=${c.number}&c=${c.verificationCode}';
}

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fileName(MemberCard c) => 'carte-${c.number}.pdf';

Future<Uint8List?> _pdf(BuildContext context, MemberCard c) async {
  final lang = Localizations.localeOf(context).languageCode;
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('summons_failed');
  try {
    return await buildMemberCardPdf(
      c,
      await loadPdfAssets(),
      verifyUrl: verifyUrl(c),
      tr: (k) => AppStrings.of(lang, k),
      rtl: lang == 'ar',
    );
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
    return null;
  }
}

Future<void> downloadMemberCard(BuildContext context, MemberCard c) async {
  final bytes = await _pdf(context, c);
  if (bytes == null) return;
  await Printing.sharePdf(bytes: bytes, filename: _fileName(c));
}

Future<void> printMemberCard(BuildContext context, MemberCard c) async {
  final bytes = await _pdf(context, c);
  if (bytes == null) return;
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: _fileName(c));
}

// ---------------------------------------------------------------------------
// On-screen card
// ---------------------------------------------------------------------------

class MemberCardView extends StatelessWidget {
  const MemberCardView({super.key, required this.card});
  final MemberCard card;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final text = Theme.of(context).textTheme;

    Widget line(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: text.bodySmall),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textDirection: ltr ? TextDirection.ltr : null,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    return AspectRatio(
      aspectRatio: 85.6 / 54,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Image.asset('assets/images/logo_icon.png'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('app_name'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    context.tr('mc_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.topStart,
                        child: SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Pill(
                                label:
                                    '${context.tr('mc_kind_${c.kind.name}')} • ${context.tr(c.detailKey)}',
                                color: AppColors.secondary,
                              ),
                              const SizedBox(height: 4),
                              line(
                                context.tr('mc_number'),
                                c.number,
                                ltr: true,
                              ),
                              line(
                                context.tr(
                                  c.kind == MemberKind.facility
                                      ? 'mc_id_facility'
                                      : 'mc_id_person',
                                ),
                                c.maskedIdValue,
                                ltr: true,
                              ),
                              line(
                                context.tr('mc_expires'),
                                _d(c.expiresAt),
                                ltr: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: QrImageView(
                              data: verifyUrl(c),
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.verificationCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (c.suspended)
              Container(
                color: AppColors.emergency,
                padding: const EdgeInsets.all(4),
                child: Text(
                  context.tr('cc_suspended'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardPage extends StatelessWidget {
  const _CardPage({required this.card, this.extra = const []});
  final MemberCard card;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      MemberCardView(card: card),
      if (card.suspended) ...[
        const SizedBox(height: 10),
        Text(
          context.tr('mc_suspended_note'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.emergency),
        ),
      ],
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              onPressed: () => downloadMemberCard(context, card),
              icon: const Icon(Icons.download),
              label: Text(context.tr('summons_download')),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
              onPressed: () => printMemberCard(context, card),
              icon: const Icon(Icons.print_outlined),
              label: Text(context.tr('summons_print')),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        context.tr('mc_print_hint'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      ...extra,
    ],
  );
}

// ---------------------------------------------------------------------------
// The signed-in user's card
// ---------------------------------------------------------------------------

class MyMemberCardScreen extends ConsumerWidget {
  const MyMemberCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(myMemberCardProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mc_title'))),
      body: card == null
          ? EmptyState(
              icon: Icons.hourglass_top,
              message: context.tr('mc_pending'),
            )
          : _CardPage(card: card),
    );
  }
}

/// Menu entry used in every account (patient, doctor, psychiatrist,
/// facility).
class MyCardTile extends StatelessWidget {
  const MyCardTile({super.key});
  @override
  Widget build(BuildContext context) => MenuTile(
    icon: Icons.badge_outlined,
    title: context.tr('mc_title'),
    onTap: () => context.push('/my-card'),
  );
}

// ---------------------------------------------------------------------------
// Team: any card, with suspend / reactivate
// ---------------------------------------------------------------------------

class _SuspendButton extends ConsumerWidget {
  const _SuspendButton({required this.card});
  final MemberCard card;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(suspendedCardsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: card.suspended
          ? FilledButton.tonalIcon(
              onPressed: () {
                n.reactivate(card.number);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('mc_reactivated_msg'))),
                );
              },
              icon: const Icon(Icons.verified),
              label: Text(context.tr('mc_reactivate')),
            )
          : OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emergency,
              ),
              onPressed: () {
                n.suspend(card.number);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('mc_suspended_msg'))),
                );
              },
              icon: const Icon(Icons.block),
              label: Text(context.tr('mc_suspend')),
            ),
    );
  }
}

class CommitteeMemberCardScreen extends ConsumerWidget {
  const CommitteeMemberCardScreen({super.key, required this.holderId});
  final String holderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MemberCard? card;
    for (final c in ref.watch(memberCardsProvider)) {
      if (c.holderId == holderId) card = c;
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mc_title'))),
      body: card == null
          ? EmptyState(
              icon: Icons.badge_outlined,
              message: context.tr('mc_pending'),
            )
          : _CardPage(
              card: card,
              extra: [_SuspendButton(card: card)],
            ),
    );
  }
}

/// Small button for the team's review cards.
class ViewMemberCardButton extends StatelessWidget {
  const ViewMemberCardButton({super.key, required this.holderId});
  final String holderId;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.push('/committee/card/$holderId'),
    icon: const Icon(Icons.badge_outlined),
    label: Text(context.tr('mc_view')),
  );
}

// ---------------------------------------------------------------------------
// Public verification page (opened by the QR code)
// ---------------------------------------------------------------------------

class VerifyCardScreen extends ConsumerStatefulWidget {
  const VerifyCardScreen({super.key, this.number, this.code});
  final String? number;
  final String? code;
  @override
  ConsumerState<VerifyCardScreen> createState() => _VerifyCardScreenState();
}

class _VerifyCardScreenState extends ConsumerState<VerifyCardScreen> {
  late final _input = TextEditingController(
    text: widget.number == null
        ? ''
        : '${widget.number} ${widget.code ?? ''}'.trim(),
  );
  (String, String)? _query;

  @override
  void initState() {
    super.initState();
    if (widget.number != null && widget.code != null) {
      _query = (widget.number!.toUpperCase(), widget.code!.toUpperCase());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _verify() {
    final q = parseCardInput(_input.text);
    if (q == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('mc_bad_input'))));
      return;
    }
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final isTeam = ref.watch(authProvider).isCommittee;
    final cards = ref.watch(memberCardsProvider);
    final result = _query == null
        ? null
        : checkCard(cards, _query!.$1, _query!.$2);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('mc_verify_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('mc_verify_hint'), style: text.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: context.tr('mc_verify_input'),
              hintText: context.tr('mc_verify_input_hint'),
              prefixIcon: const Icon(Icons.qr_code_2),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
            onPressed: _verify,
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(context.tr('mc_verify_btn')),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            _Result(check: result.$1, card: result.$2, isTeam: isTeam),
          ],
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.check,
    required this.card,
    required this.isTeam,
  });
  final CardCheck check;
  final MemberCard? card;
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final ok = check == CardCheck.valid;
    final color = switch (check) {
      CardCheck.valid => AppColors.success,
      CardCheck.expired => AppColors.warning,
      _ => AppColors.emergency,
    };
    final c = card;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  ok ? Icons.verified : Icons.gpp_bad_outlined,
                  color: color,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('cc_${check.name}'),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            if (c != null) ...[
              const Divider(height: 24),
              // The public sees initials only; the team sees the full name.
              Text(
                isTeam || c.kind == MemberKind.facility
                    ? c.name
                    : maskName(c.name),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${context.tr('mc_kind_${c.kind.name}')} • ${context.tr(c.detailKey)}',
              ),
              const SizedBox(height: 6),
              Text('${context.tr('mc_number')}: ${c.number}'),
              Text(
                '${context.tr('mc_issued')}: ${_d(c.issuedAt)} — ${context.tr('mc_expires')}: ${_d(c.expiresAt)}',
              ),
              if (isTeam) _SuspendButton(card: c),
              if (isTeam)
                TextButton.icon(
                  onPressed: () =>
                      context.push('/committee/card/${c.holderId}'),
                  icon: const Icon(Icons.badge_outlined),
                  label: Text(context.tr('mc_view')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
