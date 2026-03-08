import os
import re

lib_dir = os.path.normcase(os.path.abspath(r"d:\vscode\memocare\memocare\lib"))
package_name = "dementia_care_app"

def resolve_import(file_path, import_str):
    if import_str.startswith('package:') or import_str.startswith('dart:') or import_str.startswith('http'):
        return import_str
        
    current_dir = os.path.dirname(os.path.abspath(file_path))
    target_file = os.path.normpath(os.path.join(current_dir, import_str))
    target_file_norm = os.path.normcase(target_file)
    
    if target_file_norm.startswith(lib_dir):
        rel_path_actual_case = target_file[len(lib_dir):].lstrip('\\/').replace('\\', '/')
        return f"package:{package_name}/{rel_path_actual_case}"
    
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
            
        pattern = re.compile(r"(import\s+|export\s+|part\s+)'([^']+)'")
        new_content = pattern.sub(repl, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
            
    except Exception as e:
        print(f"Error {file_path}: {e}")
    return False

def main():
    changed = 0
    lib_path = r"d:\vscode\memocare\memocare\lib"
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                if process_file(file_path):
                    changed += 1
                    
    print(f"Changed {changed} files to use absolute imports.")

if __name__ == '__main__':
    main()
