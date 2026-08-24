files = [
    'lib/features/admin/screens/admin_dashboard_screen.dart',
    'lib/features/employee/screens/employee_leaves_screen.dart'
]

import re

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    if 'return Scaffold(' in content:
        content = content.replace('return Scaffold(', 'return AppScaffold(')
        
        rel_import = "../../shared/widgets/app_scaffold.dart"
        if 'app_scaffold.dart' not in content:
            content = re.sub(r'(import .*;\n)', r'\1import \'' + rel_import + '\';\n', content, count=1)
            
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")

