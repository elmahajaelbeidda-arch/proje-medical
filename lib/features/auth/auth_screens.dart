import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/media.dart';
import '../onboarding/onboarding_screens.dart';

void _goHome(BuildContext context, WidgetRef ref) {
  final isDoctor = ref.read(authProvider).isDoctor;
  context.go(isDoctor ? '/doctor' : '/patient');
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final text = Theme.of(context).textTheme;

    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? context.tr('required_field') : null;

    return Theme(
      data: AppTheme.forRole(Theme.of(context), isDoctor: auth.isDoctor),
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(size: 72)),
                  const Center(child: BrandName(fontSize: 34)),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('login_welcome'),
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      backgroundColor: AppColors.role(auth.isDoctor),
                      side: BorderSide.none,
                      avatar: Icon(
                        auth.isDoctor
                            ? Icons.medical_services_outlined
                            : Icons.personal_injury_outlined,
                        color: AppColors.ink,
                        size: 18,
                      ),
                      label: Text(
                        context.tr(
                          auth.isDoctor ? 'role_doctor' : 'role_patient',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.tr('phone_or_email'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: context.tr('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
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
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      ref.read(authProvider.notifier).login();
                      _goHome(context, ref);
                    },
                    child: Text(context.tr('login')),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(context.tr('no_account')),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(context.tr('register')),
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
  String? _specialty;
  Attachment? _certificate;
  Attachment? _idFront;
  Attachment? _idBack;
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  Future<Attachment?> _pickImage() async {
    final source = await askImageSource(context);
    if (source == null || !mounted) return null;
    final files = await pickAttachments(
      context,
      source,
      category: AttachmentCategory.other,
    );
    return files.isEmpty ? null : files.first;
  }

  Future<void> _pickCertificate() async {
    final files = await pickAttachments(
      context,
      PickSource.files,
      category: AttachmentCategory.other,
    );
    if (files.isNotEmpty) setState(() => _certificate = files.first);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_idFront == null || _idBack == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('id_photos_required'))));
      return;
    }
    if (!_accepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('must_accept_terms'))));
      return;
    }
    final isDoctor = ref.read(authProvider).isDoctor;
    ref
        .read(authProvider.notifier)
        .register(
          name: isDoctor ? 'د. ${_name.text.trim()}' : _name.text,
          phone: _phone.text,
          idNumber: _idNumber.text,
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
                              ? Icons.medical_services_outlined
                              : Icons.personal_injury_outlined,
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
                      prefixIcon: const Icon(Icons.badge_outlined),
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
                      hintText: '05XX XX XX XX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      if (digits.isEmpty) return context.tr('required_field');
                      if (digits.length < 9) return context.tr('phone_invalid');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.tr('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: required,
                  ),

                  // ---------------- National ID card ----------------
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, color: AppColors.teal),
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
                    maxLength: 18,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.tr('id_number'),
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return context.tr('required_field');
                      if (value.length < 9) {
                        return context.tr('id_number_invalid');
                      }
                      return null;
                    },
                  ),
                  Text(
                    context.tr('id_upload_hint'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _IdPhotoTile(
                          label: context.tr('id_front'),
                          file: _idFront,
                          onTap: () async {
                            final f = await _pickImage();
                            if (f != null) setState(() => _idFront = f);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _IdPhotoTile(
                          label: context.tr('id_back'),
                          file: _idBack,
                          onTap: () async {
                            final f = await _pickImage();
                            if (f != null) setState(() => _idBack = f);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16),
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
                        prefixIcon: const Icon(Icons.local_hospital_outlined),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: context.tr('license_number'),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      validator: required,
                    ),
                    const SizedBox(height: 16),
                    if (_certificate == null)
                      OutlinedButton.icon(
                        onPressed: _pickCertificate,
                        icon: const Icon(Icons.upload_file_outlined),
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
                    onPressed: _submit,
                    child: Text(context.tr('register')),
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

class _IdPhotoTile extends StatelessWidget {
  const _IdPhotoTile({
    required this.label,
    required this.file,
    required this.onTap,
  });
  final String label;
  final Attachment? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = file?.bytes;
    final done = file != null;
    return AspectRatio(
      aspectRatio: 1.58, // ID-1 card format
      child: Material(
        color: done ? AppColors.teal : AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null) Image.memory(bytes, fit: BoxFit.cover),
              if (!done)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.ink,
                      size: 30,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.tr('tap_to_add'),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                PositionedDirectional(
                  start: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
      data: AppTheme.forRole(Theme.of(context), isDoctor: auth.isDoctor),
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('verify_phone'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.teal,
                child: Icon(Icons.sms_outlined, color: Colors.white, size: 44),
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
                  style: const TextStyle(
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
