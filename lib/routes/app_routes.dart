import 'package:go_router/go_router.dart';

import '../presentation/home_screen/home_screen.dart';
import '../presentation/order_progress_screen/order_progress_screen.dart';
import '../presentation/register_entry_screen/register_entry_screen.dart';
import '../presentation/washing_register_screen/washing_register_screen.dart';
import '../presentation/create_order_screen/create_order_screen.dart';
import '../presentation/reports_screen/reports_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String registerEntryScreen = '/register-entry-screen';
  static const String orderProgressScreen = '/order-progress-screen';
  static const String washingRegisterScreen = '/washing-register-screen';
  static const String createOrderScreen = '/create-order-screen';
  static const String reportsScreen = '/reports-screen';
  static const String profileScreen = '/profile-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.homeScreen,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'washing',
                  builder: (context, state) => const WashingRegisterScreen(),
                ),
                GoRoute(
                  path: 'create-order',
                  builder: (context, state) => const CreateOrderScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.initial,
              redirect: (context, state) => AppRoutes.homeScreen,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.registerEntryScreen,
              builder: (context, state) => const RegisterEntryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.orderProgressScreen,
              builder: (context, state) => const OrderProgressScreen(),
              routes: [
                GoRoute(
                  path: 'create-order',
                  builder: (context, state) => const CreateOrderScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reportsScreen,
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
