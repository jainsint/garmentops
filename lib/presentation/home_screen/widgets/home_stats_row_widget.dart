import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../services/app_state_service.dart';

class HomeStatsRowWidget extends StatefulWidget {
  final bool isAdmin;
  const HomeStatsRowWidget({required this.isAdmin, super.key});

  @override
  State<HomeStatsRowWidget> createState() => _HomeStatsRowWidgetState();
}

class _HomeStatsRowWidgetState extends State<HomeStatsRowWidget> {
  int _cuttingTotal = 0;
  int _productionTotal = 0;
  int _activeStyles = 0;
  bool _loading = true;
  DateTime? _lastLoaded;

  @override
  void initState() {
    super.initState();
    _loadStats();
    AppStateService.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    // Reload when a register entry is written
    final lastWrite = AppStateService.instance.lastRegisterWrite;
    if (_lastLoaded == null || lastWrite.isAfter(_lastLoaded!)) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.getTodayCuttingTotal(),
        SupabaseService.instance.getTodayProductionTotal(),
        SupabaseService.instance.getActiveStylesCount(),
      ]);
      if (mounted) {
        setState(() {
          _cuttingTotal = results[0];
          _productionTotal = results[1];
          _activeStyles = results[2];
          _loading = false;
          _lastLoaded = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.isAdmin
        ? [
            _StatData(
              icon: Icons.inventory_2_outlined,
              label: 'Active Styles',
              value: _loading ? '—' : '$_activeStyles',
              unit: 'styles',
              color: AppTheme.primary,
              containerColor: AppTheme.primaryContainer,
            ),
            _StatData(
              icon: Icons.precision_manufacturing_outlined,
              label: "Today's Output",
              value: _loading ? '—' : '$_productionTotal',
              unit: 'pcs',
              color: AppTheme.success,
              containerColor: AppTheme.successContainer,
            ),
            _StatData(
              icon: Icons.content_cut_rounded,
              label: "Today's Cutting",
              value: _loading ? '—' : '$_cuttingTotal',
              unit: 'pcs',
              color: AppTheme.warning,
              containerColor: AppTheme.warningContainer,
            ),
          ]
        : [
            _StatData(
              icon: Icons.content_cut_rounded,
              label: "Today's Cutting",
              value: _loading ? '—' : '$_cuttingTotal',
              unit: 'pcs',
              color: AppTheme.primary,
              containerColor: AppTheme.primaryContainer,
            ),
            _StatData(
              icon: Icons.precision_manufacturing_outlined,
              label: "Today's Output",
              value: _loading ? '—' : '$_productionTotal',
              unit: 'pcs',
              color: AppTheme.success,
              containerColor: AppTheme.successContainer,
            ),
            _StatData(
              icon: Icons.inventory_2_outlined,
              label: 'Active Styles',
              value: _loading ? '—' : '$_activeStyles',
              unit: 'styles',
              color: AppTheme.warning,
              containerColor: AppTheme.warningContainer,
            ),
          ];

    return Row(
      children: List.generate(stats.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            child: _StatCard(data: stats[i], loading: _loading),
          ),
        );
      }),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color containerColor;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.containerColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool loading;
  const _StatCard({required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: data.containerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: data.color,
                    ),
                  )
                : Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            data.unit,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
