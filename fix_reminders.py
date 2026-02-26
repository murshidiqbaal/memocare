import os
import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Replace `.remindAt` with `.reminderTime`
    # Replace `remindAt:` with `reminderTime:`
    content = re.sub(r'\bremindAt\b(?!:)', 'reminderTime', content)
    content = re.sub(r'\bremindAt\s*:', 'reminderTime:', content)

    # In Reminder(...) constructor, ensure caregiverId: is present. 
    def add_caregiver_id(m):
        full_match = m.group(0)
        if 'caregiverId:' not in full_match and 'patientId:' in full_match:
             return full_match.replace('patientId:', "caregiverId: '', patientId:")
        return full_match

    # A more resilient regex for nested parens might be needed,
    # but for simple new Reminder() it works.
    # It might be safer to replace `patientId: ` with `caregiverId: '', patientId: ` inside `Reminder(...)`
    # using a simple find / replace if the file contains `Reminder(`
    
    # We will just do a brute force search for `Reminder(` and inject caregiverId if missing.
    # Wait, dart regex match for `Reminder(` to closing `)`. 
    # Let's do a simple hack.
    content = re.sub(r'Reminder\s*\(([^)]*\))', lambda m: m.group(0).replace('patientId:', "caregiverId: '', \npatientId:") if 'caregiverId:' not in m.group(0) and 'patientId:' in m.group(0) else m.group(0), content)

    # Some `Reminder(` might be multiline so `[^)]+` will not match if the regex engine doesn't span newlines, or does but matches too greedily. Let's use `r'Reminder\s*\([\s\S]*?\)'`.
    content = re.sub(r'Reminder\s*\([\s\S]*?\)', lambda m: m.group(0).replace('patientId:', "caregiverId: '', patientId:") if 'caregiverId:' not in m.group(0) and 'patientId:' in m.group(0) else m.group(0), content)

    if content != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {path}")

for root, dirs, files in os.walk(r'd:\vscode\GTech\MemoCare\memocare\lib'):
    for f in files:
        if f.endswith('.dart'):
            fix_file(os.path.join(root, f))
