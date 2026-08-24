import re

files_to_fix = [
    'lib/features/attendance/screens/admin_attendance_approvals_screen.dart',
    'lib/features/admin/screens/admin_approvals_screen.dart',
    'lib/features/admin/screens/admin_employees_screen.dart',
    'lib/features/admin/screens/admin_reports_screen.dart',
    'lib/features/admin/screens/admin_settings_screen.dart',
    'lib/features/admin/screens/admin_dashboard_screen.dart',
    'lib/features/employee/screens/employee_dashboard_screen.dart',
    'lib/features/employee/screens/employee_history_screen.dart',
    'lib/features/employee/screens/employee_leaves_screen.dart',
    'lib/features/overtime/screens/admin_overtime_screen.dart',
    'lib/features/overtime/screens/employee_overtime_screen.dart',
    'lib/features/attendance/screens/live_monitoring_screen.dart',
]

for filepath in files_to_fix:
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        # We want to find the first padding argument in a ListView or SingleChildScrollView.
        # It's usually right after ListView( or ListView.builder( or SingleChildScrollView(
        
        # Let's use a regex that looks for:
        # (ListView|ListView\.builder|SingleChildScrollView)\s*\(\s*padding:\s*(const EdgeInsets\.[a-zA-Z0-9_\(\)\., ]+),
        
        def replacer(match):
            widget = match.group(1)
            original_padding = match.group(2)
            # Remove const if it exists, since AppScaffold.getScrollPadding returns a dynamic value
            clean_padding = original_padding
            if clean_padding.startswith('const '):
                # actually, we can pass it exactly as is: basePadding: const EdgeInsets.all(16)
                pass
                
            return f"{widget}(\n              padding: AppScaffold.getScrollPadding(context, basePadding: {original_padding}),"
            
        new_content = re.sub(r'(ListView|ListView\.builder|SingleChildScrollView)\s*\(\s*padding:\s*(const EdgeInsets\.[a-zA-Z0-9_\(\)\., ]+),', replacer, content, count=1)
        
        if new_content != content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f"Fixed padding in {filepath}")
        else:
            print(f"Could not find matching padding in {filepath}")
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        
