# Contributing to SAC Solution Practice

感谢您考虑为 SAC 项目贡献代码！本文档提供了贡献指南。

## 项目概述

SAC (Solution Practices) 是一个华为云解决方案实践仓库，以 Skills 为核心交付物。核心工作流：
1. AI 架构师评估方案可行性
2. AI 开发生成 Terraform 模板 + 安装脚本
3. AI 质量审查验证模板语法与安全风险
4. AI 文档生成部署指南

## 目录结构

```
skills/                                    # 核心交付物
├── sac-project/SKILL.md                   # 项目范围与配置规则
├── sac-architecture/SKILL.md              # 架构设计规则
├── sac-implementation/SKILL.md            # 实现规则
├── sac-quality/SKILL.md                   # 质量审查规则
├── sac-documentation/SKILL.md             # 文档生成规则
├── sac-deep-search/SKILL.md               # 可选：深度搜索
├── sac-page-enhance/SKILL.md              # 可选：页面增强
├── query-huawei-cloud-prices/SKILL.md     # 可选：价格查询
└── reference/                             # 共享参考文档
scripts/tests/                             # 质量门禁测试
project.config.json                        # Skills 注册表与能力定义
```

Practice 产物（Terraform 模板、部署指南等）存放在本地 `practices/` 目录，不纳入 git 跟踪。

## 开发流程

### 1. 新方案提交流程

```bash
# 在本地 practices/ 下创建方案目录
mkdir -p practices/my-app/cn/cn-north-4

# 编辑 Terraform 模板
# 编辑安装脚本

# 运行测试验证
python -m scripts.tests.runner

# 提交 Skills 变更（如有）
git add skills/
git commit -m "feat: add my-app skill rules"
```

### 2. 代码规范

**Terraform 规范：**
- 所有密码/密钥变量必须设置 `sensitive = true`
- 密码变量不加 `validation` 块，由云 API 策略校验
- `validation` 块只能引用自身变量
- 安全组规则必须限制源 IP，不允许 `0.0.0.0/0`
- 变量必须包含 `description` 字段
- Region 代码统一使用标准命名（`cn-north-4`、`ap-southeast-1`）
- 输出值使用独立 `output` 块，不用 `|` 或逗号拼接

**Shell 脚本规范：**
- 必须包含 `set -euo pipefail`
- 必须包含健康检查步骤
- 必须使用 `mkdir -p` 确保幂等性
- 禁止硬编码密码/Token
- 禁止 `curl | bash` 高危管道安装
- 日志输出到 `/var/log/{app}-deploy/`

### 3. 提交信息格式

```
<type>: <简短描述> (<version>)

- <具体改动 1>
- <具体改动 2>

Co-Authored-By: Claude <noreply@anthropic.com>
```

类型：`feat` / `fix` / `refactor` / `test` / `docs` / `chore`

### 4. 测试

提交前运行：
```bash
# Skills 结构测试
npm test

# Python 质量门禁
python -m scripts.tests.runner
```

## 安全注意事项

- **不要** 在代码中提交真实 AK/SK 或密码
- **不要** 提交 `.tfvars` 文件到仓库
- 敏感信息应通过环境变量或 RFS 参数传递
- 发现安全漏洞请直接联系维护者

## 问题反馈

提交 Issue 时请包含：
- 方案名称和区域
- 具体错误信息
- `npm test` 和 `python -m scripts.tests.runner` 的输出
