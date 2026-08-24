import os
import re

files_to_update = [
    'lib/features/admin/screens/admin_employees_screen.dart',
    'lib/features/admin/screens/admin_reports_screen.dart',
    'lib/features/admin/screens/admin_settings_screen.dart',
    'lib/features/attendance/screens/live_monitoring_screen.dart',
]

for filepath in files_to_update:
    if not os.path.exists(filepath):
        continue
        
    with open(filepath, 'r') as f:
        content = f.read()

    # Add import if not present
    if 'app_scaffold.dart' not in content:
        content = re.sub(r'(import .*;\n)', r'\1import \'../../shared/widgets/app_scaffold.dart\';\n', content, count=1)

    # Replace child: Scaffold( and return Scaffold(
    content = content.replace('child: Scaffold(', 'child: AppScaffold(')
    content = content.replace('return Scaffold(', 'return AppScaffold(')
    content = content.replace('backgroundColor: AppTheme.lightBackground,', '')

    with open(filepath, 'w') as f:
        f.write(content)
        
    print(f"Refactored {filepath}")
