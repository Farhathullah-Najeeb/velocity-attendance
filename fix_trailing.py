def fix_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
        
    # Remove trailing empty lines
    while lines and lines[-1].strip() == '':
        lines.pop()
        
    if lines and lines[-1].strip() == '}':
        # Check if it's an extra '}'. 
        # A quick way is to check the second to last line.
        # But actually, let's just count { and } in the file.
        content = "".join(lines)
        open_braces = content.count('{')
        close_braces = content.count('}')
        if close_braces > open_braces:
            lines.pop()
            with open(filepath, 'w') as f:
                f.write("".join(lines))
            print(f"Fixed {filepath}")

fix_file('lib/features/admin/screens/admin_dashboard_screen.dart')
fix_file('lib/features/employee/screens/employee_leaves_screen.dart')
