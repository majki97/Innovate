# Innovate Inc.

## Description

1. Overview
This document describes the cloud architecture for Innovate Inc.’s web application running on Amazon Web Services (AWS).​
The application consists of a React single‑page application (SPA) frontend, a Python/Flask REST API backend, and a PostgreSQL database.​
The solution uses Amazon EKS for container orchestration, Amazon RDS for PostgreSQL, and a simple multi‑account structure suitable for a small startup expecting future growth.​

2. High‑Level Goals
Provide a simple, secure, and maintainable AWS setup that a small team with limited cloud experience can operate.​

Support low initial traffic while being able to scale to significantly higher load without major redesign.​

Use managed services (EKS, RDS, ALB, Route 53) to reduce undifferentiated heavy lifting and operational overhead.​

Implement a basic CI/CD pipeline for frequent, safe deployments to non‑production and production environments.​

3. Cloud Environment Structure
Innovate Inc. uses three AWS accounts under a single AWS Organization: Management, Non‑Production, and Production.​

3.1 Management account
Hosts AWS Organizations, consolidated billing, and global guardrails such as service control policies (SCPs) as the company grows.​

Stores centralized audit logs: an organization‑wide CloudTrail trail and S3 buckets for log archiving.​

Does not run application workloads to keep the blast radius small and operational scope clear.​

3.2 Non‑Production account
Contains a single non‑prod environment (development + staging) that mirrors the production architecture at smaller scale.​

Runs an EKS cluster, a smaller RDS PostgreSQL instance, and the same networking pattern as production for realistic testing.​

Isolates experimentation and testing from production while keeping operations simple for a small team.​

3.3 Production account
Hosts the production EKS cluster, production RDS PostgreSQL, and internet‑facing Application Load Balancer.​

Uses stricter IAM policies, network controls, and monitoring than non‑prod to protect sensitive user data.​

Enables clear cost tracking and access control boundaries for business‑critical workloads.​

4. Network Design
Each workload account (Non‑Production and Production) contains one VPC in a chosen region (for example, eu-west-1), designed as a standard three‑tier web architecture.​

4.1 VPC and subnets
One VPC per account with a /16 CIDR range, split across three Availability Zones for high availability.​

In each AZ, three subnet types are used:

Public subnets for the Application Load Balancer (ALB) and NAT Gateway.​

Private application subnets for EKS worker nodes.​

Private database subnets for RDS PostgreSQL, with no direct internet access.​

4.2 Traffic flow
Internet users resolve the application domain via Amazon Route 53 and connect over HTTPS to the public ALB.​

The ALB forwards incoming requests to the EKS cluster via the AWS Load Balancer Controller and Kubernetes Ingress resources.​

Flask API pods in EKS connect to the PostgreSQL database over a private subnet using the RDS endpoint.​

4.3 Network security
Security groups restrict:

ALB to accept HTTPS traffic only from the internet on port 443.​

EKS nodes to accept traffic from the ALB security group and internal cluster components.​

RDS PostgreSQL to accept traffic only from the EKS node group or RDS Proxy security group.​

Network ACLs remain close to default and stateless, with security groups providing the main layer of network enforcement to keep operations simpler.​

VPC Flow Logs are enabled and delivered to CloudWatch Logs or S3 for troubleshooting and security investigations.​

4.4 DNS and TLS
Amazon Route 53 hosts public DNS zones (for example, innovate.example.com) and maps application subdomains (such as app.innovate.example.com and api.innovate.example.com) to the ALB.​

AWS Certificate Manager issues and manages TLS certificates, and HTTPS is terminated at the ALB to ensure encryption in transit from clients.​

5. Compute Platform – Amazon EKS
Amazon EKS is used as the managed Kubernetes control plane for running the Flask API and React SPA as containerized workloads.​

5.1 Cluster layout
One EKS cluster is deployed per account: one in Non‑Production and one in Production.​

Each cluster runs in three Availability Zones and uses the EKS managed control plane, which AWS patches and operates.​

The Kubernetes API endpoint is configured as private, accessible from inside the VPC (and optionally via a VPN or bastion host for administrators).​

5.2 Node groups and scaling
Each cluster has two managed node groups:

A “system” node group (on‑demand instances) for core services such as the AWS Load Balancer Controller, logging, and monitoring agents.​

An “application” node group (mix of on‑demand and Spot instances) for the Flask API and React SPA pods.​

Karpenter adjusts node counts based on pending pods, allowing the cluster to scale up under load and scale down when idle.​

Horizontal Pod Autoscalers (HPA) scale the Flask API and frontend Deployments based on CPU utilization or request metrics.​

5.3 Workloads
The Flask REST API is deployed as a Kubernetes Deployment with a corresponding Service and Ingress rule.​

The React SPA can either be served from the same EKS cluster (for example, via Nginx) or from an S3/CloudFront static site, but for simplicity here it runs as a Deployment and Service behind the same ALB.​

Liveness and readiness probes ensure that rolling updates do not degrade availability and that only healthy pods receive traffic.​

5.4 Security and access control
IAM Roles for Service Accounts (IRSA) are used so pods can securely access AWS services (for example, Secrets Manager, S3) without storing long‑lived credentials.​

Kubernetes RBAC and namespaces are used to separate system components (for example, kube-system, platform) from application namespaces (for example, innovate-api, innovate-frontend).​

6. Containerization and CI/CD
The backend and frontend are packaged as Docker images, stored in Amazon ECR, and deployed to EKS using Helm charts and a simple CI/CD pipeline.​

6.1 Container images
Each service (Flask API, React SPA) has its own Dockerfile using multi‑stage builds to keep the runtime image minimal.​

Images are pushed to private ECR repositories with semantic version tags (for example, innovate-api:1.2.0) and latest for convenience.​

The build pipeline runs vulnerability scans (for example, AWS Inspector) on the images before deployment to catch common security issues early.​

6.2 CI pipeline (build and test)
On every push or pull request to the main branch, the CI pipeline is triggered in GitHub Actions or GitLab CI.​

Stages typically include: dependency installation, unit tests, optional integration tests, Docker build, image scan, and push to ECR.​

6.3 CD pipeline (deploy)
For Non‑Production, successful CI builds automatically update Helm values and run helm upgrade against the non‑prod EKS cluster.​

For Production, a manual approval gate is required; once approved, the same image tag is deployed to the production EKS cluster, ensuring consistency between environments.​

Deployments use rolling updates with a small surge and PodDisruptionBudgets so that the service remains available during releases.​

7. Database – Amazon RDS for PostgreSQL
Amazon RDS for PostgreSQL is used as the managed relational database for both Non‑Production and Production environments.​

7.1 Service configuration
Each account has its own RDS PostgreSQL instance deployed in private database subnets with no public IP.​

Production uses a Multi‑AZ deployment to provide automatic failover in case the primary AZ becomes unavailable.​

Instance sizes are chosen to match expected load, with the option to scale up vertically as the user base grows.​

7.2 Backups and disaster recovery
Automated backups are enabled with a retention period (for example, 30 days in production) and point‑in‑time recovery.​

Regular manual snapshots are created and optionally copied to a secondary region for regional disaster recovery.​

7.3 Security
RDS storage is encrypted at rest using AWS KMS keys, and all connections to the database require TLS.​

Database credentials are stored in AWS Secrets Manager and retrieved by the application using IAM rather than hard‑coded values.​

8. Security and Observability
Security and observability controls are intentionally kept straightforward while still following AWS best practices.​

8.1 Identity and access
IAM roles and policies follow the principle of least privilege for both human and machine identities.​

MFA is enforced for console access, especially in the Production account, via AWS IAM Identity Center or standard IAM.​

8.2 Logging and monitoring
CloudWatch collects application logs from EKS via a log forwarder such as Fluent Bit or CloudWatch Agent.​

CloudWatch metrics and alarms monitor key signals such as API error rates, pod CPU/memory usage, node health, and RDS performance.​

Optionally, Prometheus and Grafana can be deployed in EKS for richer Kubernetes‑native observability.


