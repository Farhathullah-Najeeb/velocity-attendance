import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/shared/app_shell.dart';
import '../../features/employee/screens/employee_dashboard_screen.dart';
import '../../features/employee/screens/employee_leaves_screen.dart';
import '../../features/employee/screens/employee_history_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_approvals_screen.dart';
import '../../features/admin/screens/admin_employees_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/admin/screens/admin_roles_screen.dart';
import '../../features/admin/screens/super_admin_admins_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';

import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/setup_super_admin_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';

import '../../features/attendance/screens/admin_attendance_approvals_screen.dart';
import '../../features/attendance/screens/live_monitoring_screen.dart';
import '../../features/employees/screens/register_employee_screen.dart';
import '../../features/employees/screens/employee_profile_edit_screen.dart';
import '../../features/overtime/screens/employee_overtime_screen.dart';
import '../../features/overtime/screens/request_overtime_screen.dart';
import '../../features/overtime/screens/admin_overtime_screen.dart';
import '../../models/user.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LoginRoute.page, initial: true),
        AutoRoute(page: SetupSuperAdminRoute.page),
        AutoRoute(page: RegisterRoute.page),
        AutoRoute(page: ForgotPasswordRoute.page),
        AutoRoute(page: ResetPasswordRoute.page, path: '/reset-password/:token'),
        AutoRoute(page: ChangePasswordRoute.page),
        AutoRoute(page: PendingApprovalRoute.page),
        AutoRoute(page: RegisterEmployeeRoute.page),
        AutoRoute(page: EmployeeProfileEditRoute.page),
        AutoRoute(
          page: AppShellRoute.page,
          children: [
            AutoRoute(page: EmployeeDashboardRoute.page),
            AutoRoute(page: EmployeeLeavesRoute.page),
            AutoRoute(page: EmployeeHistoryRoute.page),
            AutoRoute(page: EmployeeOvertimeRoute.page),
            AutoRoute(page: RequestOvertimeRoute.page),
            AutoRoute(page: AdminDashboardRoute.page),
            AutoRoute(page: AdminApprovalsRoute.page),
            AutoRoute(page: AdminEmployeesRoute.page),
            AutoRoute(page: AdminReportsRoute.page),
            AutoRoute(page: AdminAttendanceApprovalsRoute.page),
            AutoRoute(page: LiveMonitoringRoute.page),
            AutoRoute(page: AdminOvertimeRoute.page),
            AutoRoute(page: AdminSettingsRoute.page),
            AutoRoute(page: AdminRolesRoute.page),
            AutoRoute(page: SuperAdminAdminsRoute.page),
            AutoRoute(page: ProfileRoute.page),
            AutoRoute(page: NotificationsRoute.page),
          ],
        ),
      ];
}
