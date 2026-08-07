#!/usr/bin/env python3
"""Update DOCX title pages with new naming convention (v2 - handles all formatting)"""

import os
import re
from docx import Document

BASE = r'C:\Users\Administrator\Desktop\Project\claudeproject\solution-practices'

# Map of replacements per file
files = [
    (r'practices\headroom-claude-code\cn\Headroom-ClaudeCode-部署指南.docx',
     [('Headroom + Claude Code — Context Compression for AI Coding One-Click Deployment',
       'Claude Code + Headroom，The Frugal Coding Assistant — One-Click Deployment'),
      ('Headroom + Claude Code', 'Claude Code + Headroom')]),
    (r'release\headroom-claude-code\hk\Headroom-ClaudeCode-部署指南.docx',
     [('Headroom + Claude Code', 'Claude Code + Headroom，更省的编程助手')]),
    (r'practices\headroom-claude-code\hk\Headroom-ClaudeCode-Deployment-Guide.docx',
     [('Headroom + Claude Code — Context Compression for AI Coding One-Click Deployment',
       'Claude Code + Headroom，The Frugal Coding Assistant — One-Click Deployment'),
      ('Headroom + Claude Code', 'Claude Code + Headroom')]),
    (r'release\headroom-claude-code\hk\Headroom-ClaudeCode-Deployment-Guide.docx',
     [('Headroom + Claude Code — Context Compression for AI Coding One-Click Deployment',
       'Claude Code + Headroom，The Frugal Coding Assistant — One-Click Deployment'),
      ('Headroom + Claude Code', 'Claude Code + Headroom')]),
    (r'practices\aitoearn\cn\AiToEarn-部署指南.docx',
     [('AiToEarn', 'AiToEarn，AI 赋能的内容营销平台')]),
    (r'practices\aitoearn\hk\AiToEarn-部署指南.docx',
     [('AiToEarn', 'AiToEarn，AI 赋能的内容营销平台')]),
    (r'practices\aitoearn\hk\AiToEarn-Deployment-Guide.docx',
     [('AiToEarn', 'AiToEarn，AI-Powered Content Marketing Platform')]),
    (r'release\litellm\hk\LiteLLM-部署指南.docx',
     [('Litellm — 统一 LLM 网关', 'LiteLLM，统一的 LLM 网关')]),
    (r'release\litellm\hk\LiteLLM-Deployment-Guide.docx',
     [('LiteLLM — Unified LLM Gateway', 'LiteLLM，The Unified LLM Gateway')]),
]

for rel_path, replacements in files:
    path = os.path.join(BASE, rel_path)
    if not os.path.exists(path):
        print(f'SKIP (not found): {rel_path}')
        continue
    doc = Document(path)
    modified = False
    for paragraph in doc.paragraphs:
        for old, new in replacements:
            if old in paragraph.text:
                # Replace text in each run that contains it
                for run in paragraph.runs:
                    if old in run.text:
                        run.text = run.text.replace(old, new)
                        modified = True
                # Also check for split runs (old text might span multiple runs)
                full_text = ''.join(r.text for r in paragraph.runs)
                if old in full_text and not modified:
                    # Reconstruct with replacement across runs - simpler:
                    # Just set first run to new text and clear others
                    runs_text = [r.text for r in paragraph.runs]
                    full = ''.join(runs_text)
                    if old in full:
                        new_full = full.replace(old, new)
                        # Distribute back
                        chars_used = 0
                        for ri, r in enumerate(paragraph.runs):
                            old_len = len(r.text)
                            if ri == 0:
                                r.text = new_full[:old_len]
                            else:
                                start = chars_used
                                end = chars_used + old_len
                                if start < len(new_full):
                                    r.text = new_full[start:end]
                                else:
                                    r.text = ''
                            chars_used += old_len
                        modified = True

    if modified:
        doc.save(path)
        print(f'OK: {rel_path}')
    else:
        print(f'NO MATCH: {rel_path}')

print('\nDone!')
