#!/usr/bin/env python3
"""Force update headroom release HK CN docx"""
import os, shutil
from docx import Document

base = r'C:\Users\Administrator\Desktop\Project\claudeproject\solution-practices'
rel = r'release\headroom-claude-code\hk'

src = os.path.join(base, rel, 'Headroom-ClaudeCode-部署指南.docx')
tmp = os.path.join(base, rel, '_temp_save.docx')
bak = os.path.join(base, rel, '_bak.docx')

# Backup
shutil.copy2(src, bak)

# Copy to temp
shutil.copy2(src, tmp)

# Edit
doc = Document(tmp)
modified = False
for p in doc.paragraphs:
    for r in p.runs:
        if 'Headroom + Claude Code' in r.text:
            r.text = r.text.replace('Headroom + Claude Code', 'Claude Code + Headroom，更省的编程助手')
            modified = True
            print('Fixed:', r.text[:60])

doc.save(tmp)
print('Temp save OK, modified:', modified)

# Copy back
shutil.copy2(tmp, src)
os.remove(tmp)
os.remove(bak)
print('Done!')
