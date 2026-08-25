/// RBAC permissions grouped by category for UI pickers.
class PermissionGroups {
  static const Map<String, List<String>> categories = {
    'Attendance': [
      'CHECK_IN',
      'CHECK_OUT',
      'APPROVE_ATTENDANCE',
      'REJECT_ATTENDANCE',
      'VIEW_PENDING_ATTENDANCE',
      'VIEW_MY_ATTENDANCE',
      'VIEW_ALL_ATTENDANCE',
    ],
    'Leaves': [
      'APPLY_LEAVE',
      'VIEW_MY_LEAVES',
      'VIEW_ALL_LEAVES',
      'APPROVE_LEAVE',
      'REJECT_LEAVE',
      'VIEW_LEAVE_BALANCE',
    ],
    'Overtime': [
      'REQUEST_OVERTIME',
      'VIEW_MY_OVERTIME',
      'VIEW_ALL_OVERTIME',
      'APPROVE_OVERTIME',
      'REJECT_OVERTIME',
    ],
    'Employees & Admins': [
      'MANAGE_EMPLOYEES',
      'VIEW_EMPLOYEES',
      'MANAGE_ADMINS',
    ],
    'Reports': [
      'VIEW_REPORTS',
      'EXPORT_REPORTS',
    ],
    'Sites': [
      'MANAGE_SITES',
      'VIEW_SITES',
      'ASSIGN_SITE',
    ],
    'Settings & Holidays': [
      'VIEW_SETTINGS',
      'MANAGE_SETTINGS',
      'VIEW_HOLIDAYS',
      'MANAGE_HOLIDAYS',
    ],
    'Roles': [
      'MANAGE_ROLES',
    ],
  };

  static String label(String permission) =>
      permission.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');

  static List<String> get allPermissions =>
      categories.values.expand((list) => list).toList();
}
