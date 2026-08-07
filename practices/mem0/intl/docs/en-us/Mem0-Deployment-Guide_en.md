# Mem0, Universal Memory Layer for AI Agents — Deployment Guide

> **Document Type:** Huawei Cloud Solution Practices — Deployment Guide
> **Document Version:** 1.0
> **Release Date:** 2026-08-06
> **Applicable Site:** intl (International)
> **Applicable Regions:** ap-southeast-1 / ap-southeast-2 / ap-southeast-3 / af-south-1 / af-north-1 / la-north-2 / sa-brazil-1 / tr-west-1

## 1. Solution Overview

Mem0 is a universal memory layer for AI Agents, providing persistent, learnable memory for AI applications. This solution uses Huawei Cloud Resource Formation Service (RFS) to create a single stack in your chosen region, deploying a self-hosted Mem0 service.

### 1.1 Use Cases

- **Persistent AI Assistant Memory:** Add cross-session user preferences and history to AI assistants for personalized interactions.
- **Customer Support Systems:** Retain customer conversation history and preferences across multiple service interactions.
- **RAG Application Memory Layer:** Add user-level memory management to Retrieval-Augmented Generation applications.
- **Multi-Agent Collaboration:** Multiple agents share a unified memory layer for consistent collaboration context.

### 1.2 Solution Architecture

```text
Internet
  │
EIP
  │
ECS（Ubuntu 24.04, Docker Compose）
  ├─ Mem0 API :8888（FastAPI service）
  ├─ PostgreSQL + pgvector :5432（vector store）
  └─ Mem0 Dashboard :3000（management UI）
```

The standard edition creates 1 VPC, 1 subnet, 1 security group, 1 EIP, and 1 ECS in a single RFS stack. The ECS runs 3 containers via Docker Compose. PostgreSQL data and Mem0 history data are stored in Docker volumes on the ECS system disk.

The template opens TCP 8888 (API) and 3000 (Dashboard) to the public internet. SSH port 22 is restricted to the Cloud Shell source specified in the template. The API uses HTTP without TLS termination — restrict the security group source and add HTTPS for production use.

### 1.3 Advantages

- **Single-stack delivery:** Managed by one RFS stack for easy plan review, deployment, and teardown.
- **One-click deployment:** Automatically installs Docker, clones the repository, builds images, and starts the full Mem0 stack.
- **Auto-generated secrets:** Database password and JWT secret are randomly generated on the ECS during deployment, never passed through template variables.
- **Multi-LLM support:** Defaults to OpenAI; switch to Anthropic, Gemini, or other providers via the Dashboard.

### 1.4 Constraints & Limitations

- Mem0 requires an LLM API Key to function (default OpenAI). Configure the API Key in the Dashboard or `/opt/mem0/.env` after deployment.
- Verify account status, service permissions, resource quotas, and target specifications are available in the chosen region before deployment.
- First deployment requires building Docker images, approximately 10-15 minutes.
- This is a single-ECS architecture with no compute, database, or cache high availability.
- Deleting the ECS/stack removes the system disk and its local Docker volume data.

### 1.5 Launch Information

```text
Type: RFS One-click Deployment
Site: intl (International)
Regions: ap-southeast-1 / ap-southeast-2 / ap-southeast-3 / af-south-1 / af-north-1 / la-north-2 / sa-brazil-1 / tr-west-1
```

## 2. Resource & Cost Planning

The tables below do not include fixed prices. Cloud service prices vary by region, specification, billing mode, purchase duration, discounts, and actual usage. Use the RFS execution plan and Huawei Cloud Price Calculator for real-time estimates before deployment. All tables exclude LLM Provider API call fees.

### 2.1 Pay-per-Use (PostPaid)

| Resource | Template Configuration | Qty | Billing Verification |
|---|---|---:|---|
| VPC, Subnet, Security Group | `172.16.0.0/16`, 1 subnet | 1 each | Check execution plan for independent fees |
| ECS | `c7n.2xlarge.2`, Ubuntu 24.04 | 1 | Pay-per-use instance duration |
| ECS System Disk | GPSSD, default 100 GB | 1 | Capacity and duration |
| EIP & Bandwidth | Dynamic BGP, default 200 Mbit/s, traffic-based | 1 | Internet traffic and associated EIP fees |

### 2.2 Subscription (PrePaid)

| Resource | Template Configuration | Qty | Billing Verification |
|---|---|---:|---|
| ECS & System Disk | `charging_mode=prePaid`; period by `charging_unit`, `charging_period` | 1 | Verify order and execution plan |
| EIP & Bandwidth | Fixed `postPaid`, traffic-based; not switched to prePaid | 1 | Actual internet traffic |
| VPC, Subnet, Security Group | Same as pay-per-use | 1 each | Check execution plan |

> **Cost Disclaimer:** Estimated costs are for reference only. Actual costs depend on selected specifications, billing mode, discounts, and actual usage. Refer to your final Huawei Cloud bill. Use the [Huawei Cloud Price Calculator](https://www.huaweicloud.com/pricing/) for real-time estimates.

## 3. Implementation Steps

### 3.1 Preparation

1. Register and verify your Huawei Cloud account. Ensure no outstanding payments or freezes.
2. Confirm RFS, VPC, EIP, and ECS permissions in your chosen region.
3. Configure an IAM permission delegation for RFS with least-privilege principles. See [Creating a Stack](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0003.html).
4. Verify quotas: at least 1 VPC, 1 EIP, and 1 ECS.
5. Prepare an OpenAI API Key (or configure Anthropic/Gemini later via Dashboard).
6. Generate an ECS root password using a cryptographically secure random generator:

   ```bash
   openssl rand -base64 16
   ```

### 3.2 Quick Deployment

1. Log in to the Huawei Cloud console. Navigate to "Resource Formation Service RFS > Stacks > Create Stack".
2. Upload the `deploying-mem0.tf` file for your chosen region.
3. Fill in all variables from the table below. Defaults are as defined in the Terraform template.

| Parameter | Default | Description |
|---|---|---|
| `solution_name` | `mem0-memory-layer` | Resource name prefix; 4-24 chars, lowercase letter start, only lowercase letters, digits, hyphens |
| `ecs_flavor` | `c7n.2xlarge.2` | ECS specification; validated against `c7n.{U}xlarge.{G}` format |
| `ecs_password` | empty | **Sensitive**; ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special chars |
| `openai_api_key` | empty | **Sensitive**; OpenAI API Key for default LLM and Embedding models |
| `system_disk_size` | `100` | System disk GB, range 40-1024 |
| `bandwidth_size` | `200` | EIP bandwidth Mbit/s, range 1-300, traffic billing |
| `charging_mode` | `postPaid` | `postPaid` (pay-per-use) or `prePaid` (subscription) |
| `charging_unit` | `month` | Subscription period unit: `month` or `year` |
| `charging_period` | `1` | Purchase period; 1-9 for monthly, 1-3 for yearly |

4. Select the permission delegation, review advanced settings and deletion protection.
5. It is recommended to create an execution plan first to review resources and real-time cost estimates before deploying the stack.
6. After the stack shows deployment complete, check the `access_info` output. Wait for the ECS startup script to finish (~10-15 minutes), then use the API, Dashboard, and API Docs URLs provided.

### 3.3 Getting Started & Verification

Copy the URLs from the RFS `access_info` output:

```bash
export MEM0_API='Copy API base URL from access_info (e.g., http://123.xxx.xxx.xxx)'
export MEM0_DASHBOARD='Copy Dashboard URL from access_info'
```

#### Verify API Health

```bash
curl --fail --silent --show-error "$MEM0_API:8888/docs"
```

Expect a Swagger UI HTML page in response.

#### Initial Dashboard Setup

1. Open the Dashboard URL `http://<EIP>:3000` in your browser.
2. On first access, register an admin account (email, password, name).
3. After logging in, go to Settings > API Keys and create an API Key.
4. Go to the Configuration page and verify the default LLM and Embedder settings (uses `OPENAI_API_KEY` by default).

#### Test the Mem0 API

```bash
export API_KEY='API Key from Dashboard'

curl -X POST "$MEM0_API:8888/memories" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "I like hiking"}], "user_id": "test-user"}'
```

Search memories:

```bash
curl -X POST "$MEM0_API:8888/search" \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "outdoor activities", "user_id": "test-user"}'
```

### 3.4 Configuring LLM and Embedding Services

After deployment, configure your LLM using either method:

**Method 1: Dashboard Configuration**

Log in to the Dashboard > Configuration, select an LLM provider (OpenAI/Anthropic/Gemini), enter the API Key, and save.

**Method 2: Direct Configuration File Edit**

```bash
sudoedit /opt/mem0/.env
sudo chmod 0600 /opt/mem0/.env
```

Modify or add the following variables:

```bash
# OpenAI (default)
OPENAI_API_KEY=sk-...

# Or Anthropic
# ANTHROPIC_API_KEY=sk-ant-...

# Or Google Gemini
# GOOGLE_API_KEY=...
```

After modification, restart the Mem0 service:

```bash
cd /opt/mem0
docker compose restart mem0
```

### 3.5 Troubleshooting

| Symptom | Check |
|---|---|
| Stack complete but API unreachable | Check `/var/log/mem0-bootstrap.log`, `docker compose ps`, and container logs under `/opt/mem0/`; verify 8888/3000 security group source matches your access point |
| Dashboard cannot connect to API | Verify `NEXT_PUBLIC_API_URL` is `http://localhost:8888` and the mem0 container is running |
| API returns `provider_auth_failed` | LLM provider API Key not configured; configure via Dashboard or `/opt/mem0/.env` |
| Memory add/search is slow | pgvector index takes time to build; verify ECS specification meets recommendations |
| Docker image pull failure | Check ECS outbound network connectivity; use `docker compose logs` for specific errors |

### 3.6 Quick Uninstall

1. Back up any memory data and PostgreSQL data you wish to retain, and verify restoration.
2. In the RFS console, select the target stack and perform stack deletion.
3. Confirm deletion as prompted, and monitor resource events until complete.
4. Verify in the VPC, EIP, and ECS consoles that no resources or records remain, to avoid residual charges.

> PostgreSQL data and Mem0 history data are stored in Docker volumes on the ECS system disk. The template configures disks to be deleted with the ECS. Complete data retention procedures before deletion.

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|---|---|
| Mem0 | Universal memory layer for AI Agents, providing persistent, learnable memory for LLM applications |
| pgvector | PostgreSQL vector similarity search extension for storing and retrieving memory embeddings |
| RFS | Resource Formation Service; manages cloud resource stack lifecycle via Terraform templates |
| EIP | Elastic IP; provides public internet access for ECS |
| GPSSD | General Purpose SSD, a Huawei Cloud EVS disk type |
| JWT | JSON Web Token; token format for API authentication |

### 4.2 Reference Documentation

- [Mem0 Official Documentation](https://docs.mem0.ai)
- [Mem0 GitHub Repository](https://github.com/mem0ai/mem0)
- [Mem0 Research Paper](https://arxiv.org/abs/2504.19413) (Building Production-Ready AI Agents with Scalable Long-Term Memory)
- [Huawei Cloud RFS Creating a Stack](https://support.huaweicloud.com/intl/en-us/usermanual-aos/rf_04_0003.html)
- [Huawei Cloud Price Calculator](https://www.huaweicloud.com/pricing/)

## 5. Revision History

| Release Date | Revision Description |
|---|---|
| 2026-08-06 | Initial version based on `deploying-mem0.tf` for intl multi-region standard edition. |
