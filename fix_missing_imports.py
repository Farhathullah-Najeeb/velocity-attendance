import os
import glob
import re

for filepath in glob.glob("lib/features/**/*.dart", recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if file uses AppScaffold but lacks the import
    if 'AppScaffold' in content and 'app_scaffold.dart' not in content:
        # Determine relative path to app_scaffold.dart
        # For admin/screens -> ../../shared/widgets/app_scaffold.dart
        # If it's a deeper file we might need ../../../ etc, but all our files are at level 4.
        # Let's just use the absolute package import instead to be bulletproof!
        # Wait, the package name is flutter_app? Or attendance_frontend?
        # Let's check pubspec.yaml for the name, but since we don't know it, we can just use the relative path based on the directory depth.
        depth = filepath.count('/') - 1 # 'lib/' is 1
        # 'lib/features/admin/screens/admin_dashboard_screen.dart' has 4 slashes -> depth 4.
        # Needs to go up 2 directories to reach features/
        # Wait, from features/admin/screens, up 1 is admin, up 2 is features.
        # Then shared/widgets/app_scaffold.dart
        rel_import = "../../shared/widgets/app_scaffold.dart"
        
        # Strip out any broken imports first
        content = re.sub(r"import \\*'.*app_scaffold\.dart\\*'.*\n", "", content)
        
        # Add the import after the first import
        content = re.sub(r'(import .*;\n)', r'\1import \'' + rel_import + '\';\n', content, count=1)
        
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Added import to {filepath}")
