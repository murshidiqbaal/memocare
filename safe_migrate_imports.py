import os
import re

package_name = "memocare"
lib_dir = os.path.abspath("lib")

def absolute_to_package(file_path, import_path):
    if import_path.startswith("package:") or import_path.startswith("dart:") or import_path.startswith("http"):
        return None
    
    # Resolve relative path
    file_dir = os.path.dirname(file_path)
    binary_path = os.path.abspath(os.path.join(file_dir, import_path))
    
    if binary_path.startswith(lib_dir):
        relative_to_lib = os.path.relpath(binary_path, lib_dir).replace("\\", "/")
        return f"package:{package_name}/{relative_to_lib}"
    return None

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    def replacer(match):
        keyword = match.group(1)
        import_path = match.group(2)
        new_path = absolute_to_package(file_path, import_path)
        if new_path:
            return f"{keyword} '{new_path}'"
        return match.group(0)

    # Match import '...'; or export '...'; or part '...';
    new_content = re.sub(r"(import|export|part)\s+'([^']+)'", replacer, content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

# 1. Convert all imports to absolute
count = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            if process_file(os.path.join(root, file)):
                count += 1

print(f"Converted {count} files to absolute imports.")
