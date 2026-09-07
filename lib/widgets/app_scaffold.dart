import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool get _isAdmin => AuthService.instance.isAdmin;

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _NavItem(
      label: 'Registers',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment_rounded,
      branchIndex: 1,
    ),
    _NavItem(
      label: 'Orders',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      branchIndex: 2,
    ),
    _NavItem(
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      branchIndex: 3,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      branchIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _showRoleSwitchMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Role',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAdmin ? 'Admin' : 'Staff',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
              title: Text(
                'Sign Out',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthService.instance.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    if (isWide) {
      return _buildWideLayout(context);
    }

    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            AppBar(
              backgroundColor: AppTheme.surfaceLight,
              elevation: 0,
              scrolledUnderElevation: 2,
              titleSpacing: 16,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.navigationShell.goBranch(
                      0,
                      initialLocation: widget.navigationShell.currentIndex == 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.factory_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Jains Int.',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.onSurfaceLight,
                  ),
                  onPressed: () {},
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.onSurfaceLight,
                      ),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                    size: 22,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await AuthService.instance.logout();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppTheme.onSurfaceLight,
                    size: 26,
                  ),
                  tooltip: 'Menu',
                  onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
      body: widget.navigationShell,
      endDrawer: _buildEndDrawer(context, currentIndex, scaffoldKey),
    );
  }

  Widget _buildEndDrawer(
    BuildContext context,
    int currentIndex,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) {
    return Drawer(
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.navigationShell.goBranch(
                      0,
                      initialLocation: widget.navigationShell.currentIndex == 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.factory_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Jains Int.',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppTheme.mutedText,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Nav items
            ...List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isSelected = currentIndex == item.branchIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isSelected ? AppTheme.primaryContainer : null,
                  leading: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    size: 22,
                    color: isSelected ? AppTheme.primary : AppTheme.mutedText,
                  ),
                  title: Text(
                    item.label,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(); // close drawer
                    widget.navigationShell.goBranch(
                      item.branchIndex,
                      initialLocation:
                          item.branchIndex ==
                          widget.navigationShell.currentIndex,
                    );
                  },
                ),
              );
            }),
            const Spacer(),
            const Divider(height: 1),
            // Role / sign-out footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _isAdmin
                      ? AppTheme.primaryContainer
                      : const Color(0xFFE8F5E9),
                  child: Text(
                    _isAdmin ? 'AD' : 'FS',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _isAdmin
                          ? AppTheme.primary
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
                title: Text(
                  _isAdmin ? 'Admin' : 'Staff',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppTheme.error,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await AuthService.instance.logout();
                  },
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: AppTheme.surfaceLight,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  height: kToolbarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => widget.navigationShell.goBranch(
                          0,
                          initialLocation:
                              widget.navigationShell.currentIndex == 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.factory_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Jains Int.',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppTheme.mutedText,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ..._buildSidebarItems(context, currentIndex),
                const Spacer(),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _isAdmin
                        ? AppTheme.primaryContainer
                        : const Color(0xFFE8F5E9),
                    child: Text(
                      _isAdmin ? 'AD' : 'FS',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _isAdmin
                            ? AppTheme.primary
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  title: Text(
                    _isAdmin ? 'Admin' : 'Staff',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    onPressed: () => AuthService.instance.logout(),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  List<Widget> _buildSidebarItems(BuildContext context, int currentIndex) {
    final items = [
      (icon: Icons.home_rounded, label: 'Home', index: 0),
      (icon: Icons.list_alt_rounded, label: 'Registers', index: 1),
      (icon: Icons.receipt_long_rounded, label: 'Orders', index: 2),
      (icon: Icons.bar_chart_rounded, label: 'Reports', index: 3),
      (icon: Icons.person_rounded, label: 'Profile', index: 4),
    ];
    return items.map((item) {
      final isSelected = currentIndex == item.index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          tileColor: isSelected ? AppTheme.primaryContainer : null,
          leading: Icon(
            item.icon,
            size: 20,
            color: isSelected ? AppTheme.primary : AppTheme.mutedText,
          ),
          title: Text(
            item.label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primary : AppTheme.onSurfaceLight,
            ),
          ),
          onTap: () => widget.navigationShell.goBranch(
            item.index,
            initialLocation: item.index == widget.navigationShell.currentIndex,
          ),
        ),
      );
    }).toList();
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int branchIndex;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
  });
}
