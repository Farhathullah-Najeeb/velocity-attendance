// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AdminApprovalsScreen]
class AdminApprovalsRoute extends PageRouteInfo<void> {
  const AdminApprovalsRoute({List<PageRouteInfo>? children})
    : super(AdminApprovalsRoute.name, initialChildren: children);

  static const String name = 'AdminApprovalsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminApprovalsScreen();
    },
  );
}

/// generated route for
/// [AdminAttendanceApprovalsScreen]
class AdminAttendanceApprovalsRoute extends PageRouteInfo<void> {
  const AdminAttendanceApprovalsRoute({List<PageRouteInfo>? children})
    : super(AdminAttendanceApprovalsRoute.name, initialChildren: children);

  static const String name = 'AdminAttendanceApprovalsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminAttendanceApprovalsScreen();
    },
  );
}

/// generated route for
/// [AdminDashboardScreen]
class AdminDashboardRoute extends PageRouteInfo<void> {
  const AdminDashboardRoute({List<PageRouteInfo>? children})
    : super(AdminDashboardRoute.name, initialChildren: children);

  static const String name = 'AdminDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminDashboardScreen();
    },
  );
}

/// generated route for
/// [AdminEmployeesScreen]
class AdminEmployeesRoute extends PageRouteInfo<void> {
  const AdminEmployeesRoute({List<PageRouteInfo>? children})
    : super(AdminEmployeesRoute.name, initialChildren: children);

  static const String name = 'AdminEmployeesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminEmployeesScreen();
    },
  );
}

/// generated route for
/// [AdminOvertimeScreen]
class AdminOvertimeRoute extends PageRouteInfo<void> {
  const AdminOvertimeRoute({List<PageRouteInfo>? children})
    : super(AdminOvertimeRoute.name, initialChildren: children);

  static const String name = 'AdminOvertimeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminOvertimeScreen();
    },
  );
}

/// generated route for
/// [AdminReportsScreen]
class AdminReportsRoute extends PageRouteInfo<void> {
  const AdminReportsRoute({List<PageRouteInfo>? children})
    : super(AdminReportsRoute.name, initialChildren: children);

  static const String name = 'AdminReportsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminReportsScreen();
    },
  );
}

/// generated route for
/// [AdminSettingsScreen]
class AdminSettingsRoute extends PageRouteInfo<void> {
  const AdminSettingsRoute({List<PageRouteInfo>? children})
    : super(AdminSettingsRoute.name, initialChildren: children);

  static const String name = 'AdminSettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AdminSettingsScreen();
    },
  );
}

/// generated route for
/// [AppShellScreen]
class AppShellRoute extends PageRouteInfo<void> {
  const AppShellRoute({List<PageRouteInfo>? children})
    : super(AppShellRoute.name, initialChildren: children);

  static const String name = 'AppShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppShellScreen();
    },
  );
}

/// generated route for
/// [ChangePasswordScreen]
class ChangePasswordRoute extends PageRouteInfo<void> {
  const ChangePasswordRoute({List<PageRouteInfo>? children})
    : super(ChangePasswordRoute.name, initialChildren: children);

  static const String name = 'ChangePasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ChangePasswordScreen();
    },
  );
}

/// generated route for
/// [EmployeeDashboardScreen]
class EmployeeDashboardRoute extends PageRouteInfo<void> {
  const EmployeeDashboardRoute({List<PageRouteInfo>? children})
    : super(EmployeeDashboardRoute.name, initialChildren: children);

  static const String name = 'EmployeeDashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmployeeDashboardScreen();
    },
  );
}

/// generated route for
/// [EmployeeHistoryScreen]
class EmployeeHistoryRoute extends PageRouteInfo<void> {
  const EmployeeHistoryRoute({List<PageRouteInfo>? children})
    : super(EmployeeHistoryRoute.name, initialChildren: children);

  static const String name = 'EmployeeHistoryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmployeeHistoryScreen();
    },
  );
}

/// generated route for
/// [EmployeeLeavesScreen]
class EmployeeLeavesRoute extends PageRouteInfo<void> {
  const EmployeeLeavesRoute({List<PageRouteInfo>? children})
    : super(EmployeeLeavesRoute.name, initialChildren: children);

  static const String name = 'EmployeeLeavesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmployeeLeavesScreen();
    },
  );
}

/// generated route for
/// [EmployeeOvertimeScreen]
class EmployeeOvertimeRoute extends PageRouteInfo<void> {
  const EmployeeOvertimeRoute({List<PageRouteInfo>? children})
    : super(EmployeeOvertimeRoute.name, initialChildren: children);

  static const String name = 'EmployeeOvertimeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmployeeOvertimeScreen();
    },
  );
}

/// generated route for
/// [EmployeeProfileEditScreen]
class EmployeeProfileEditRoute
    extends PageRouteInfo<EmployeeProfileEditRouteArgs> {
  EmployeeProfileEditRoute({
    Key? key,
    required User employee,
    List<PageRouteInfo>? children,
  }) : super(
         EmployeeProfileEditRoute.name,
         args: EmployeeProfileEditRouteArgs(key: key, employee: employee),
         initialChildren: children,
       );

  static const String name = 'EmployeeProfileEditRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EmployeeProfileEditRouteArgs>();
      return EmployeeProfileEditScreen(key: args.key, employee: args.employee);
    },
  );
}

class EmployeeProfileEditRouteArgs {
  const EmployeeProfileEditRouteArgs({this.key, required this.employee});

  final Key? key;

  final User employee;

  @override
  String toString() {
    return 'EmployeeProfileEditRouteArgs{key: $key, employee: $employee}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmployeeProfileEditRouteArgs) return false;
    return key == other.key && employee == other.employee;
  }

  @override
  int get hashCode => key.hashCode ^ employee.hashCode;
}

/// generated route for
/// [ForgotPasswordScreen]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [LiveMonitoringScreen]
class LiveMonitoringRoute extends PageRouteInfo<void> {
  const LiveMonitoringRoute({List<PageRouteInfo>? children})
    : super(LiveMonitoringRoute.name, initialChildren: children);

  static const String name = 'LiveMonitoringRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LiveMonitoringScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfileScreen();
    },
  );
}

/// generated route for
/// [RegisterEmployeeScreen]
class RegisterEmployeeRoute extends PageRouteInfo<void> {
  const RegisterEmployeeRoute({List<PageRouteInfo>? children})
    : super(RegisterEmployeeRoute.name, initialChildren: children);

  static const String name = 'RegisterEmployeeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterEmployeeScreen();
    },
  );
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterScreen();
    },
  );
}

/// generated route for
/// [ResetPasswordScreen]
class ResetPasswordRoute extends PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    Key? key,
    required String token,
    List<PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, token: token),
         rawPathParams: {'token': token},
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ResetPasswordRouteArgs>(
        orElse: () =>
            ResetPasswordRouteArgs(token: pathParams.getString('token')),
      );
      return ResetPasswordScreen(key: args.key, token: args.token);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, required this.token});

  final Key? key;

  final String token;

  @override
  String toString() {
    return 'ResetPasswordRouteArgs{key: $key, token: $token}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResetPasswordRouteArgs) return false;
    return key == other.key && token == other.token;
  }

  @override
  int get hashCode => key.hashCode ^ token.hashCode;
}
