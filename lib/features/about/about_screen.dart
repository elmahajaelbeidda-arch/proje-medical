import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../models/blood.dart';
import '../../widgets/brand.dart';
import '../blood/blood_screens.dart';
import '../onboarding/onboarding_screens.dart';

/// Phone number for donations to the association (from its poster).
const associationDonationPhone = '32203250';

/// Photo of the association members with the president.
const teamPhotoAsset = 'assets/images/team.jpg';

/// "عن الجمعية": team photo, introduction and donation number.
class AboutAssociationScreen extends StatelessWidget {
  const AboutAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_association'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              onTap: () => _openPhoto(context),
              child: Image.asset(
                teamPhotoAsset,
                fit: BoxFit.cover,
                semanticLabel: context.tr('team_photo_caption'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('team_photo_caption'),
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
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
                    phone: associationDonationPhone,
                    preferred: ContactMethod.call,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          maxScale: 4,
          child: Image.asset(teamPhotoAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Card with the team photo that opens the "about" page.
class TeamPhotoCard extends StatelessWidget {
  const TeamPhotoCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(teamPhotoAsset, fit: BoxFit.cover),
            ),
            ListTile(
              title: Text(
                context.tr('meet_team'),
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              subtitle: Text(context.tr('team_photo_caption')),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
