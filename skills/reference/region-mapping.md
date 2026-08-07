# 区域代码映射表（公共参考文档）

> 本文档是 SAC 项目站点与 Region 映射的权威来源。

## 站点与目录模型

| 站点 | 默认 Region | 说明 |
|------|------------|------|
| `cn` | `cn-north-4`（华北-北京四） | 中国站，中文文档 |
| `intl` | `ap-southeast-3`（亚太-新加坡） | 国际站，中英双语文档 |

默认实现目录只有 `site/region` 两个维度：

```text
practices/<practice>/cn/<region>/deploying-<practice>.tf
practices/<practice>/intl/<region>/deploying-<practice>.tf
```

同一 Region 存在多个部署形态时，才改为 `<region>/<variant>/deploying-<practice>.tf`；只有默认单机标准版时不建 `standard/`。任何形态都不建 `terraform/` 包装目录。

语言不是实现维度。国际站共享一份 Terraform，双语参数文案放在 `.extension`，双语正文分别放在 `intl/docs/zh-cn/` 和 `intl/docs/en-us/`。禁止新建 `intl/<locale>/<region>/<variant>/`，也禁止把 `hk` 当作站点。

## Region 代码与显示名称

| Region | 显示名称 | 站点 |
|--------|----------|------|
| `cn-north-4` | 华北-北京四 | `cn` |
| `ap-southeast-1` | 中国-香港 | `intl` |
| `ap-southeast-2` | 亚太-曼谷 | `intl` |
| `ap-southeast-3` | 亚太-新加坡 | `intl` |
| `ap-southeast-5` | 亚太-马尼拉 | `intl` |
| `af-north-1` | 非洲-开罗 | `intl` |
| `af-south-1` | 非洲-约翰内斯堡 | `intl` |
| `la-north-2` | 拉美-墨西哥城2 | `intl` |
| `la-south-2` | 拉美-圣地亚哥 | `intl` |
| `sa-brazil-1` | 拉美-圣保罗 | `intl` |
| `tr-west-1` | 土耳其-伊斯坦布尔 | `intl` |

未列出的 Region 必须先核验站点归属、服务可用性和规格可用性，再加入架构方案；不得凭 Region 前缀推断交付支持。

## 站点差异

| 维度 | `cn` | `intl` |
|------|------|--------|
| Docker CE 源 | `mirrors.huaweicloud.com/docker-ce` | `download.docker.com` |
| pip 源 | 已验证的国内镜像 | 官方 PyPI |
| Docker Hub | 保留官方镜像名，通过已验证 registry mirror 加速 | 官方 Docker Hub / `ghcr.io` |
| 文档 | `cn/docs/` 中文 | `intl/docs/zh-cn/` 与 `intl/docs/en-us/` |

标准 Practice 的部署逻辑全部内联在 Terraform `user_data` 中。
