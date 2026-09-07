import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryContainer,
                    child: Text(
                      'AD',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Administrator',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Info section
            _ProfileSection(
              title: 'Account',
              items: const [
                _ProfileItem(
                  icon: Icons.factory_rounded,
                  label: 'Factory',
                  value: 'GarmentOps',
                ),
                _ProfileItem(
                  icon: Icons.badge_rounded,
                  label: 'Role',
                  value: 'Admin',
                ),
                _ProfileItem(
                  icon: Icons.access_time_rounded,
                  label: 'Shift',
                  value: 'Morning',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'App',
              items: const [
                _ProfileItem(
                  icon: Icons.info_outline_rounded,
                  label: 'Version',
                  value: '1.0.0',
                ),
                _ProfileItem(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  value: 'English',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItem> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              items.length,
              (i) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(items[i].icon, size: 20, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          items[i].label,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          items[i].value,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 48, endIndent: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
