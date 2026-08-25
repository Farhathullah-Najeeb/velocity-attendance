import os
import re

def replace_in_file(path, replacements):
    try:
        with open(path, 'r') as f:
            content = f.read()
            
        for old, new in replacements:
            content = content.replace(old, new)
            
        with open(path, 'w') as f:
            f.write(content)
    except FileNotFoundError:
        pass

# Fix withOpacity
replace_in_file('lib/core/theme/app_theme.dart', [('.withOpacity(0.5)', '.withValues(alpha: 0.5)')])
replace_in_file('lib/features/shared/screens/notifications_screen.dart', [('.withOpacity(0.1)', '.withValues(alpha: 0.1)')])
replace_in_file('lib/features/shared/widgets/loading_overlay.dart', [
    ('.withOpacity(0.3)', '.withValues(alpha: 0.3)'),
    ('.withOpacity(0.5)', '.withValues(alpha: 0.5)')
])

# Remove avoid_print in dio_client and login
replace_in_file('lib/core/network/dio_client.dart', [('print(', '// print(')])
replace_in_file('lib/features/auth/screens/login_screen.dart', [('print(', '// print(')])

# Remove dead code in employee_dashboard_screen.dart
replace_in_file('lib/features/employee/screens/employee_dashboard_screen.dart', [
    ('checkInTimeStr ?? \'--\'', 'checkInTimeStr'),
    ('checkOutTimeStr ?? \'--\'', 'checkOutTimeStr')
])

print("Fixes applied.")
