# NewAPI Solution Details

> Status: verified local-release candidate. The user has confirmed that the retained Standard and HA templates were live-cloud validated. The external OBS bootstrap script referenced by Standard is neither packaged nor audited in this repository.

## Overview

This practice deploys NewAPI through RFS in Huawei Cloud International `ap-southeast-1` (Hong Kong, China), with Standard and HA variants. NewAPI manages upstream model channels, access tokens, user permissions, and usage data. The templates retain their existing resources, runtime behavior, and public endpoints.

| Variant | Application topology | Public endpoint |
|---|---|---|
| Standard | One ECS and EIP; first boot downloads and runs an external OBS bootstrap script | ECS EIP, TCP `3000` |
| HA | ELB, CCE, RDS for MySQL, DCS Redis, and NAT | ELB EIP, HTTP `80` |

## Implementation Facts

### Standard

- VPC `172.16.0.0/16`; subnet `172.16.1.0/24`.
- One Ubuntu 22.04 ECS, default flavor `x1.8u.16g`, and a `100` GB SAS system disk.
- One traffic-billed `300` Mbit/s EIP.
- The security group opens TCP `3000` publicly; SSH is restricted to `119.8.185.245/32`.
- `user_data` downloads, executes, and deletes `newapi_deploy.sh`. The script body, checksum, and supply-chain audit are outside this delivery.

### HA

- VPC `192.168.0.0/16`; subnets `192.168.200.0/24`, `192.168.201.0/24`, and `192.168.202.0/24`.
- Three EIPs serve ELB, the CCE API server, and NAT. ELB listens on HTTP `80`; NAT provides SNAT egress for private networks.
- A CCE Turbo `v1.34` cluster has three Ubuntu 24.04 nodes and an API-server EIP.
- RDS for MySQL 8.0 is HA with `100` GB CLOUDSSD. DCS Redis 6.0 is HA, defaults to `1` GB, and retains automatic backups for three days.
- Kubernetes creates the `new-api` namespace, one Master Pod, three Slave Pods, a ClusterIP Service, and CCE Ingress to ELB.
- The application image resolves to `swr.cn-east-3.myhuaweicloud.com/sac/new-api:v1.0.0-rc.8`. This is the template's fixed source, not a claim that it is in the target Region or the latest upstream version.

## Operational and Security Boundaries

- Standard TCP `3000` and HA HTTP `80` are public application endpoints. The templates do not configure TLS termination or certificates; operators must add TLS and access control before carrying sessions, keys, or production traffic.
- HA gives the CCE API server an EIP. The template notes that the EIP can be released after creation when public API access is not required; operators should restrict or remove this exposure as appropriate.
- Standard depends on the external OBS bootstrap. Deployment, change, incident response, and supply-chain responsibility depend on the actual object and its availability. This delivery cannot reproduce or audit its installation procedure.
- Flavor availability, quotas, availability zones, pricing, and reachability of the cross-Region image source are account- and Region-specific at stack creation.

## Billing and Use Cases

Standard uses ECS, EIP, and traffic billing. HA also uses CCE nodes, ELB, NAT, RDS, DCS, and three EIPs. Templates default to `postPaid` and expose `prePaid`, `month|year`, and period parameters; actual prices are determined in the Huawei Cloud International console.

The practice is intended for organizations authorized to use their upstream model services and needing centralized API, token, quota, and usage administration. Operators remain responsible for applicable law, provider terms, and data-handling requirements.

## Delivery Scope

- Terraform: `standard/terraform/deploying-newapi.tf.json` and `ha/terraform/deploying-newapi.tf`.
- Documentation: International Chinese and English solution details and deployment guides.
- Excluded: the external OBS script body, its checksum, an offline image copy, and credentials.

## References

- [NewAPI official repository](https://github.com/QuantumNous/new-api)
- [NewAPI official documentation](https://docs.newapi.pro/en/docs)
- [Huawei Cloud Application Orchestration Service](https://www.huaweicloud.com/intl/en-us/product/aos.html)
