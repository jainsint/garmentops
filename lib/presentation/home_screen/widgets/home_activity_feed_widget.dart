import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/app_state_service.dart';
import '../../../core/ist_utils.dart';

class HomeActivityFeedWidget extends StatefulWidget {
  const HomeActivityFeedWidget({super.key});

  @override
  State<HomeActivityFeedWidget> createState() => _HomeActivityFeedWidgetState();
}

class _HomeActivityFeedWidgetState extends State<HomeActivityFeedWidget> {
  @override
  void initState() {
    super.initState();
    AppStateService.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _clearActivity() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Clear Recent Activity',
          style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove all recent activity entries from this view?',
          style: GoogleFonts.ibmPlexSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppStateService.instance.clearActivity();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  static IconData _iconForRegister(String register) {
    switch (register.toLowerCase()) {
      case 'cutting':
        return Icons.content_cut_rounded;
      case 'production':
      case 'stitching':
        return Icons.precision_manufacturing_rounded;
      case 'ironing':
        return Icons.iron_rounded;
      case 'checking':
        return Icons.fact_check_rounded;
      case 'fabric stock':
        return Icons.inventory_2_rounded;
      case 'washing':
        return Icons.local_laundry_service_rounded;
      case 'buttoning & button holing':
      case 'buttoning':
        return Icons.radio_button_checked_rounded;
      case 'lay':
        return Icons.layers_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  static Color _colorForRegister(String register) {
    switch (register.toLowerCase()) {
      case 'cutting':
        return const Color(0xFF1565C0);
      case 'production':
      case 'stitching':
        return const Color(0xFFE65100);
      case 'ironing':
        return AppTheme.error;
      case 'checking':
        return AppTheme.success;
      case 'fabric stock':
        return const Color(0xFF00695C);
      case 'washing':
        return const Color(0xFF0277BD);
      case 'buttoning & button holing':
      case 'buttoning':
        return const Color(0xFF6D4C41);
      case 'lay':
        return const Color(0xFF6A1B9A);
      default:
        return AppTheme.primary;
    }
  }

  /// Format timestamp using IST-aware relative time
  String _formatTime(DateTime istTimestamp) {
    return ISTUtils.relativeTime(istTimestamp);
  }

  @override
  Widget build(BuildContext context) {
    final svc = AppStateService.instance;
    final cleared = svc.activityCleared;
    final activities = svc.recentActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            if (!cleared && activities.isNotEmpty)
              TextButton.icon(
                onPressed: _clearActivity,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: Text(
                  'Clear',
                  style: GoogleFonts.ibmPlexSans(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.mutedText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (cleared)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 40,
                  color: AppTheme.mutedText.withAlpha(100),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activity cleared',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => AppStateService.instance.restoreActivity(),
                  child: Text(
                    'Restore',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 36,
                    color: AppTheme.mutedText.withAlpha(80),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No activity yet.\nLog an entry in any register to see it here.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppTheme.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(activities.length, (i) {
                final item = activities[i];
                final register = item['register'] as String? ?? '';
                final styleNo = item['styleNo'] as String? ?? '';
                final actor = item['actor'] as String? ?? '';
                final quantity = item['quantity'] as int?;
                // timestamp is stored as IST DateTime (set via ISTUtils.now())
                final timestamp =
                    item['timestamp'] as DateTime? ?? ISTUtils.now();
                final icon = _iconForRegister(register);
                final color = _colorForRegister(register);
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withAlpha(31),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, size: 18, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$register entry — $styleNo',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (actor.isNotEmpty) actor,
                                    if (quantity != null) '$quantity pcs',
                                  ].join(' · '),
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11,
                                    color: AppTheme.mutedText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(timestamp),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < activities.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}
