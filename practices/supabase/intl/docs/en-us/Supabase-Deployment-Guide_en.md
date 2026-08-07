# Deploy Supabase — Open-Source Firebase Alternative Deployment Guide

> **Document Type:** Huawei Cloud Solution Practice Deployment Guide
> **Document Version:** 02 (candidate)
> **Updated:** 2026-07-14

> **Validation status:** This guide is aligned with the `deploying-supabase_v6.tf` candidate. Its revision number is synchronized with the CN candidate, while the international template continues to use official upstream networking. Real Huawei Cloud deployment, cloud-init, and application verification are still pending; do not treat this candidate as production-validated.

---

## 1. Solution Overview

### 1.1 Use Cases

This solution deploys Supabase `v1.26.07` — the open-source Firebase alternative — on a Huawei Cloud ECS instance. The candidate checks out the complete official `docker/` directory at commit `949a57d2854b7fcadc0d621cb7fffa167506d581`, then uses the official `docker-compose.yml` and `run.sh`. It provides PostgreSQL, authentication, REST/GraphQL APIs, real-time subscriptions, file storage, Edge Functions, and a web Dashboard.

Typical use cases:

- **Rapid backend setup** — Provide database + API + auth as a complete backend infrastructure for mobile/web apps
- **AI application development** — Leverage pgvector vector search extension for RAG and semantic search
- **Real-time data applications** — Subscribe to database changes via WebSocket in real time
- **Enterprise internal BaaS platform** — Self-hosted backend-as-a-service with full data sovereignty

### 1.2 Solution Architecture

#### Single-Instance Deployment

Figure 1-1 Single-instance deployment architecture

This solution deploys the following resources:

- 1 x Huawei Cloud ECS instance (recommended 8vCPUs 16GiB), running the 11 official default services
- 1 x Elastic Public IP (EIP) associated to ECS, providing public Dashboard and API access
- 1 x VPC and subnet for network isolation

#### Component Architecture

```
Kong (API Gateway) ← Unified entry point :8000
├── Studio (Web management Dashboard, protected by HTTP Basic Auth)
├── GoTrue / auth (Authentication)
├── PostgREST / rest (REST API)
├── Realtime (WebSocket real-time subscriptions)
├── Storage (File storage)
├── imgproxy (Image processing)
├── postgres-meta / meta (Database management API)
├── Edge Runtime / functions (Edge Functions)
├── PostgreSQL / db
└── Supavisor (Connection pooler)
```

The candidate uses the fixed image tags from the pinned official Compose file:

| Service | Fixed image |
|---------|-------------|
| Studio | `supabase/studio:2026.07.07-sha-a6a04f2` |
| Kong | `kong/kong:3.9.1` |
| Auth | `supabase/gotrue:v2.189.0` |
| REST | `postgrest/postgrest:v14.12` |
| Realtime | `supabase/realtime:v2.102.3` |
| Storage | `supabase/storage-api:v1.60.4` |
| imgproxy | `darthsim/imgproxy:v3.30.1` |
| Meta | `supabase/postgres-meta:v0.96.6` |
| Functions | `supabase/edge-runtime:v1.74.0` |
| Database | `supabase/postgres:17.6.1.136` |
| Supavisor | `supabase/supavisor:2.9.5` |

Optional Analytics and Vector logging services are not enabled by default. The PostgreSQL `pgvector` extension is separate from the optional Vector logging service.

#### Data Flow

1. Developers/apps access Supabase services through Kong API gateway (port 8000)
2. Auth requests are handled by GoTrue, generating JWT tokens
3. Data requests are automatically converted to PostgreSQL queries via PostgREST
4. Real-time subscriptions push database changes via WebSocket
5. File storage is persisted to local volumes via the Storage service
6. Edge Functions execute through the official Edge Runtime service

### 1.3 Key Benefits

- **Upstream-aligned deployment** — Uses the complete official Docker directory at an immutable commit
- **Official lifecycle commands** — Image pull, startup, shutdown, status, logs, and secret display are handled by the bundled `run.sh`
- **Fixed images and service set** — Runs 11 default services with explicit image tags; optional Analytics/Vector services remain disabled
- **Built-in PostgreSQL extensions** — pgvector vector search, pgjwt auth, PostGIS geospatial, etc.
- **Complete backend capability** — Database + REST API + GraphQL + Auth + Real-time + Storage + Edge Functions + Dashboard
- **Protected Dashboard and persistent snippets** — Kong enforces HTTP Basic Auth, while Studio SQL snippets persist in a host-mounted directory

### 1.4 Constraints and Limitations

- A Huawei Cloud account with real-name authentication and sufficient balance is required before deployment.
- For subscription billing, ensure sufficient balance for auto-deduction, or manually pay at "Billing Center > Unpaid Orders".
- Wait approximately 10-20 minutes for cloud-init, Docker image pulls, and service health checks to complete.
- Recommended ECS flavor is c7n.2xlarge.2 (8vCPUs 16GiB) or above to support all 11 services.
- System disk should be at least 100GB for Docker images and database data.
- The candidate exposes port 8000 over plain HTTP. HTTP Basic Auth protects the Dashboard from unauthenticated access, but it does not encrypt credentials or traffic. Restrict source IPs during evaluation; for production, place the service behind HTTPS/TLS and apply appropriate network access controls before use.
- This is a single-ECS deployment. Database, Storage, and SQL snippets are stored on the ECS system disk and are not highly available.
- Optional Analytics and Vector logging services are not part of the default deployment.

---

## 2. Resource and Cost Planning

> This solution deploys the following resources. Costs are estimates only; actual costs may vary.

### 2.1 Single-Instance Deployment

#### Table 2-1 Cost Estimate (Pay-per-use)

| Huawei Cloud Service | Configuration | Quantity | Estimated Cost (1 hour) |
|---------------------|---------------|----------|------------------------|
| ECS Instance | Billing: Pay-per-use<br>Region: China-Hong Kong (ap-southeast-1)<br>Flavor: c7n.2xlarge.2<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | ~$0.20 |
| Elastic Public IP EIP | Billing: Pay-per-use<br>Line: Dynamic BGP<br>Bandwidth: Traffic billing<br>Size: 300Mbit/s | 1 | $0.00 |
| **Total** | — | — | **~$0.20** |

> Estimated costs are for reference only. Actual costs depend on usage. See Huawei Cloud pricing for details.

#### Table 2-2 Cost Estimate (Subscription)

| Huawei Cloud Service | Configuration | Quantity | Estimated Cost (1 month) |
|---------------------|---------------|----------|-------------------------|
| ECS Instance | Billing: Subscription<br>Region: China-Hong Kong (ap-southeast-1)<br>Flavor: c7n.2xlarge.2<br>Image: Ubuntu 24.04 server 64bit<br>System Disk: High-IO \| 100GB | 1 | ~$146.00 |
| Elastic Public IP EIP | Billing: Traffic<br>Line: Dynamic BGP<br>Bandwidth: 300Mbit/s | 1 | Billed by actual traffic |
| **Total** | — | — | **~$146.00/month + EIP traffic** |

---

## 3. Implementation Steps

### 3.1 Prerequisites

#### 3.1.1 Create rf_admin_trust Delegation (Optional)

Step 1 Open the Huawei Cloud console, hover over the username in the upper right, and open "Unified Identity Authentication".

Step 2 Navigate to the "Agencies" page and search for `rf_admin_trust`.

If the delegation already exists, skip the following creation steps. If not, proceed as follows.

Step 3 Click "Create Agency", enter `rf_admin_trust` as the name, select "Cloud Service" as the type, select `RFS` as the cloud service, and click "OK".

Step 4 Click "Authorize Now".

Step 5 Search for and select `Tenant Administrator`, then click "Next".

Step 6 Select "All Resources" for the authorization scope, and click "OK".

Step 7 Confirm that `rf_admin_trust` appears in the agency list.

----End

### 3.2 Quick Deployment

> This section helps you efficiently deploy the Supabase solution. Follow these steps for one-click deployment.

Step 1 Click "Start Deployment" to navigate to the RFS console.

Step 2 Click "Next", confirm the basic configuration, and set the ECS password and database password.

**Table 3-1 Configuration Parameters**

| Parameter | Description | Default |
|-----------|-------------|---------|
| solution_name | Solution name, 4-24 chars, lowercase letters/digits/hyphens, must start with a lowercase letter | supabase |
| ecs_flavor | ECS flavor, c7n.2xlarge.2 (8vCPUs 16GiB) or above recommended. Change to match available flavors in target region | c7n.2xlarge.2 |
| ecs_password | ECS root password, 8-26 chars, at least 3 of: uppercase, lowercase, digits, special characters | / |
| db_password | PostgreSQL password, 8-24 characters, using letters, digits, and `~!^*-=_+,`; `@` is not supported | / |
| system_disk_size | General Purpose SSD system disk size (GB), range: 40-1024, 100GB recommended for Supabase | 100 |
| bandwidth_size | EIP bandwidth (Mbit/s), traffic billing, range: 1-300 | 300 |
| charging_mode | Billing mode: postPaid (pay-per-use) or prePaid (subscription) | postPaid |
| charging_unit | Subscription unit: month or year, only effective for prePaid | month |
| charging_period | Subscription period, 1-9 (month) or 1-3 (year), only effective for prePaid | 1 |

Step 3 Configure encryption and permissions as needed, then click "Next".

Step 4 Review the stack content. Optionally click "Create Execution Plan" to preview estimated costs, then click "Deploy Stack Directly".

Step 5 Wait for `Apply required resource success`, then check the "Outputs" tab for the Dashboard URL and deployment log path. Allow approximately 10-20 minutes for cloud-init, image pulls, and health checks. RFS resource creation success does not by itself prove that application initialization has completed.

> **Note:**
> - If account balance is insufficient, go to "Billing Center > Top Up" to recharge.
> - If subscription auto-deduction fails, go to "Billing Center > Unpaid Orders" to pay manually.

----End

### 3.3 Getting Started

#### 3.3.1 Access the Supabase Dashboard

Step 1 Open the Dashboard URL from the deployment output in your browser:

```
http://<EIP>:8000/
```

> **Note:** Replace `<EIP>` with the elastic public IP address from the RFS output. This URL uses unencrypted HTTP; use it only in a controlled evaluation environment. Configure HTTPS before production use.

Step 2 The browser must show an HTTP Basic Auth login dialog before Studio loads. The Dashboard username remains the upstream default `supabase`; the password is randomly generated during bootstrap and is intentionally not included in the RFS output. Retrieve it only after connecting over SSH:

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

Use the displayed `DASHBOARD_PASSWORD` with username `supabase`. Do not send the command output to logs, tickets, or chat messages.

Step 3 After authentication, you can:

- View and manage database tables
- Configure user authentication (email, OAuth, phone, etc.)
- Manage file storage buckets
- View real-time subscription status
- Execute SQL queries
- Create and manage Edge Functions

Step 4 Verify Supabase running status with the official lifecycle helper:

```bash
# SSH into ECS
ssh root@<EIP>

# Enter the official Docker deployment directory
cd /opt/supabase

# Check service status or follow logs
sh run.sh status
sh run.sh logs

# Check cloud-init/bootstrap progress if services are not ready
tail -n 200 /var/log/supabase-bootstrap.log
```

----End

#### 3.3.2 Get API Keys

Use the official helper to display generated passwords and API keys. Do not print the complete `.env` file:

```bash
ssh root@<EIP>
cd /opt/supabase
sh run.sh secrets
```

**Table 3-2 API Keys**

| Key | Description | Usage |
|-----|-------------|-------|
| `SUPABASE_PUBLISHABLE_KEY` | Publishable client key | Client-side apps, subject to database authorization policies |
| `SUPABASE_SECRET_KEY` | Secret server key | Trusted server-side components only, **never expose to clients** |
| `POSTGRES_PASSWORD` | PostgreSQL database password | Database connections |
| `DASHBOARD_PASSWORD` | Random Dashboard Basic Auth password | Browser login with username `supabase` |
| `S3_PROTOCOL_ACCESS_KEY_ID` / `S3_PROTOCOL_ACCESS_KEY_SECRET` | S3-compatible Storage credentials | Trusted server-side S3 clients only |

> **Security Note:** Bootstrap uses the official `utils/generate-keys.sh --update-env` and `utils/add-new-auth-keys.sh --update-env` tools with output suppressed, then stores `.env` with mode `0600` under `/opt/supabase` (mode `0700`). `run.sh secrets` is the supported retrieval path in this solution. Never expose secret keys or database/S3 passwords to clients.

----End

#### 3.3.3 Official Operations and Credential Changes

Run lifecycle operations from `/opt/supabase` through the pinned official `run.sh`:

```bash
cd /opt/supabase
sh run.sh status
sh run.sh restart
sh run.sh stop
sh run.sh start
```

Do not hand-build JWTs or directly edit individual values in `.env`. JWT/API-key and PostgreSQL password changes affect multiple services and database roles. Back up data first, then rebuild the stack or follow the coordinated credential-rotation procedure for the exact pinned upstream release. The official key-generation scripts in this candidate are intended for initial bootstrap and are not a standalone post-deployment database-password rotation procedure.

----End

#### 3.3.4 SQL Snippets Persistence

The pinned official Compose file sets `SNIPPETS_MANAGEMENT_FOLDER=/app/snippets` for Studio and mounts `./volumes/snippets:/app/snippets:z`. SQL snippets saved in Studio therefore persist across container restarts in `/opt/supabase/volumes/snippets`. They remain on the single ECS system disk and must be backed up before deleting or rebuilding the ECS.

#### 3.3.5 Common Service Endpoints

**Table 3-3 Supabase Service Endpoints**

| Endpoint | Description | Example |
|----------|-------------|---------|
| Dashboard | Web management dashboard | `http://<EIP>:8000/` |
| REST API | Auto-generated RESTful API | `http://<EIP>:8000/rest/v1/` |
| Auth API | User authentication API | `http://<EIP>:8000/auth/v1/` |
| Storage | File storage API | `http://<EIP>:8000/storage/v1/` |
| Realtime | WebSocket real-time subscriptions | `http://<EIP>:8000/realtime/v1/` |
| Edge Functions | Edge Functions endpoint | `http://<EIP>:8000/functions/v1/` |

----End

> **Security Note:** All examples above use the candidate's current plain-HTTP endpoint. API keys and payloads are not protected by transport encryption. Configure HTTPS/TLS before production use. The optional Analytics endpoint is unavailable because Analytics/Vector services are disabled by default.

### 3.4 Uninstall

Step 1 In the RFS console, find the stack created by this solution, and click "Delete" next to the stack name.

Step 2 In the confirmation dialog, select "Delete Resources", enter `Delete`, and click "OK".

> **Note:**
> - Uninstalling releases all resources (ECS, EIP, VPC, security group).
> - **Back up `/opt/supabase/volumes/db/data`, Storage data, and `/opt/supabase/volumes/snippets` before deletion** — local data is unrecoverable after uninstall.

----End

---

## 4. Appendix

### 4.1 Glossary

| Term | Description |
|------|-------------|
| Supabase | Open-source Firebase alternative providing PostgreSQL, auth, REST API, real-time subscriptions, file storage, etc. |
| PostgreSQL | Open-source relational database, Supabase's core data storage engine |
| Kong | Open-source API gateway, serves as Supabase's unified entry point |
| GoTrue | Open-source user authentication service supporting email, OAuth, phone, etc. |
| PostgREST | Auto-generates RESTful API from PostgreSQL database schema |
| pgvector | PostgreSQL vector search extension for AI and semantic search |
| RFS | Resource Formation Service, Huawei Cloud's infrastructure-as-code service |
| JWT | JSON Web Token, stateless token for API authentication |

### 4.2 Reference Links

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [Pinned official Docker deployment directory for v1.26.07](https://github.com/supabase/supabase/tree/949a57d2854b7fcadc0d621cb7fffa167506d581/docker)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting/docker)
- [Huawei Cloud RFS](https://support.huaweicloud.com/intl/en-us/rfs/)

---

## 5. Revision History

| Date | Revision |
|------|----------|
| 2026-07-14 | Added `_v6` to synchronize the candidate revision with the CN template; removed the `_v5` candidate. |
| 2026-07-14 | Added `_v5` to synchronize the candidate revision with the CN template; removed the `_v4` candidate. |
| 2026-07-07 | Initial release for intl ap-southeast-1 (Hong Kong). |
| 2026-07-14 | Candidate guide aligned to the pinned official Docker Compose deployment: 11 fixed-image services, Basic Auth, official `run.sh`, persistent snippets, and pending cloud validation. |
| 2026-07-14 | Added the `_v2` candidate with a self-only `charging_period` validation for RFS compatibility; deleted the failed `_v1` candidate files. |
| 2026-07-14 | Added `_v3`: removed the database-password and CN flavor format regexes, added Base64 and dotenv literal-safe password handling, and deleted the failed `_v2` candidates. |
| 2026-07-14 | Added `_v4`: set Docker APT key/source files to mode `0644` to fix `_apt` `NO_PUBKEY` failures caused by restrictive umask; deleted the failed `_v3` candidates. |
