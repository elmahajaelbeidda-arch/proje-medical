import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/account_lookup.dart';
import '../../core/accounts_remote.dart';
import '../../core/admin_provider.dart';
import '../../core/facility_provider.dart';
import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../models/registration.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';

/// Accounts suspended by the administration cannot sign in.
bool _blockedIfSuspended(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  if (auth.isCommittee) return false;
  final holder =
      auth.registrationId ??
      MockData.demoRegistrationId(
        doctor: auth.isDoctor,
        psych: auth.isPsychDoctor,
      );
  if (!ref.read(adminProvider).suspendedAccounts.containsKey(holder)) {
    return false;
  }
  ref.read(authProvider.notifier).logout();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.tr('account_suspended_msg')),
      backgroundColor: AppColors.emergency,
    ),
  );
  return true;
}

void _goHome(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  context.go(
    auth.isCommittee
        ? '/committee'
        : auth.isPsychDoctor
        ? '/psych/doctor'
        : auth.isDoctor
        ? '/doctor'
        : '/patient',
  );
}

/// Message of a server account error.
String accountErrorKey(AccountError e) => switch (e) {
  AccountError.notFound => 'login_not_found',
  AccountError.wrongPassword => 'login_wrong_password',
  AccountError.confirmEmailOn => 'account_confirm_email_on',
  AccountError.weakPassword => 'password_rule',
  AccountError.network => 'ad_login_network',
};

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// One sign-in for every account: phone number, account code or national
/// ID number, then the password. The account found decides where to go.
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _busy = false;

  /// Server: real sign-in, then the person's own space.
  Future<void> _loginRemote() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    String msg(String k) => context.tr(k);
    try {
      final p = await const AccountsRemote().signIn(_id.text, _password.text);
      if (!mounted) return;
      ref.read(registrationsProvider.notifier).upsert(p.toRegistration());
      ref
          .read(authProvider.notifier)
          .loginAs(
            role: p.role,
            name: p.name,
            phone: p.phone,
            idNumber: p.nationalId,
            registrationId: p.userId,
            specialtyId: p.specialtyId,
          );
      _goHome(context, ref);
    } on AccountException catch (e) {
      // Not a person's account: maybe a medical facility (next stage).
      if (e.error == AccountError.notFound && _loginLocalFacility()) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg(accountErrorKey(e.error))),
          backgroundColor: AppColors.emergency,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Medical facilities still sign in locally until their stage is linked.
  bool _loginLocalFacility() {
    final account = findAccount(
      const [],
      ref.read(facilityProvider).facilities,
      _id.text,
    );
    if (account == null || account.kind != AccountKind.facility) return false;
    ref.read(facilitySessionProvider.notifier).signIn(account.facilityId!);
    context.go('/facility/home');
    return true;
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    if (AccountsRemote.enabled) {
      _loginRemote();
      return;
    }
    final account = findAccount(
      ref.read(registrationsProvider),
      ref.read(facilityProvider).facilities,
      _id.text,
    );
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('login_not_found')),
          action: SnackBarAction(
            label: context.tr('register'),
            onPressed: () => context.push('/role'),
          ),
        ),
      );
      return;
    }
    if (account.kind == AccountKind.facility) {
      if (ref
          .read(adminProvider)
          .suspendedAccounts
          .containsKey(account.facilityId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('account_suspended_msg')),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }
      ref.read(facilitySessionProvider.notifier).signIn(account.facilityId!);
      context.go('/facility/home');
      return;
    }
    ref
        .read(authProvider.notifier)
        .loginAs(
          role: roleOf(account),
          name: account.name,
          phone: account.phone,
          idNumber: account.idNumber,
          registrationId: account.registrationId,
          specialtyId: account.specialtyId,
        );
    if (_blockedIfSuspended(context, ref)) return;
    _goHome(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: LogoDisc(size: 88)),
                const SizedBox(height: Space.xs),
                Center(
                  child: BrandName(fontSize: 28, color: AppColors.primary),
                ),
                const SizedBox(height: Space.m),
                Text(
                  context.tr('login_welcome'),
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('login_sub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _id,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.tr('login_id'),
                    helperText: context.tr('login_id_help'),
                    helperMaxLines: 2,
                    prefixIcon: const Icon(LucideIcons.user),
                  ),
                  validator: required,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(LucideIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: required,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(context.tr('forgot_password')),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('login')),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(context.tr('no_account')),
                    TextButton(
                      onPressed: () => context.push('/role'),
                      child: Text(context.tr('register')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Demo stage only: ready-made accounts (any password).
                if (!AccountsRemote.enabled)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr('demo_accounts_hint'),
                          style: TextStyle(fontSize: 13, color: AppColors.grey),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final (label, code) in demoLoginCodes)
                              ActionChip(
                                label: Text('${context.tr(label)} · $code'),
                                onPressed: () => setState(() {
                                  _id.text = code;
                                  _password.text = 'demo1234';
                                }),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _idNumber = TextEditingController();
  final _license = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _specialty;
  Attachment? _certificate;
  bool _accepted = false;
  bool _psychPledge = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idNumber.dispose();
    _license.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final files = await pickAttachments(
      context,
      PickSource.files,
      category: AttachmentCategory.other,
    );
    if (files.isNotEmpty) setState(() => _certificate = files.first);
  }

  /// Server: creates the real account, then opens the person's space
  /// (waiting for the team's review).
  Future<void> _submitRemote(UserRole role, String name, bool isDoctor) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    String msg(String k) => context.tr(k);
    try {
      final p = await const AccountsRemote().signUp(
        role: role,
        name: name,
        phone: _phone.text,
        nationalId: _idNumber.text,
        password: _password.text,
        specialtyId: isDoctor ? _specialty : null,
        licenseNumber: isDoctor ? _license.text : null,
        certificate: isDoctor ? _certificate : null,
      );
      if (!mounted) return;
      ref.read(registrationsProvider.notifier).upsert(p.toRegistration());
      ref
          .read(authProvider.notifier)
          .loginAs(
            role: p.role,
            name: p.name,
            phone: p.phone,
            idNumber: p.nationalId,
            registrationId: p.userId,
            specialtyId: p.specialtyId,
          );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${msg('account_created')} ${p.code}\n${msg(isDoctor ? 'doctor_review_note' : 'account_review_note')}',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
      _goHome(context, ref);
    } on DuplicateRegistrationException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg('dup_${e.field}')),
          backgroundColor: AppColors.emergency,
        ),
      );
    } on AccountException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg(accountErrorKey(e.error))),
          backgroundColor: AppColors.emergency,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg('ad_login_network')),
          backgroundColor: AppColors.emergency,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('must_accept_terms'))));
      return;
    }
    if (ref.read(authProvider).isDoctor &&
        _specialty == 'psych' &&
        !_psychPledge) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('psych_pledge_required'))),
      );
      return;
    }
    final auth = ref.read(authProvider);
    final isDoctor = auth.isDoctor;
    final name = isDoctor ? 'د. ${_name.text.trim()}' : _name.text;
    if (AccountsRemote.enabled) {
      _submitRemote(auth.role, name, isDoctor);
      return;
    }
    // The new account is sent to the committee for review.
    final String registrationId;
    try {
      registrationId = ref
          .read(registrationsProvider.notifier)
          .add(
            role: auth.role,
            name: name,
            phone: _phone.text,
            idNumber: _idNumber.text,
            specialtyId: isDoctor ? _specialty : null,
            licenseNumber: isDoctor ? _license.text : null,
            certificate: isDoctor ? _certificate : null,
          );
    } on DuplicateRegistrationException catch (e) {
      // One account per person: same ID card number or phone.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('dup_${e.field}')),
          backgroundColor: AppColors.emergency,
        ),
      );
      return;
    }
    ref
        .read(authProvider.notifier)
        .register(
          name: name,
          phone: _phone.text,
          idNumber: _idNumber.text,
          registrationId: registrationId,
          specialtyId: isDoctor ? _specialty : null,
        );
    // Step 2: confirm the phone number with the SMS code.
    context.push('/verify');
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = ref.watch(authProvider).isDoctor;
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    return Theme(
      data: AppTheme.forRole(Theme.of(context), isDoctor: isDoctor),
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('register'))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.role(isDoctor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDoctor
                              ? LucideIcons.briefcaseMedical
                              : LucideIcons.userRound,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(
                              isDoctor ? 'role_doctor' : 'role_patient',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: context.tr('full_name'),
                      prefixIcon: const Icon(LucideIcons.idCard),
                    ),
                    validator: required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('phone'),
                      hintText: 'XX XX XX XX',
                      prefixIcon: const Icon(LucideIcons.phone),
                    ),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.isEmpty) return context.tr('required_field');
                      if (digits.length < 8) return context.tr('phone_invalid');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.tr('password'),
                      helperText: context.tr('password_rule'),
                      prefixIcon: const Icon(LucideIcons.lock),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return context.tr('required_field');
                      }
                      if (v.length < 8) return context.tr('password_rule');
                      return null;
                    },
                  ),

                  // ---------------- National ID card ----------------
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(LucideIcons.idCard, color: AppColors.turquoise),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('id_card'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _idNumber,
                    keyboardType: TextInputType.number,
                    // Mauritanian national ID number (NNI): 10 digits.
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.tr('id_number'),
                      prefixIcon: const Icon(LucideIcons.pin),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return context.tr('required_field');
                      if (value.length != 10) {
                        return context.tr('id_number_invalid');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.lock, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('id_privacy'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (isDoctor) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _specialty,
                      decoration: InputDecoration(
                        labelText: context.tr('specialty'),
                        prefixIcon: const Icon(LucideIcons.hospital),
                      ),
                      items: [
                        for (final s in Specialty.all)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(context.tr(s.key)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _specialty = v),
                      validator: required,
                    ),
                    // Volunteer psychiatrists commit to confidentiality.
                    if (_specialty == 'psych') ...[
                      const SizedBox(height: 12),
                      Card(
                        color: AppColors.secondary,
                        child: CheckboxListTile(
                          value: _psychPledge,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (v) =>
                              setState(() => _psychPledge = v ?? false),
                          title: Text(
                            context.tr('psych_pledge_title'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(context.tr('psych_pledge')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _license,
                      decoration: InputDecoration(
                        labelText: context.tr('license_number'),
                        prefixIcon: const Icon(LucideIcons.hash),
                      ),
                      validator: required,
                    ),
                    const SizedBox(height: 16),
                    if (_certificate == null)
                      OutlinedButton.icon(
                        onPressed: _pickCertificate,
                        icon: const Icon(LucideIcons.fileUp),
                        label: Text(context.tr('upload_certificate')),
                      )
                    else
                      AttachmentTile(
                        _certificate!,
                        onRemove: () => setState(() => _certificate = null),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('doctor_review_note'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _accepted,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    title: Text(context.tr('accept_terms')),
                    subtitle: GestureDetector(
                      onTap: () => context.push('/disclaimer'),
                      child: Text(
                        context.tr('disclaimer'),
                        style: TextStyle(
                          color: AppColors.roleDark(isDoctor),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(context.tr('register')),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('have_account')),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(context.tr('login')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SMS code verification
// ---------------------------------------------------------------------------

class VerifyPhoneScreen extends ConsumerStatefulWidget {
  const VerifyPhoneScreen({super.key});
  @override
  ConsumerState<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends ConsumerState<VerifyPhoneScreen> {
  /// Demo code until an SMS service is connected.
  static const _demoCode = '123456';
  static const _resendDelay = 60;

  final _code = TextEditingController();
  String? _error;
  int _secondsLeft = _resendDelay;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  void _verify() {
    if (_code.text != _demoCode) {
      setState(() => _error = context.tr('wrong_code'));
      return;
    }
    final isDoctor = ref.read(authProvider).isDoctor;
    final regId = ref.read(authProvider).registrationId;
    if (regId != null) {
      ref.read(registrationsProvider.notifier).markPhoneVerified(regId);
    }
    ref.read(authProvider.notifier).verifyPhone();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.tr(isDoctor ? 'doctor_review_note' : 'phone_verified'),
        ),
      ),
    );
    _goHome(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final text = Theme.of(context).textTheme;

    return Theme(
      data: auth.isCommittee
          ? Theme.of(context)
          : AppTheme.forRole(Theme.of(context), isDoctor: auth.isDoctor),
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('verify_phone'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.secondary,
                child: Icon(
                  LucideIcons.messageSquareText,
                  color: AppColors.turquoise,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('code_sent'),
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              Text(
                auth.phone,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: text.headlineMedium?.copyWith(
                    letterSpacing: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: context.tr('enter_code'),
                    hintText: '••••••',
                    counterText: '',
                    errorText: _error,
                  ),
                  onChanged: (v) {
                    if (_error != null) setState(() => _error = null);
                    if (v.length == 6) _verify();
                  },
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  context.tr('demo_code'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _verify,
                child: Text(context.tr('verify')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _secondsLeft > 0
                    ? null
                    : () {
                        _startTimer();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('code_resent'))),
                        );
                      },
                child: Text(
                  _secondsLeft > 0
                      ? context.tr('resend_in', args: {'n': _secondsLeft})
                      : context.tr('resend_code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
