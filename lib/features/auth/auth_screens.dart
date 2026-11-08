import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
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
  String? _specialty;
  bool _certificate = false;
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('must_accept_terms'))));
      return;
    }
    final isDoctor = ref.read(authProvider).isDoctor;
    ref
        .read(authProvider.notifier)
        .login(
          name: isDoctor && _name.text.trim().isNotEmpty
              ? 'د. ${_name.text.trim()}'
              : _name.text,
        );
    if (isDoctor) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('doctor_review_note'))));
    }
    _goHome(context, ref);
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
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr('phone'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: required,
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
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _certificate = true),
                      icon: Icon(
                        _certificate
                            ? Icons.check_circle
                            : Icons.upload_file_outlined,
                      ),
                      label: Text(
                        context.tr(
                          _certificate
                              ? 'certificate_uploaded'
                              : 'upload_certificate',
                        ),
                      ),
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
