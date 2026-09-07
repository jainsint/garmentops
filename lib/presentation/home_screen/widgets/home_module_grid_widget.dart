import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class _ModuleData {
  final String name;
  final IconData icon;
  final String lastUpdated;
  final int pendingCount;
  final Color color;

  const _ModuleData({
    required this.name,
    required this.icon,
    required this.lastUpdated,
    required this.pendingCount,
    required this.color,
  });
}

class HomeModuleGridWidget extends StatelessWidget {
  final int crossAxisCount;
  final void Function(int moduleIndex) onModuleTap;

  const HomeModuleGridWidget({
    this.crossAxisCount = 2,
    required this.onModuleTap,
    super.key,
  });

  static const List<_ModuleData> _modules = [
    _ModuleData(
      name: 'Cutting',
      icon: Icons.content_cut_rounded,
      lastUpdated: 'Today 09:14',
      pendingCount: 0,
      color: Color(0xFF1565C0),
    ),
    _ModuleData(
      name: 'Lay Register',
      icon: Icons.layers_rounded,
      lastUpdated: 'Yesterday',
      pendingCount: 1,
      color: Color(0xFF6A1B9A),
    ),
    _ModuleData(
      name: 'Production',
      icon: Icons.precision_manufacturing_rounded,
      lastUpdated: 'Today 10:00',
      pendingCount: 3,
      color: Color(0xFFE65100),
    ),
    _ModuleData(
      name: 'Ironing',
      icon: Icons.iron_rounded,
      lastUpdated: 'Today 09:45',
      pendingCount: 0,
      color: Color(0xFFC62828),
    ),
    _ModuleData(
      name: 'Checking',
      icon: Icons.fact_check_rounded,
      lastUpdated: 'Today 08:55',
      pendingCount: 2,
      color: Color(0xFF2E7D32),
    ),
    _ModuleData(
      name: 'Fabric Stock',
      icon: Icons.inventory_2_rounded,
      lastUpdated: 'Today 08:00',
      pendingCount: 0,
      color: Color(0xFF00838F),
    ),
    _ModuleData(
      name: 'Planner',
      icon: Icons.calendar_month_rounded,
      lastUpdated: 'Today 07:30',
      pendingCount: 0,
      color: Color(0xFF558B2F),
    ),
    _ModuleData(
      name: 'Washing',
      icon: Icons.local_laundry_service_rounded,
      lastUpdated: 'Today 07:00',
      pendingCount: 0,
      color: Color(0xFF00695C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: crossAxisCount == 4 ? 1.1 : 1.45,
      ),
      itemCount: _modules.length,
      itemBuilder: (context, i) {
        final module = _modules[i];
        return _ModuleTile(data: module, onTap: () => onModuleTap(i));
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _ModuleData data;
  final VoidCallback onTap;

  const _ModuleTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: data.color.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: data.color.withAlpha(31),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, size: 20, color: data.color),
                  ),
                  if (data.pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${data.pendingCount}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
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
                    data.lastUpdated,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
