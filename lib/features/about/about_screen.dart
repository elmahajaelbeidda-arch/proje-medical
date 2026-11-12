import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin_provider.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/blood.dart';
import '../../widgets/brand.dart';
import '../blood/blood_screens.dart';
import '../onboarding/onboarding_screens.dart';

/// Phone number for donations to the association (from its poster).
const associationDonationPhone = '32203250';

/// "عن الجمعية": introduction and donation number.
class AboutAssociationScreen extends ConsumerWidget {
  const AboutAssociationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(appSettingsProvider).info;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_association'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const Center(child: ShifaLockup(iconSize: 72)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: BrandRichText(
              context.tr('about_shifa'),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(
                color: Colors.white,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('support_association'),
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(context.tr('support_association_desc')),
                  const SizedBox(height: 12),
                  ContactButtons(
                    phone: info.donationNumber,
                    preferred: ContactMethod.call,
                  ),
                  const SizedBox(height: 10),
                  // Contact details managed from the admin dashboard.
                  Text(
                    '${info.name}\n${info.address}\n${info.email}\n'
                    '${context.tr('phone')}: ${info.phone} • ${context.tr('whatsapp')}: ${info.whatsapp}',
                    style: Theme.of(context).textTheme.bodySmall,
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
