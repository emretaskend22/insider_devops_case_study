# ADR-0001: Use Helm Charts for Kubernetes Deployment and Configuration Management

## Status
Accepted

## Context
Managing raw Kubernetes manifests (`deployment.yaml`, `service.yaml`, `ingress.yaml`) for multiple application environments introduces significant maintenance overhead, duplication of configuration code, and a high risk of configuration drift. For this case study, the stateless Python FastAPI application must be deployed across two distinct environments: a lightweight, cost-aware Development environment and a high-availability, heavily monitored Production environment running on an AWS `t3.small` instance. Using raw static manifests would make managing environment-specific configurations (such as replica counts, horizontal pod autoscaling rules, resource limits, and monitoring parameters) highly error-prone.

## Decision
We decided to adopt Helm as the primary package manager and template engine for managing all Kubernetes infrastructure and application deployments. 

Instead of writing static YAML manifests, we created a unified, parameterized Helm chart called `insider-app`. Environment separation is strictly enforced at the configuration level using dedicated values files:
* `values-dev.yaml`: Configured for a single pod replica, strict localized image pulling (`pullPolicy: Never`), and tight resource allocations to optimize costs in the test environment.
* `values-prod.yaml`: Configured for high availability (minimum 3 replicas), robust horizontal scaling (HPA up to 5 replicas aligned with `t3.small` constraints), higher vertical resource boundaries, and an active Prometheus `ServiceMonitor` for cluster metrics collection.

## Consequences
* **(+) DRY Compliance (Don't Repeat Yourself):** A single Helm chart defines the underlying architectural template, completely eliminating duplicated Kubernetes resource declarations.
* **(+) Atomic Upgrades and Rollbacks:** Deployments are executed via atomic operations (`helm upgrade --install`). If a failure occurs during a production rollout, the cluster state can be safely reverted instantly using `helm rollback`.
* **(+) Configuration Flexibility:** Environment-specific settings are completely decoupled from core infrastructure code, enabling rapid, risk-free configuration modifications.
* **(-) Added Complexity:** Introduces Helm syntax abstraction and template nesting dependencies, requiring developers to understand Helm chart structures rather than pure Kubernetes manifests.