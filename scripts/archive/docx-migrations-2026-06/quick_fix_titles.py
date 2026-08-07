#!/usr/bin/env python3
"""Quick fix remaining DOCX titles"""
import shutil, os, sys
from docx import Document

base = r'C:\Users\Administrator\Desktop\Project\claudeproject\solution-practices'

updates = [
    (r'practices\headroom-claude-code\hk\Headroom-ClaudeCode-Deployment-Guide.docx',
     'Headroom + Claude Code', 'Claude Code + Headroom, the Frugal Coding Assistant'),
    (r'release\headroom-claude-code\hk\Headroom-ClaudeCode-Deployment-Guide.docx',
     'Headroom + Claude Code', 'Claude Code + Headroom, the Frugal Coding Assistant'),
    (r'practices\headroom-claude-code\hk\Headroom-ClaudeCode-部署指南.docx',
     'Headroom + Claude Code', 'Claude Code + Headroom，更省的编程助手'),
    (r'practices\aitoearn\cn\AiToEarn-部署指南.docx',
     'AiToEarn', 'AiToEarn，AI 赋能的内容营销平台'),
    (r'practices\aitoearn\hk\AiToEarn-Deployment-Guide.docx',
     'AiToEarn', 'AiToEarn，AI-Powered Content Marketing Platform'),
    (r'practices\aitoearn\hk\AiToEarn-部署指南.docx',
     'AiToEarn', 'AiToEarn，AI 赋能的内容营销平台'),
]

for rel, old, new in updates:
    path = os.path.join(base, rel)
    if not os.path.exists(path):
        print(f'SKIP: {rel}')
        continue
    tmp = path + '.tmp'
    try:
        shutil.copy2(path, tmp)
        doc = Document(tmp)
        changed = False
        for p in doc.paragraphs:
            for r in p.runs:
                if old in r.text:
                    r.text = r.text.replace(old, new)
                    changed = True
        if changed:
            doc.save(tmp)
            shutil.copy2(tmp, path)
            os.remove(tmp)
            print(f'OK: {rel}')
        else:
            os.remove(tmp)
            print(f'NOCHANGE: {rel}')
    except Exception as e:
        print(f'ERR: {rel} -> {e}')
        if os.path.exists(tmp):
            os.remove(tmp)
print('Done!')
