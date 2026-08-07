# SAC Codex Adapter

`.codex/` 只把共享的 SAC Core 映射到 Codex 的角色与 Task Flow，不保存第二份业务规则。
Codex 从根 `AGENTS.md` 获取轻量路由，从 `.agents/skills/` 按需发现根 `skills/` 的权威内容。

```text
AGENTS.md
.agents/skills/          # SAC Core 的 Codex 发现入口
.codex/
├── config.toml          # Codex 子 Agent 并发配置
├── agents/              # Architect / Builder / Reviewer；旧名为兼容入口
└── workflows/           # 既有工作流名到三种能力角色的映射
```

## 原生角色

- `sac_architect`：只读研究、架构设计和架构合同。
- `sac_builder`：Terraform、文档和获授权的本地交付实现。
- `sac_reviewer`：只读质量、安全、架构/文档一致性及交付检查。

`sac_developer`、`sac_documenter`、`sac_tester`、`sac_security`、`sac_delivery` 仍可被旧调用方
使用，但均为 Deprecated 兼容别名；新任务不得默认路由到这些名称。

## 使用原则

小型任务由主 Agent 直接承担一个能力角色。只有独立工作能降低上下文噪声时才启动子 Agent；
大型架构变更采用 Architect → Builder → Reviewer，修复再回到 Builder。平台适配不改变
Terraform 事实、SAC Core 规则或授权边界。
