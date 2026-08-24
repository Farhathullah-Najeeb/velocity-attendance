import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/providers/auth_provider.dart';

import 'core/router/app_router.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AttendanceApp()));
}

class AttendanceApp extends ConsumerStatefulWidget {
  const AttendanceApp({super.key});

  @override
  ConsumerState<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends ConsumerState<AttendanceApp> {
  final _appRouter = AppRouter();
  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.isLoading) return;

      final isLoggedIn = next.user != null;
      if (!isLoggedIn) {
        _appRouter.replaceAll([const LoginRoute()]);
        return;
      }

      // If we just logged in
      if (previous?.user == null && isLoggedIn) {
        if (next.user!.role == 'EMPLOYEE') {
          _appRouter.replaceAll([
            AppShellRoute(children: [const EmployeeDashboardRoute()]),
          ]);
        } else {
          _appRouter.replaceAll([
            AppShellRoute(children: [const AdminDashboardRoute()]),
          ]);
        }
      }
    });

    return MaterialApp.router(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.config(),
    );
  }
}
