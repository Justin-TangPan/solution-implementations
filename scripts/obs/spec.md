# OBS 交付上传规范

> 把单个 practice 的交付产物上传到华为云 OBS **私有桶**做测试归档。

---

## 1. 凭证（硬约束）

| 环境变量 | 说明 |
|:--|:--|
| `OBS_AK` | 访问密钥 ID |
| `OBS_SK` | 访问密钥 |
| `OBS_ENDPOINT` | 桶 endpoint（如 `obs.cn-north-4.myhuaweicloud.com`） |
| `OBS_BUCKET` | 桶名 |

**铁律：**
- 凭证**只从环境变量读**，绝不硬编码、绝不落盘、绝不打印
- 仓库内**不得出现** AK/SK/endpoint/bucket 的真实值
- `.gitignore` 已排除 `.obs/`、`.obs-credentials` 兜底

设置方式（每次会话）：
```bash
export OBS_AK=YourAK
export OBS_SK=YourSK
export OBS_ENDPOINT=obs.cn-north-4.myhuaweicloud.com
export OBS_BUCKET=your-private-bucket
```

---

## 2. 路径约定

```
obs://<bucket>/sac/<practice>/<site>/<locale?>/<region>/<deploy_type>/<version>/<files>
```

示例：
```
obs://my-bucket/sac/litellm/cn/cn-north-4/standard/0.9.1.1/litellm-0.9.1.1-cn-cn-north-4-standard.zip
obs://my-bucket/sac/supabase/intl/en-us/ap-southeast-1/standard/0.9.1.1/manifest.json
```

- `practice`：方案名（litellm, supabase, ...）
- `site`：`cn` 或 `intl`
- `locale`：国际站必须包含 `en-us` 或 `zh-cn`；中国站无此层
- `region`：华为云区域（cn-north-4, ap-southeast-1, ...）
- `deploy_type`：`standard` | `ha`
- `version`：测试上传使用 SAC 四级测试版本（如 0.9.1.1）

国际站的 locale 是对象身份的一部分。不得让 `en-us` 与 `zh-cn` 共用同一前缀、归档名或
manifest，否则第二次上传会覆盖第一次上传。

---

## 3. 必含文件

### manifest.json

每个版本目录下必须有 `manifest.json`，字段：

```json
{
  "practice": "litellm",
  "region": "cn-north-4",
  "deploy_type": "standard",
  "version": "0.3.2",
  "git_commit": "6b4500c",
  "generated_at": "2026-06-30T12:00:00Z",
  "file_count": 12,
  "files": [
    { "path": "deploying-litellm.tf", "size": 4096, "sha256": "..." },
    { "path": "scripts/install_litellm.sh", "size": 2048, "sha256": "..." }
  ]
}
```

### 交付包 zip

`<practice>-<version>-<region>-<deploy_type>.zip`，内含 `manifest.json` + 全部源文件。

---

## 4. 排除清单

打包时自动排除：

| 模式 | 原因 |
|:--|:--|
| `.git/` | 版本元数据 |
| `__pycache__/` | Python 缓存 |
| `node_modules/` | 依赖 |
| `.next/`、`.terraform/` | 构建产物 |
| `*.env` | 环境配置（可能含密钥） |
| `*.pyc`、`*.pyo` | 编译缓存 |
| `*.tfstate`、`*.tfstate.backup` | Terraform 状态（含敏感信息） |
| `package-lock.json` | 锁文件 |
| `.DS_Store` | macOS 元数据 |

---

## 5. 预上传密钥扫描

上传前自动复用 `scripts/tests/` 的检查框架，对目标 practice 运行：
- `tf_syntax` — 硬编码 AK/SK、安全组过宽、BOM 头
- `scripts` — Shell 脚本中的硬编码密码/Token、curl|bash

**扫到任何 ERROR 级问题 → 立即中止，不上传。** 需修复后重传。

---

## 6. 覆盖策略

目标路径已存在时：
1. 下载远端 `manifest.json`
2. 对比本地与远端文件 sha256，打印：新增 / 删除 / 修改 / 未变
3. 提示输入 `yes` 确认后才覆盖
4. `--force` 可跳过确认（慎用）

目的：防止误覆盖不同内容，同时允许有意识地重传。

上传完成后，工具必须回读 zip 与 manifest，并比较 SHA-256。当前 OBS SDK 使用
`loadStreamInMemory`；工具同时兼容仍使用 `loadStreamInMS` 的旧 SDK。

---

## 7. 用法

```bash
# 干跑（不连 OBS，只看将传什么）
python -m scripts.obs.upload \
  --practice litellm --region cn-north-4 \
  --version 0.3.2 --deploy-type standard --dry-run

# 实际上传
python -m scripts.obs.upload \
  --practice litellm --region cn-north-4 \
  --version 0.3.2 --deploy-type standard

# 强制覆盖（跳过确认）
python -m scripts.obs.upload \
  --practice litellm --region cn-north-4 \
  --version 0.3.2 --deploy-type standard --force
```

---

## 8. 安全检查清单

- [ ] 凭证只在环境变量里，`git status` 看不到凭证文件
- [ ] `grep -r OBS_SK scripts/` 无硬编码
- [ ] 桶策略是 **私有**（非 public-read）
- [ ] 上传日志只记 `obs://` 路径，不记 AK/SK
- [ ] manifest.json 不含任何凭证字段
