import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/offline_banner_widget.dart';
import './widgets/home_activity_feed_widget.dart';
import './widgets/home_module_grid_widget.dart';
import './widgets/home_order_progress_widget.dart';
import './widgets/home_stats_row_widget.dart';
import './widgets/home_week_calendar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _isAdmin => AuthService.instance.isAdmin;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          const OfflineBannerWidget(),
          Expanded(
            child: SafeArea(
              top: false,
              child: isTablet
                  ? _buildTabletLayout(theme)
                  : _buildPhoneLayout(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: HomeStatsRowWidget(isAdmin: _isAdmin),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: HomeWeekCalendarWidget(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildQuickActions(theme),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildSectionHeader(theme, 'Registers', null),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: HomeModuleGridWidget(
              onModuleTap: (moduleIndex) {
                if (moduleIndex == 7) {
                  context.push('${AppRoutes.homeScreen}/washing');
                } else {
                  context.push(
                    AppRoutes.registerEntryScreen,
                    extra: moduleIndex,
                  );
                }
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: _buildSectionHeader(
              theme,
              'Order Progress',
              () => context.push(AppRoutes.orderProgressScreen),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: HomeOrderProgressWidget(
              onOrderTap: (_) => context.push(AppRoutes.orderProgressScreen),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: HomeActivityFeedWidget(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: HomeStatsRowWidget(isAdmin: _isAdmin),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: HomeWeekCalendarWidget(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: _buildQuickActions(theme),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: _buildSectionHeader(theme, 'Registers', null),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: HomeModuleGridWidget(
                    crossAxisCount: 4,
                    onModuleTap: (moduleIndex) {
                      if (moduleIndex == 7) {
                        context.push('${AppRoutes.homeScreen}/washing');
                      } else {
                        context.push(
                          AppRoutes.registerEntryScreen,
                          extra: moduleIndex,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: AppTheme.surfaceLight,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
                    child: _buildSectionHeader(
                      theme,
                      'Order Progress',
                      () => context.push(AppRoutes.orderProgressScreen),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: HomeOrderProgressWidget(
                      onOrderTap: (_) =>
                          context.push(AppRoutes.orderProgressScreen),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 16, 24),
                    child: HomeActivityFeedWidget(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    VoidCallback? onSeeAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                'See All',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    if (!_isAdmin) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_shopping_cart_rounded,
            label: 'Create\nOrder',
            color: const Color(0xFF2E7D32),
            onTap: () => context.push('${AppRoutes.homeScreen}/create-order'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
