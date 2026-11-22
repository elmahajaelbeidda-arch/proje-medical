import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/shifa_ui.dart';
import '../care_map/care_map.dart' show openDirections;

/// Public page of a volunteer doctor: a large card over a curved header
/// (avatar, rating, availability, city) with the two main actions, then
/// the bio, hours and figures.
class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final d = MockData.doctorById(id);
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.person_search_outlined,
          message: context.tr('none'),
        ),
      );
    }
    final lang = Localizations.localeOf(context).languageCode;
    final specialty = context.tr(Specialty.byId(d.specialtyId).key);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 400,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 230,
                  child: CustomPaint(painter: _CoverPainter()),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _RoundIcon(
                          icon: Icons.arrow_back,
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onTap: () => context.pop(),
                        ),
                        const Spacer(),
                        _RoundIcon(
                          icon: Icons.map_outlined,
                          tooltip: context.tr('cm_title'),
                          onTap: () => context.push('/care-map'),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main card overlapping the cover.
                Positioned(
                  left: 16,
                  right: 16,
                  top: 150,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33126B50),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _AvailabilityPill(on: d.available),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            Text(
                              ' ${d.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  d.cityFor(lang),
                                  d.clinicAddress,
                                ].where((e) => e.isNotEmpty).join(' / '),
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassButton(
                                icon: Icons.add_comment_outlined,
                                label: context.tr('dp_ask'),
                                onTap: () => context.push('/patient/new'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _GlassButton(
                                icon: Icons.directions_outlined,
                                label: context.tr('dp_location'),
                                onTap: d.latitude == null
                                    ? () => context.push('/care-map')
                                    : () => openDirections(
                                        context,
                                        LatLng(d.latitude!, d.longitude!),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Avatar over the card's top edge.
                Positioned(
                  top: 104,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x26126B50),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(5),
                          child: CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              d.initials,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 6,
                          bottom: 6,
                          child: StatusDot(on: d.available, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _Figure(
                      value: '${d.yearsOfExperience}',
                      label: context.tr('dp_years'),
                    ),
                    const SizedBox(width: 10),
                    _Figure(
                      value: '${d.consultationsCount}',
                      label: context.tr('dp_consults'),
                    ),
                    const SizedBox(width: 10),
                    _Figure(
                      value: '${d.rating}',
                      label: context.tr('dp_rating'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MenuPanel(
                  title: context.tr('professional_profile'),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(d.bio, style: const TextStyle(height: 1.7)),
                    ),
                  ],
                ),
                if (d.availability.isNotEmpty)
                  MenuPanel(
                    title: context.tr('availability_hours'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in d.availability)
                              Chip(
                                avatar: const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                label: Text(a),
                                backgroundColor: Colors.white,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (d.verified)
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.info,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.tr('dp_verified_note'),
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: const StadiumBorder(),
              backgroundColor: AppColors.primary,
            ),
            onPressed: () => context.push('/patient/new'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(context.tr('dp_ask_this', args: {'name': d.name})),
          ),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter();
  @override
  void paint(Canvas canvas, Size size) =>
      WaveHeaderPainter().paint(canvas, size);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(6),
    child: Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    ),
  );
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(on: on, size: 10),
        const SizedBox(width: 6),
        Text(
          context.tr(on ? 'available_now' : 'unavailable'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.white24),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.vivid,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
