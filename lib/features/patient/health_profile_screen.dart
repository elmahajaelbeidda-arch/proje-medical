import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/providers.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});
  @override
  ConsumerState<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _diseases = [
    'cd_diabetes',
    'cd_hypertension',
    'cd_asthma',
    'cd_heart',
    'cd_kidney',
  ];

  late final HealthProfile _initial = ref.read(healthProfileProvider);
  late final _age = TextEditingController(text: '${_initial.age}');
  late final _allergies = TextEditingController(text: _initial.allergies);
  late final _meds = TextEditingController(text: _initial.medications);
  late bool _male = _initial.male;
  late String _blood = _initial.bloodType;
  late final Set<String> _chronic = {..._initial.chronicDiseases};

  @override
  void dispose() {
    _age.dispose();
    _allergies.dispose();
    _meds.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(healthProfileProvider.notifier).update(HealthProfile(
          age: int.tryParse(_age.text) ?? _initial.age,
          male: _male,
          bloodType: _blood,
          chronicDiseases: _chronic,
          allergies: _allergies.text.trim(),
          medications: _meds.text.trim(),
        ));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr('saved'))));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('health_profile'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr('age'),
                    prefixIcon: const Icon(Icons.cake_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _blood,
                  decoration: InputDecoration(
                    labelText: context.tr('blood_type'),
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                  ),
                  items: [
                    for (final b in _bloodTypes)
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (v) => setState(() => _blood = v ?? _blood),
                ),
              ),
            ],
          ),
          SectionHeader(context.tr('gender')),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.male),
                label: Text(context.tr('male')),
              ),
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.female),
                label: Text(context.tr('female')),
              ),
            ],
            selected: {_male},
            onSelectionChanged: (s) => setState(() => _male = s.first),
          ),
          SectionHeader(context.tr('chronic_diseases')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _diseases)
                FilterChip(
                  label: Text(context.tr(d)),
                  selected: _chronic.contains(d),
                  onSelected: (v) => setState(
                    () => v ? _chronic.add(d) : _chronic.remove(d),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _allergies,
            decoration: InputDecoration(
              labelText: context.tr('allergies'),
              hintText: context.tr('none'),
              prefixIcon: const Icon(Icons.no_food_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _meds,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.tr('current_medications'),
              hintText: context.tr('none'),
              prefixIcon: const Icon(Icons.medication_outlined),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: Text(context.tr('save'))),
        ],
      ),
    );
  }
}
