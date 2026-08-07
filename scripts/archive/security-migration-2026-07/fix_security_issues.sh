#!/bin/bash
# 安全修复脚本 - 修复调试信息泄露和敏感信息问题

set -e

echo "=== 开始安全修复 ==="

# 1. 修复脚本中的调试信息泄露
echo "1. 修复脚本中的调试信息泄露..."
FILES_TO_FIX=(
    "assets/demo/dify-knowledgebase-cn/dify_search_css.sh"
    "assets/demo/dify-standalone-cn/dify_search.sh"
    "assets/demo/hermes-standalone-cn/hermesagent_install.sh"
)

for file in "${FILES_TO_FIX[@]}"; do
    if [ -f "$file" ]; then
        echo "  修复 $file"
        # 移除 DEBUG trap 中的 set -x
        sed -i 's/trap.*DEBUG//g' "$file"
        # 移除单独的 set -x
        sed -i '/^set -x$/d' "$file"
        # 添加适当的日志记录
        if ! grep -q "exec >" "$file"; then
            sed -i '2i# 日志记录到文件\nexec 1>>"$LOGFILE" 2>&1' "$file"
        fi
    else
        echo "  警告: $file 不存在"
    fi
done

# 2. 检查 Terraform 文件中的敏感变量
echo ""
echo "2. 检查 Terraform 敏感变量标记..."
TF_FILES=$(find . -name "*.tf" -type f ! -path "./node_modules/*" ! -path "./.next/*")

for tf_file in $TF_FILES; do
    if grep -q "variable.*password\|variable.*secret\|variable.*key" "$tf_file"; then
        echo "  检查 $tf_file"
        # 检查是否标记为敏感
        if ! grep -q "sensitive.*=.*true" "$tf_file"; then
            echo "    警告: 发现敏感变量但未标记为 sensitive = true"
            # 这里可以自动修复，但需要谨慎
            # sed -i '/variable.*password\|variable.*secret\|variable.*key/ {n;s/$/\n  sensitive   = true/}' "$tf_file"
        fi
    fi
done

# 3. 检查硬编码的凭据
echo ""
echo "3. 检查硬编码凭据..."
grep -r "password.*=.*['\"].*['\"]" --include="*.tf" --include="*.sh" --include="*.py" . 2>/dev/null | \
    grep -v node_modules | grep -v ".next" | while read -r line; do
    echo "  警告: 发现硬编码凭据 - $line"
done

# 4. 检查文件权限
echo ""
echo "4. 检查脚本文件权限..."
find . -name "*.sh" -type f ! -path "./node_modules/*" ! -path "./.next/*" -exec ls -la {} \; | \
    awk '{if ($1 !~ /^..x/) print "  警告: " $9 " 缺少执行权限"}'

# 5. 添加缺失的 shebang
echo ""
echo "5. 检查 Python 文件 shebang..."
PY_FILES=$(find . -name "*.py" -type f ! -path "./node_modules/*" ! -path "./.next/*" ! -name "__init__.py")

for py_file in $PY_FILES; do
    if [ ! -s "$py_file" ]; then
        continue  # 跳过空文件
    fi
    if ! head -1 "$py_file" | grep -q "^#!/usr/bin/env python"; then
        echo "  修复 $py_file"
        # 检查文件是否以 import 或 from 开头
        if head -1 "$py_file" | grep -q "^import\|^from"; then
            # 在文件开头添加 shebang
            sed -i '1i#!/usr/bin/env python3' "$py_file"
        fi
    fi
done

echo ""
echo "=== 安全修复完成 ==="
echo ""
echo "建议手动检查的项目:"
echo "1. 确认所有敏感变量都标记为 sensitive = true"
echo "2. 检查所有脚本中的硬编码凭据"
echo "3. 验证文件权限设置"
echo "4. 审查 .gitignore 配置"