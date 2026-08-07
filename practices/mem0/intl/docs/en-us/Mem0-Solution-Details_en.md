# Mem0 Solution Details

> **Document Type:** Huawei Cloud Solution Practices — Solution Details
> **Scope:** `intl` / Multi-Region / `standard`

## 1. Solution Overview

This solution deploys Mem0 in a single VPC across multiple international regions (ap-southeast-1, ap-southeast-2, ap-southeast-3, af-south-1, af-north-1, la-north-2, sa-brazil-1, tr-west-1). A single Ubuntu 24.04 ECS runs Mem0 API, PostgreSQL (pgvector), and Mem0 Dashboard via Docker Compose. An EIP is bound to the ECS; the Mem0 API is accessible via public TCP `8888`, and the Dashboard via public TCP `3000`. LLM and Embedding services are configured by the customer after deployment through the Dashboard or local configuration file.

Mem0 (62.6k GitHub Stars, Apache 2.0 License, Y Combinator S24) is a universal memory layer for AI Agents, providing persistent, learnable memory for AI applications. It supports multi-level memory (User/Session/Agent), intelligent retrieval, entity linking, and temporal-aware queries.

Ideal for scenarios requiring persistent memory for AI applications, personalized interactions, and context-aware experiences.

## 2. Architecture & Data Flow

```text
Internet
   │
EIP
   │
Ubuntu 24.04 ECS（1 node, c7n.2xlarge.2, 100 GiB GPSSD）
  └─ Docker Compose
       ├─ Mem0 API（FastAPI, :8000, mapped to public :8888）
       ├─ PostgreSQL + pgvector（:5432, internal only）
       └─ Mem0 Dashboard（Next.js, :3000）

Customer's LLM / Embedding Services
              ▲  Configured post-deployment via Dashboard or /opt/mem0/.env
```

The template creates and binds an EIP. The security group opens Mem0 API TCP `8888` and Dashboard TCP `3000` to the public internet. After deployment, access the API at `http://<EIP>:8888` and the Dashboard at `http://<EIP>:3000`.

## 3. Delivered Content

| Scope | Content |
|---|---|
| Cloud Resources | 1 VPC (`172.16.0.0/16`), 1 subnet (`172.16.1.0/24`), security group, EIP, 1 ECS |
| Runtime | Docker Engine, Docker Compose, Mem0 API, PostgreSQL + pgvector, Mem0 Dashboard |
| Network | API TCP `8888` and Dashboard TCP `3000` open to internet; PostgreSQL TCP `5432` internal only; SSH TCP `22` restricted to Huawei CloudShell source `121.36.59.153/32` |
| Data | PostgreSQL named volume `mem0_postgres_data`; Mem0 history named volume `mem0_history_data` |
| Secrets | Database password and JWT secret auto-generated on ECS during startup, stored in `/opt/mem0/.env` with `0600` permissions |
| Security | JWT authentication and API Key access control enabled |

## 4. Usage & Operations Boundaries

- Customers must configure their chosen LLM and Embedding service API Keys in the Dashboard's Configuration page or `/opt/mem0/.env` (default OpenAI). The template does not create LLM or Embedding services.
- Mem0 uses OpenAI `gpt-5-mini` as the default LLM and `text-embedding-3-small` as the default embedding model. You can switch to Anthropic Claude or Google Gemini in the Dashboard.
- All services, PostgreSQL data, and persistent directories reside on a single ECS. Before maintenance, upgrade, or stack deletion, back up data according to your recovery requirements and verify restoration.
- The system disk is set to not delete automatically on ECS termination. After stack deletion, verify retained disks in the console and check for any residual charges.
- Production recommendations: configure TLS termination (via reverse proxy or ELB), schedule regular PostgreSQL backups, and set up request log pruning.

## 5. Excluded Capabilities

This standard edition does not include HA, RDS, ELB, TLS, auto-backup, cross-AZ/cross-Region disaster recovery, or LLM/Embedding services. No cost, performance, availability, or recovery time commitments are provided.

See [Mem0 Deployment Guide](Mem0-Deployment-Guide_en.md) for deployment instructions.
