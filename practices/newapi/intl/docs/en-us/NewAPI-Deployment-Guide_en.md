# NewAPI Deployment Guide

> Status: verified local-release candidate. The user confirms the existing templates have passed live-cloud validation; preserve their behavior. Standard installation depends on an external OBS script whose body is not packaged or audited here.

## 1. Select a Template

Create an RFS stack in Huawei Cloud International `ap-southeast-1` with one of these templates:

| Variant | Template | Use when |
|---|---|---|
| Standard | `standard/terraform/deploying-newapi.tf.json` | One ECS is sufficient and an external OBS bootstrap plus public TCP `3000` are acceptable. |
| HA | `ha/terraform/deploying-newapi.tf` | CCE, RDS, Redis, ELB, NAT, and three EIPs are required, and public HTTP `80` plus a CCE API EIP are acceptable. |

Do not load both templates in the same Terraform directory.

## 2. Pre-deployment Checks

1. Confirm account quota and billing authorization in `ap-southeast-1`.
2. Supply independent, strong values for ECS/CCE, MySQL, Redis, `session_secret`, and `crypto_secret`. Do not put sensitive values in documentation, logs, or source control.
3. Confirm acceptance of the public endpoints: Standard TCP `3000` and HA HTTP `80`. Neither template configures HTTPS termination.
4. For Standard, confirm the ECS can retrieve the external OBS object at the template URL. Its script body and hash are not included in this delivery, so this guide cannot provide installation steps or an integrity conclusion for it.
5. For HA, confirm availability of CCE `v1.34`, three Ubuntu 24.04 nodes, MySQL 8.0 HA, Redis 6.0 HA, ELB, NAT, and three EIPs, and that the environment can pull `swr.cn-east-3.myhuaweicloud.com/sac/new-api:v1.0.0-rc.8`.

## 3. Template Parameters

### Standard

| Parameter | Default | Description |
|---|---|---|
| `vpc_name` / `security_group_name` / `ecs_name` | `building-a-newapi-llm-gateway-demo` | New resource names |
| `ecs_flavor` | `x1.8u.16g` | Ubuntu 22.04 ECS flavor |
| `ecs_password` | empty | Sensitive ECS root password |
| `system_disk_size` | `100` | SAS system disk in GB |
| `bandwidth_size` | `300` | Traffic-billed EIP bandwidth in Mbit/s |
| `charging_mode` | `postPaid` | `postPaid` or `prePaid` |
| `charging_unit` / `charging_period` | `month` / `1` | Subscription period |

Standard fixes the VPC at `172.16.0.0/16` and subnet at `172.16.1.0/24`, restricts SSH to `119.8.185.245/32`, and opens TCP `3000` to all IPv4 addresses.

### HA

| Parameter | Default | Description |
|---|---|---|
| `resource_name_prefix` | `ha-new-api` | Resource-name prefix |
| `cce_cluster_flavor` | `cce.s2.small` | CCE Turbo cluster flavor |
| `cce_node_pool_flavor` / `cce_node_pool_count` | `x1.8u.16g` / `3` | Ubuntu 24.04 node flavor and count |
| `cce_node_pool_password` | empty | Sensitive CCE node password |
| `rds_flavor` | `rds.mysql.n1.xlarge.2.ha` | MySQL 8.0 HA flavor |
| `mysql_password` / `mysql_user_password` | empty | Sensitive database passwords |
| `redis_capacity` / `redis_password` | `1` / empty | Redis 6.0 HA capacity in GB and password |
| `session_secret` / `crypto_secret` | empty | Sensitive NewAPI session and channel-encryption secrets |
| `charging_mode` / `charging_unit` / `charging_period` | `postPaid` / `month` / `1` | Billing parameters |

HA fixes the VPC at `192.168.0.0/16` and uses subnets `192.168.200.0/24`, `192.168.201.0/24`, and `192.168.202.0/24`. RDS uses `100` GB CLOUDSSD; Redis automatic backups retain three days. The application runs one Master and three Slave Pods, with ELB HTTP `80` forwarding to service port `3000`.

## 4. Create and Verify

1. In the RFS console, select `ap-southeast-1`, create a stack, and upload the selected template.
2. Enter parameters, review the resource list and charges, and create the stack.
3. Wait for stack creation to complete. Access Standard at the output ECS EIP on `:3000`; access HA at the output ELB EIP on HTTP `80`.
4. For HA, also check CCE nodes, RDS, DCS, ELB, Master/Slave Pods, and the `/api/status` probes.

## 5. Operate and Uninstall

- For Standard incidents, use ECS cloud-init logs and the availability of the external OBS object; no local script exists in this delivery for comparison.
- If HA image pulls fail, verify connectivity and authorization to the fixed SWR image address.
- Add TLS and access control before transmitting sessions, upstream API keys, or production traffic through a public endpoint.
- If public CCE API access is no longer needed, release or restrict its EIP as noted by the template.
- Before stack deletion, export required NewAPI configuration and business data. Afterwards, verify the actual retention state of EIPs, NAT, ELB, CCE, RDS, DCS, and disks.

## 6. Revision History

| Date | Status | Description |
|---|---|---|
| 2026-07-21 | verified local-release candidate | Delivery documentation updated from the retained live-cloud-validated templates; external OBS script explicitly excluded from packaging and audit. |
