import os
import glob

for filepath in glob.glob("lib/features/**/*.dart", recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if r"import \'" in content:
        content = content.replace(r"import \'", "import '")
        content = content.replace(r"\';", "';")
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Fixed {filepath}")
