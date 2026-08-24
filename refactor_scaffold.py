import os
import re

files_to_update = [
    'lib/features/admin/screens/admin_dashboard_screen.dart',
    'lib/features/admin/screens/admin_employees_screen.dart',
    'lib/features/admin/screens/admin_approvals_screen.dart',
    'lib/features/attendance/screens/admin_attendance_approvals_screen.dart',
    'lib/features/employee/screens/employee_dashboard_screen.dart',
    'lib/features/employee/screens/employee_leaves_screen.dart',
    'lib/features/employee/screens/employee_history_screen.dart',
    'lib/features/overtime/screens/admin_overtime_screen.dart',
    'lib/features/overtime/screens/employee_overtime_screen.dart',
]

import_statement = "import '../../shared/widgets/app_scaffold.dart';"
# Adjust import paths for different depths if needed, but wait!
# admin/screens/ -> ../../shared/widgets/app_scaffold.dart
# attendance/screens/ -> ../../shared/widgets/app_scaffold.dart
# employee/screens/ -> ../../shared/widgets/app_scaffold.dart
# overtime/screens/ -> ../../shared/widgets/app_scaffold.dart

for filepath in files_to_update:
    if not os.path.exists(filepath):
        continue
        
    with open(filepath, 'r') as f:
        content = f.read()

    # Only add import if not already there
    if 'app_scaffold.dart' not in content:
        # Find first import and insert after it
        content = re.sub(r'(import .*;\n)', r'\1import \'../../shared/widgets/app_scaffold.dart\';\n', content, count=1)

    # Replace Scaffold with AppScaffold in the build method of the main screen
    # Since there might be other Scaffolds (e.g. in dialogs? No usually they use Dialog), this regex looks for the main return.
    # We can just replace all `return Scaffold(` with `return AppScaffold(`
    content = content.replace('return Scaffold(', 'return AppScaffold(')
    content = content.replace('return const Scaffold(', 'return const AppScaffold(')
    content = content.replace('backgroundColor: AppTheme.lightBackground,', '') # AppScaffold provides this

    # Revert padding 120
    content = content.replace('const SizedBox(height: 120),', '')
    content = content.replace('const SizedBox(height: 120)', '')
    content = content.replace('padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120)', 'padding: const EdgeInsets.all(16)')
    content = content.replace('padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120)', 'padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24)')
    content = content.replace('const SliverToBoxAdapter(child: SizedBox(height: 120)),', '')

    with open(filepath, 'w') as f:
        f.write(content)
        
    print(f"Refactored {filepath}")
