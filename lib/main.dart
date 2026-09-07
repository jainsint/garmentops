import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:workmanager/workmanager.dart' as wm;

import '../core/app_export.dart';
import '../services/auth_service.dart';
import '../services/offline_queue_service.dart';
import '../services/sync_service.dart';
import '../widgets/custom_error_widget.dart';
import './presentation/login_screen/login_screen.dart';
import './services/supabase_service.dart';

// Background task name
const String _dailySyncTask = 'garmentops.dailySync';

/// Called by Workmanager in a background isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  wm.Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _dailySyncTask) {
      final syncService = SyncService();
      await syncService.initialize();
      await syncService.syncNow();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Load persisted auth session
  await AuthService.instance.loadSession();

  // Initialize offline queue service
  await OfflineQueueService.instance.initialize();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // Initialize Workmanager for daily background sync
  await wm.Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  // Register a periodic task that runs once per day
  await wm.Workmanager().registerPeriodicTask(
    _dailySyncTask,
    _dailySyncTask,
    frequency: const Duration(hours: 24),
    constraints: wm.Constraints(networkType: wm.NetworkType.connected),
    existingWorkPolicy: wm.ExistingPeriodicWorkPolicy.keep,
  );

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  ]).then((value) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loggedIn = AuthService.instance.isLoggedIn;
    AuthService.instance.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() => _loggedIn = AuthService.instance.isLoggedIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'garmentops',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          home: _loggedIn
              ? _RouterWrapper()
              : LoginScreen(
                  onLoginSuccess: () {
                    setState(() => _loggedIn = true);
                  },
                ),
        );
      },
    );
  }
}

class _RouterWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Router(
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
      backButtonDispatcher: appRouter.backButtonDispatcher,
    );
  }
}
