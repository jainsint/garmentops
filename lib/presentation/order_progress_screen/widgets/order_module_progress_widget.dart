import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../routes/app_routes.dart';
import '../order_progress_screen.dart';

class OrderModuleProgressWidget extends StatelessWidget {
  final OrderData order;

  const OrderModuleProgressWidget({required this.order, super.key});

  static const List<_ModuleSpec> _moduleSpecs = [
    _ModuleSpec(
      name: 'Fabric Stock',
      icon: Icons.bolt_rounded,
      color: Color(0xFF00695C),
      registerIndex: 0,
    ),
    _ModuleSpec(
      name: 'Lay Register',
      icon: Icons.layers_rounded,
      color: Color(0xFF6A1B9A),
      registerIndex: 1,
    ),
    _ModuleSpec(
      name: 'Cutting',
      icon: Icons.content_cut_rounded,
      color: Color(0xFF1565C0),
      registerIndex: 2,
    ),
    _ModuleSpec(
      name: 'Production',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xFFE65100),
      registerIndex: 4,
    ),
    _ModuleSpec(
      name: 'Buttoning & Button Holing',
      icon: Icons.radio_button_checked_rounded,
      color: Color(0xFF6D4C41),
      registerIndex: 5,
    ),
    _ModuleSpec(
      name: 'Washing',
      icon: Icons.local_laundry_service_rounded,
      color: Color(0xFF0277BD),
      registerIndex: 6,
      isWashing: true,
    ),
    _ModuleSpec(
      name: 'Ironing',
      icon: Icons.iron_rounded,
      color: Color(0xFFC62828),
      registerIndex: 8,
    ),
    _ModuleSpec(
      name: 'Checking',
      icon: Icons.fact_check_rounded,
      color: Color(0xFF2E7D32),
      registerIndex: 7,
    ),
    _ModuleSpec(
      name: 'Packing',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF4E342E),
      registerIndex: 9,
    ),
    _ModuleSpec(
      name: 'Dispatch',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF1A237E),
      registerIndex: null,
    ),
  ];

  StatusType _statusForProgress(int p) {
    if (p >= 100) return StatusType.complete;
    if (p > 0) return StatusType.inProgress;
    return StatusType.pending;
  }

  String _labelForProgress(int p) {
    if (p >= 100) return 'Done';
    if (p > 0) return '$p%';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_moduleSpecs.length, (i) {
          final spec = _moduleSpecs[i];
          final progress = order.moduleProgress[spec.name] ?? 0;
          final status = _statusForProgress(progress);
          return Column(
            children: [
              _ModuleProgressRow(
                spec: spec,
                progress: progress,
                status: status,
                progressLabel: _labelForProgress(progress),
                onTap: spec.registerIndex != null
                    ? () => _navigateToRegister(context, spec)
                    : null,
              ),
              if (i < _moduleSpecs.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  void _navigateToRegister(BuildContext context, _ModuleSpec spec) {
    if (spec.isWashing) {
      context.push('${AppRoutes.homeScreen}/washing');
    } else if (spec.registerIndex != null) {
      context.push(AppRoutes.registerEntryScreen, extra: spec.registerIndex);
    }
  }
}

class _ModuleSpec {
  final String name;
  final IconData icon;
  final Color color;
  final int? registerIndex;
  final bool isWashing;

  const _ModuleSpec({
    required this.name,
    required this.icon,
    required this.color,
    required this.registerIndex,
    this.isWashing = false,
  });
}

class _ModuleProgressRow extends StatelessWidget {
  final _ModuleSpec spec;
  final int progress;
  final StatusType status;
  final String progressLabel;
  final VoidCallback? onTap;

  const _ModuleProgressRow({
    required this.spec,
    required this.progress,
    required this.status,
    required this.progressLabel,
    this.onTap,
  });

  Color get _barColor {
    if (progress >= 100) return AppTheme.success;
    if (progress >= 60) return AppTheme.primary;
    if (progress > 0) return AppTheme.warning;
    return AppTheme.outlineVariantLight;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: spec.color.withAlpha(31),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(spec.icon, size: 18, color: spec.color),
            ),
            const SizedBox(width: 12),
            // Name + progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spec.name,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            progressLabel,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _barColor,
                              fontFeatures: [
                                const FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadgeWidget(status: status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 6,
                      backgroundColor: AppTheme.outlineVariantLight,
                      valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.mutedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
