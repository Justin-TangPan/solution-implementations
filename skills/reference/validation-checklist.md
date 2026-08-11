# 模板验证清单（公共参考文档）

> `sac-quality` 使用本清单验证 SAC Practice；正式必需项以 `project.config.json` 和架构方案为准。

## 目录与模板

- 默认标准版位于 `practices/<practice>/<site>/<region>/`；仅同一 Region 有多个部署形态时使用 `<region>/<variant>/`；不建 `terraform/`，locale 仅用于 `intl/docs/<locale>/`。
- 每个 deployable instance 只有一个可加载 `.tf` 或 `.tf.json`，不得混用。
- 新 ECS 模板从基线顺序复制，保持 provider、变量、镜像、网络、EIP、ECS、outputs 的固定顺序。
- 每个变量都显式声明 `default`、`description`、`type`、`nullable`；`ecs_password` 还必须为 `sensitive = true`。只使用 Hermes 基线的对应 validation，密码由 RFS/ECS 原生校验。
- `required_providers` 是对象且只声明实际需要的 Provider；Provider 配置只包含 `region`。
- 资源命名来自 `var.solution_name` 或稳定用户输入，不使用 UUID 或随机 Provider。
- 标准模板使用全内联 `user_data`，不依赖远端安装脚本。
- Terraform heredoc 中 Shell 命令替换使用 `$()`；只对需保留给下游配置的 `${...}` 使用 `$${...}`。

## 部署逻辑

- 包管理命令非交互、可重复执行，并使用与站点匹配且已验证的软件源。
- `cn` 保留官方 Docker Hub 镜像名，通过已验证的 registry mirror 加速；`intl` 使用官方 Docker Hub 或 `ghcr.io`。
- 配置和有状态目录持久化；数据库初始化幂等，权限和 schema 完整。
- `user_data` 是单段内联 Bash，并保留 Hermes 基线形状；仅为上游已验证的运行方式修改运行时命令，任何偏离必须记录在 architecture contract。
- 有一个简短的 `access_instructions` 或 `access_info` 主输出；用户必须单独获取的 API 地址、SSH 命令、凭证查看命令、日志路径等使用独立、有意义的 `snake_case` outputs，不用 `|` 或其他装饰分隔符拼接。
- 所有 outputs 都不得包含密码、Token、生成的 Secret 或其他敏感值，也不为非必要信息增加输出。
- 变量、上游地址、端口、输出和清理行为与架构方案一致。

## 安全

- 不含 AK/SK、API Key、Token、私有端点或固定生产密码。
- 敏感变量必须声明 `sensitive = true`，不得进入 URL、output 或日志；既有模板因兼容性在 `user_data` 中传递密码时记录风险并限制作用域，不再作为项目级硬阻断。
- 公网入口和管理端口严格匹配架构方案；数据库等内部端口不做宽泛公网暴露。
- 容器不使用无依据的 `privileged`、Docker socket、host network 或危险宿主机挂载。
- 密码经安全输入或部署时生成，不因模板渲染、命令行或日志而泄露。

## 文档与国际化

- 文档名称、语言和目录符合 Practice Layout Contract；Hermes 指南必须覆盖官方 `hermes_01` 至 `hermes_08` 的概述、成本、准备、部署、开始使用、卸载和附录，方案详情必须覆盖官方方案页面的 Hero、优势、架构部署、应用场景、拓展和服务亮点。
- `cn` 提供中文文档；`intl` 同时提供 `zh-cn` 与 `en-us` 文档，并保持技术事实一致。
- `.extension` 与 Terraform 变量一致；国际站 `.extension` 同时提供中英文文案。
- Terraform output 的 `description` 使用简短纯 ASCII 文本；output 值避免 `|` 等装饰性分隔符和不必要的特殊字符。
- 文档中的参数、端口、输出、健康检查和故障排查均可从实现追溯，不含 TODO 或未解释占位符。

## 结果判定

- 静态检查不得冒充云上部署成功。
- 工具或环境失败与产品失败分开报告。
- 存在正式合同错误、安全门禁错误或不可部署项时 `passed=false`。
