# ⚡ DevOps Name Generator

![Status](https://img.shields.io/badge/status-complete-success)
![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC)
![Kubernetes](https://img.shields.io/badge/orchestration-Kubernetes-326CE5)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF)
![Monitoring](https://img.shields.io/badge/monitoring-Prometheus%20%2B%20Grafana-F46800)
![MongoDB](https://img.shields.io/badge/database-MongoDB-47A248)

A production-style DevOps project demonstrating: automated AWS infrastructure provisioning with **Terraform**, **Dockerized Node.js/Express + MongoDB**, Kubernetes orchestration by **Amazon EKS**, **persistent EBS storage**, CI/CD by **GitHub Actions using OIDC**, and observability with **Prometheus + Grafana**.

![Project overview](docs/visuals/project-overview.png)

The application is a Node.js name generator backed by MongoDB. The primary focus of this project is the infrastructure, deployment automation, resilience, and monitoring surrounding the application.

---

## Architecture

```text
Developer
    │
    │ git push
    ▼
GitHub Repository
    │
    ▼
GitHub Actions
    │
    │ OIDC authentication
    ▼
AWS IAM
    │
    ├──────────────► Amazon ECR
    │                    │
    │                    │ Docker image
    │                    ▼
    └──────────────► Amazon EKS
                         │
                 ┌───────┴────────┐
                 │                │
                 ▼                ▼
            NameGen App        MongoDB
             Deployment       StatefulSet
             2 replicas            │
                 │                 ▼
                 │             EBS / PVC
                 ▼
          AWS Network
          Load Balancer

          Prometheus ─────► Grafana
```

![AWS / EKS Architecture](docs/diagrams/architecture.svg)

Editable source: [`architecture.drawio`](docs/diagrams/architecture.drawio)

---

## Technology Stack

| Area                   | Technology                |
| ---------------------- | ------------------------- |
| Application            | Node.js / Express         |
| Database               | MongoDB                   |
| Containerization       | Docker                    |
| Container Registry     | Amazon ECR                |
| Infrastructure as Code | Terraform                 |
| Cloud Platform         | AWS                       |
| Kubernetes             | Amazon EKS                |
| Persistent Storage     | Amazon EBS                |
| Load Balancing         | AWS Network Load Balancer |
| CI/CD                  | GitHub Actions            |
| Authentication         | GitHub OIDC → AWS IAM     |
| Monitoring             | Prometheus                |
| Visualization          | Grafana                   |
| Package Management     | Helm                      |

---

## Project Structure

```text
.
├── .github/
│   └── workflows/
│       └── main.yml
│
├── data/
│   ├── connection.js
│   ├── index.js
│   └── schemas.js
│
├── docs/
│   ├── diagrams/
│   │   ├── architecture.drawio
│   │   └── cicd-pipeline.drawio
│   └── screenshots/
│       ├── application-running-1.png
│       ├── application-save-1.png
│       ├── application-save-2.png
│       ├── grafana-cluster-overview.png
│       ├── grafana-node-cpu-memory.png
│       ├── grafana-node-disk-network.png
│       ├── mongodb-persistence.png
│       └── mongodb-self-healing-api.png
│
├── k8s/
│   ├── monitoring/
│   │   └── values.yaml
│   └── namegen/
│       ├── deployment.yaml
│       └── service.yaml
│
├── public/
│   └── index.html
│
├── terraform/
│   ├── modules/
│   │   ├── cicd/
│   │   ├── ecr/
│   │   ├── eks/
│   │   └── network/
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── variables.tf
│   ├── versions.tf
│   └── workloads.tf
│
├── tests/
│   └── data-tests.js
│
├── .dockerignore
├── .gitignore
├── Dockerfile
├── package.json
├── package-lock.json
├── server.js
└── README.md
```

---

# Infrastructure

The AWS infrastructure is defined with Terraform and separated into reusable modules for networking, EKS, ECR, and CI/CD integration.

## Network

Terraform provisions the networking required by the EKS environment, including:

- VPC
- public subnets across multiple Availability Zones
- Internet Gateway
- route tables
- subnet associations

## Amazon EKS

The application runs on Amazon EKS using EKS Auto Mode for managed compute and AWS integration.

The Kubernetes environment runs:

- two NameGen application replicas
- MongoDB as a StatefulSet
- persistent MongoDB storage
- an internet-facing LoadBalancer service
- Prometheus and Grafana monitoring

## Amazon ECR

Application container images are stored in a private Amazon Elastic Container Registry repository.

The repository is configured through Terraform with:

- immutable image tags
- image scanning on push

GitHub Actions builds and pushes a new image during deployment.

CI/CD images use the Git commit SHA as the image tag, providing direct traceability between source code and the deployed container.

---

# Application Deployment

The NameGen application runs as a Kubernetes Deployment with two replicas.

```text
Internet
   │
   ▼
AWS Network Load Balancer
   │
   ▼
Kubernetes Service
   │
   ├────────► NameGen Pod
   │
   └────────► NameGen Pod
                  │
                  ▼
               MongoDB
```

The Kubernetes Service exposes port `80` externally and forwards requests to application port `8080`.

The service is exposed through an internet-facing AWS Network Load Balancer.

## Deployment Evidence

The deployed application was successfully accessed through the AWS load balancer.

![NameGen application running on EKS](docs/screenshots/application-running-1.png)

A random name can be generated directly through the browser interface.
The generated record can then be persisted to MongoDB and retrieved by the application:

![Name successfully saved to MongoDB](docs/screenshots/application-save-2.png)

---

# MongoDB Persistence and Self-Healing

MongoDB runs as a Kubernetes `StatefulSet`.

Unlike application containers, database storage must survive pod replacement. MongoDB therefore uses a PersistentVolumeClaim backed by persistent AWS storage.

```text
MongoDB Pod
    │
    ▼
PersistentVolumeClaim
    │
    ▼
PersistentVolume
    │
    ▼
Amazon EBS
```

This separates the lifecycle of the MongoDB pod from the lifecycle of the stored application data.

## Persistence Verification

Persistence was tested using the running application rather than only inspecting Kubernetes resource definitions.

A generated name was first saved through the public browser interface.

![Name persisted before MongoDB restart](docs/screenshots/application-save-2.png)

The `mongodb-0` pod was then deliberately deleted.

Because MongoDB is managed by a StatefulSet, Kubernetes automatically recreated the missing pod. During recovery, the pod transitioned through termination and creation states until the replacement returned to `Running`.

The same API query subsequently returned the record that existed before the pod was deleted:

![MongoDB self-healing and persisted API record](docs/screenshots/mongodb-self-healing-api.png)

The browser interface also continued displaying the previously stored record after MongoDB recovered:

![Persisted record after MongoDB pod recreation](docs/screenshots/mongodb-persistence.png)

This demonstrates two separate Kubernetes behaviors:

**Self-healing** — Kubernetes automatically recreated the deleted StatefulSet pod.

**Persistent storage** — the database record survived pod destruction because the data was stored outside the ephemeral container filesystem.

The deployed environment was verified with a bound **5 GiB EBS-backed PersistentVolume**.

---

# CI/CD Pipeline

A push to the `main` branch automatically starts the GitHub Actions deployment workflow.

```text
git push
   │
   ▼
GitHub Actions
   │
   ├── Checkout repository
   │
   ├── Authenticate to AWS using OIDC
   │
   ├── Login to Amazon ECR
   │
   ├── Build Docker image
   │
   ├── Tag image with Git SHA
   │
   ├── Push image to ECR
   │
   ├── Configure kubectl for EKS
   │
   ├── Update Kubernetes Deployment
   │
   └── Wait for successful rollout
   │
   ▼
Updated application on EKS
```

## CI/CD Deployment Evidence

A small visual change was used to verify that a push to `main` resulted in a new container image being built and deployed to EKS.

Before the change:

![Application before CI/CD deployment](docs/screenshots/cicd-before.png)

The source change was intentionally minimal so the deployment could be identified visually:

![Source change used to verify CI/CD](docs/screenshots/cicd-change.png)

After GitHub Actions completed the build, ECR push, and Kubernetes rollout, the updated application was visible through the same public load balancer:

![Application after CI/CD deployment](docs/screenshots/cicd-after.png)

The temporary visual change was then reverted, confirming another successful deployment while preserving the original application appearance:

![Application restored after CI/CD verification](docs/screenshots/cicd-restored.png)

![CI/CD Pipeline](docs/diagrams/cicd-pipeline.svg)

Editable source: [`cicd-pipeline.drawio`](docs/diagrams/cicd-pipeline.drawio)

## Passwordless AWS Authentication

The pipeline does not require permanent AWS access keys stored as GitHub secrets.

GitHub Actions authenticates to AWS through OpenID Connect:

```text
GitHub Actions
      │
      │ OIDC token
      ▼
AWS IAM Role
      │
      ▼
Temporary AWS credentials
```

Terraform provisions the IAM integration and grants the CI/CD role the permissions required to push images to ECR and deploy to EKS.

This avoids storing long-lived AWS credentials in the repository or CI/CD configuration.

---

# Monitoring and Observability

The Kubernetes environment includes a monitoring stack based on:

- Prometheus
- Grafana
- kube-state-metrics
- Prometheus Node Exporter
- Alertmanager

The stack is deployed with Helm using `kube-prometheus-stack`.

Prometheus collects Kubernetes and node telemetry while Grafana provides dashboards for visualizing cluster and workload health.

The monitoring components run in the dedicated `monitoring` namespace.

## Kubernetes Cluster Overview

Grafana exposes namespace-level CPU and memory utilization together with workload and resource-request information.

![Grafana Kubernetes cluster overview](docs/screenshots/grafana-cluster-overview.png)

## Node CPU and Memory

Node-level dashboards expose CPU utilization, system load and memory consumption.

![Grafana node CPU and memory metrics](docs/screenshots/grafana-node-cpu-memory.png)

## Disk and Network

Node Exporter metrics provide visibility into disk I/O, filesystem usage and network traffic.

![Grafana node disk and network metrics](docs/screenshots/grafana-node-disk-network.png)

---

# API

The application exposes REST endpoints for generating and retrieving names.

## Generate a Random Name

```http
GET /api/random_name
```

Example:

```json
{
  "firstName": "Jaydon",
  "lastName": "Harris"
}
```

## Get Stored Names

```http
GET /api/names
```

## Get a Name by ID

```http
GET /api/names/:id
```

The browser interface can generate, persist, retrieve, and clear names without requiring direct API calls.

---

# Local Development

## Requirements

Install:

- Node.js
- Docker
- Git

## Start MongoDB

```bash
docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=genuser \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:3.6
```

Configure the database connection:

```bash
export MONGODB_URL="mongodb://genuser:password@localhost:27017/namegen?authSource=admin"
```

Install application dependencies:

```bash
npm ci
```

Start the application:

```bash
npm start
```

The application listens on port `8080`.

---

# Tests

The project includes application/database integration tests.

Configure the MongoDB connection and run:

```bash
export MONGODB_URL="mongodb://genuser:password@localhost:27017/namegen?authSource=admin"

npm test
```

The test suite verifies:

- MongoDB connectivity
- creation of a person
- retrieval of persisted records
- retrieval of a specific record by ID

A successful run should report:

```text
2 passing
```

---

# Docker

Build the application image:

```bash
docker build -t namegen:local .
```

Run the container:

```bash
docker run --rm \
  -p 8080:8080 \
  -e MONGODB_URL="mongodb://genuser:password@host.docker.internal:27017/namegen?authSource=admin" \
  namegen:local
```

---

# Terraform

AWS infrastructure is managed from the `terraform/` directory.

Create a local variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Initialize Terraform:

```bash
terraform init
```

Format and validate:

```bash
terraform fmt -recursive
terraform validate
```

Review infrastructure changes:

```bash
terraform plan
```

Provision the infrastructure:

```bash
terraform apply
```

Local Terraform variable files, state, plans and runtime artifacts are intentionally excluded from Git.

The Terraform dependency lock file is committed to provide reproducible provider selection.

---

# Kubernetes Verification

Configure access to the EKS cluster:

```bash
aws eks update-kubeconfig \
  --region eu-central-1 \
  --name devops-namegen-eks
```

Check cluster nodes:

```bash
kubectl get nodes
```

Check application workloads:

```bash
kubectl get pods
kubectl get deployments
kubectl get svc
```

Check persistent storage:

```bash
kubectl get pvc
kubectl get pv
```

Check monitoring:

```bash
kubectl get pods -n monitoring
helm list -A
```

Verify the application rollout:

```bash
kubectl rollout status deployment/namegen
```

---

# Deployment Verification

The completed AWS deployment demonstrated:

- EKS compute capacity reaching `Ready`
- two running NameGen application replicas
- MongoDB running as a Kubernetes StatefulSet
- MongoDB PVC bound to persistent AWS storage
- successful MongoDB self-healing after pod deletion
- persisted database data surviving pod recreation
- internet-facing AWS load balancing
- successful application access through the load balancer
- successful database reads and writes through the application
- Prometheus and Grafana running inside the cluster
- node, namespace, CPU, memory, disk and network monitoring
- GitHub Actions authentication through AWS OIDC
- automated Docker image build and push to Amazon ECR
- Git-SHA-based container image versioning
- automated deployment from GitHub Actions to EKS
- successful Kubernetes rolling deployment

---

# Security and Repository Hygiene

The repository intentionally excludes:

- `.env` files
- Terraform state
- `terraform.tfvars`
- Terraform plan files
- `node_modules`
- IDE configuration
- operating-system metadata
- temporary files

AWS credentials are not stored in the repository.

CI/CD uses GitHub OIDC and short-lived AWS credentials instead of static access keys.

Application database configuration is supplied through environment-based configuration rather than embedded in application source code.

---

# Key DevOps Concepts Demonstrated

This project demonstrates practical experience with:

- Infrastructure as Code
- modular Terraform
- AWS networking
- Amazon EKS
- Kubernetes Deployments
- Kubernetes StatefulSets
- persistent cloud storage
- Kubernetes self-healing
- Docker containerization
- Amazon ECR
- Network Load Balancing
- GitHub Actions
- OIDC federation
- AWS IAM roles and policies
- immutable Git-SHA container tagging
- automated rolling deployments
- Prometheus monitoring
- Grafana visualization
- Helm
- environment-based configuration
- Git-based infrastructure and application delivery workflows

---

# Future Improvements

Possible production-oriented improvements include:

- HTTPS with AWS Certificate Manager
- custom DNS with Route 53
- Kubernetes Ingress
- AWS Secrets Manager integration
- dedicated Kubernetes application namespaces
- automated application tests before CI/CD deployment
- container vulnerability gates
- Terraform remote state with locking
- Horizontal Pod Autoscaling
- centralized application logging
- Grafana alerting and notification integrations

---

# Author

**Alex Plokhikh**

DevOps project built as an end-to-end implementation of AWS infrastructure provisioning, Kubernetes deployment, persistent storage, CI/CD automation, self-healing, and monitoring.
