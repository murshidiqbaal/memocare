import os
import re
from pathlib import Path

# The absolute path to lib directory
lib_dir = Path(r"d:\vscode\memocare\memocare\lib")
package_name = "memocare"

def resolve_import(file_path, import_str):
    # This takes an import string like '../../core/utils.dart'
    # and the path to the current file (e.g. lib/screens/auth/login.dart)
    # and returns 'package:memocare/core/utils.dart'
    
    if import_str.startswith('package:') or import_str.startswith('dart:'):
        return import_str
        
    # It is a relative import. Resolve it against the file's dir.
    current_dir = file_path.parent
    target_file = (current_dir / import_str).resolve()
    
    # Check if target file is inside lib_dir
    try:
        rel_to_lib = target_file.relative_to(lib_dir)
        return f"package:{package_name}/{rel_to_lib.as_posix()}"
    except ValueError:
        # Not inside lib, keep as is
        return import_str

def process_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        def repl(match):
            prefix = match.group(1)
            import_str = match.group(2)
            resolved = resolve_import(file_path, import_str)
            return f"{prefix}'{resolved}'"
            
        # Pattern to match: import 'path' or export 'path'
        # We need to be careful with string boundaries.
        pattern = re.compile(r"(import\s+|export\s+|part\s+)'([^']+)'")
        new_content = pattern.sub(repl, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
    return False

def main():
    changed_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = Path(root) / file
                if process_file(file_path):
                    changed_count += 1
                    
    print(f"Changed {changed_count} files to use absolute imports.")

if __name__ == '__main__':
    main()
