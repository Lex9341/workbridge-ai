import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/app_shell.dart';
import 'screens/workbridge_screens.dart';

void main() {
  runApp(const WorkBridgeApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => WorkBridgeShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const JobDiscoveryScreen(),
        ),
        GoRoute(
          path: '/tracker',
          builder: (context, state) => const JobTrackerScreen(),
        ),
        GoRoute(
          path: '/jobs/:id',
          builder: (context, state) =>
              JobDetailsScreen(jobId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/credentials',
          builder: (context, state) => const CredentialsScreen(),
        ),
        GoRoute(
          path: '/portfolio',
          builder: (context, state) => const PortfolioScreen(),
        ),
        GoRoute(
          path: '/resume',
          builder: (context, state) => const ResumeBuilderScreen(),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const ApplicationBuilderScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
      ],
    ),
  ],
);

class WorkBridgeApp extends StatelessWidget {
  const WorkBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'WorkBridge AI',
        debugShowCheckedModeBanner: false,
        theme: _theme,
        routerConfig: _router,
      ),
    );
  }
}

final _theme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff080b10),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff4db8ff),
    brightness: Brightness.dark,
    primary: const Color(0xff55c7ff),
    secondary: const Color(0xff48d7b7),
    surface: const Color(0xff101620),
    error: const Color(0xffff6b6b),
  ),
  fontFamily: 'Roboto',
  textTheme: Typography.whiteMountainView.apply(
    bodyColor: const Color(0xffe6edf7),
    displayColor: const Color(0xfff7fbff),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xff080b10),
    elevation: 0,
    centerTitle: false,
  ),
  cardTheme: CardThemeData(
    color: const Color(0xff111823),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xff223041)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xff0c121b),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xff253244)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xff55c7ff)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xff223041), thickness: 1),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xff55c7ff),
      foregroundColor: const Color(0xff06111a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xffd8e7f5),
      side: const BorderSide(color: Color(0xff31445b)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: Color(0xff172232),
    side: BorderSide(color: Color(0xff2b3e54)),
    labelStyle: TextStyle(color: Color(0xffe6edf7)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color(0xff0c121b),
    indicatorColor: Color(0xff17354a),
  ),
  useMaterial3: true,
);
