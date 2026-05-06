# Microservices DevOps Pipeline on AWS

End-to-end DevOps pipeline for deploying a cloud-native microservices e-commerce application on AWS — fully automated from code push to live deployment using Jenkins, Terraform, Kubernetes, Prometheus, and Grafana.

---

## 📋 Table of Contents
- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Application — Online Boutique](#application)
- [What I Built as DevOps Engineer](#what-i-built)
- [CI/CD Pipeline Flow](#cicd-pipeline)
- [Infrastructure Details](#infrastructure)
- [Monitoring](#monitoring)
- [Project Structure](#project-structure)
- [How to Deploy](#how-to-deploy)
- [Screenshots](#screenshots)
- [Cost Estimate](#cost-estimate)
- [Key Learnings](#key-learnings)
- [Author](#author)

---

## 📌 Project Overview <a name="project-overview"></a>

This project demonstrates a complete DevOps workflow:

- A **cloud-native e-commerce application** with 11 microservices is containerized and deployed on AWS
- Every `git push` automatically triggers a **Jenkins CI/CD pipeline**
- All AWS infrastructure is provisioned using **Terraform** as code
- Application runs on **AWS EKS** (Kubernetes) with zero-downtime deployments
- System health monitored in real-time via **Prometheus and Grafana**

> **Note:** My contribution was building the complete DevOps infrastructure, CI/CD pipeline, and monitoring stack around it.

---

## 🏗️ Architecture <a name="architecture"></a>

### Application Architecture
[![Architecture of microservices](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

### DevOps Pipeline Architecture

<img src="/docs/img/devops_pipeline_arch.png" width="400">

---

## 🛠️ Tech Stack <a name="tech-stack"></a>

| Category | Tool | Purpose |
|---|---|---|
| Version Control | GitHub | Source code + webhook trigger |
| CI/CD | Jenkins | Automated build and deploy |
| Containerization | Docker | Package each microservice |
| Container Registry | AWS ECR | Store Docker images |
| Orchestration | AWS EKS | Kubernetes cluster |
| Infrastructure as Code | Terraform | Provision AWS resources |
| Cluster Management | eksctl | Create and manage EKS |
| Monitoring | Prometheus | Collect system metrics |
| Dashboards | Grafana | Visualize metrics and alerts |
| In-memory Cache | Redis | Shopping cart storage |
---

## 🛍️ Application — Online Boutique <a name="application"></a>

**Online Boutique** is a cloud-native e-commerce demo application composed of 11 microservices written in different languages that communicate over gRPC.

| Service | Language | Description |
|---|---|---|
| frontend | Go | Serves the website via HTTP |
| cartservice | C# | Stores shopping cart items in Redis |
| productcatalogservice | Go | Product listings from JSON file |
| currencyservice | Node.js | Currency conversion using ECB rates |
| paymentservice | Node.js | Mock credit card payment processing |
| shippingservice | Go | Mock shipping cost estimation |
| emailservice | Python | Mock order confirmation emails |
| checkoutservice | Go | Orchestrates payment, shipping, email |
| recommendationservice | Python | Product recommendations |
| adservice | Java | Contextual text advertisements |
| loadgenerator | Python/Locust | Synthetic traffic generation |

| Home Page | Checkout Screen |
|---|---|
| [![Home](/docs/img/online-boutique-frontend-1.png)](/docs/img/online-boutique-frontend-1.png) | [![Checkout](/docs/img/online-boutique-frontend-2.png)](/docs/img/online-boutique-frontend-2.png) |

---

## 👩‍💻 What I Built as DevOps Engineer <a name="what-i-built"></a>

### 1. AWS Infrastructure (Terraform)
- VPC with public subnets across 2 availability zones
- 11 AWS ECR repositories — one per microservice
- IAM roles and policies for EKS nodes and Jenkins EC2
- Jenkins EC2 instance with automated software installation via `user_data`
- Security groups for Jenkins (ports 22 and 8080)

### 2. Kubernetes Cluster (eksctl)
- Managed EKS cluster with 2 t3.small worker nodes
- Auto-scaling configured — min: 1, max: 3 nodes
- IAM identity mapping for Jenkins → EKS secure access

### 3. CI/CD Pipeline (Jenkinsfile)
- GitHub webhook triggers pipeline automatically on every push
- Sequential Docker builds for all 11 microservices
- Images tagged with Jenkins build number for easy rollback
- Automatic push to AWS ECR with `:latest` and `:build-number` tags
- Zero-downtime rolling deployment to EKS via `kubectl`

### 4. Monitoring Stack
- Prometheus running on Jenkins EC2 as Docker container
- Node Exporter for system-level metrics collection
- Grafana dashboards showing CPU, Memory, Disk, Network metrics
- Alert rule configured for high memory usage (>85%)

---

## 🔄 CI/CD Pipeline Flow <a name="cicd-pipeline"></a>

<img src="/docs/img/cicd_pipeline_flow.png" width="400">

---

## ☁️ Infrastructure Details <a name="infrastructure"></a>

| Component         | Details                                |
|-------------------|----------------------------------------|
| Cloud Provider    | AWS (eu-north-1 — Stockholm)           |
| Jenkins Server    | t3.micro EC2 + 2GB swap space          |
| EKS Worker Nodes  | 2 × t3.small                           |
| ECR Repositories  | 11 (one per microservice)              |
| Networking        | VPC with 2 public subnets across 2 AZs |
| IAM               | Separate roles for Jenkins and EKS nodes |

---

## 📊 Monitoring <a name="monitoring"></a>

Prometheus and Grafana run as Docker containers on the Jenkins EC2 instance.

**Prometheus** scrapes metrics from:
- Node Exporter (system metrics — CPU, Memory, Disk, Network)
- Prometheus itself (internal health metrics)

**Grafana Dashboards imported:**
- Node Exporter Full (Dashboard ID: 1860) — system metrics
- Prometheus Stats (Dashboard ID: 3662) — Prometheus internals

**Alert configured:**
- High Memory Alert — triggers when memory usage exceeds 85%
Access:
Prometheus → http://<jenkins-ip>:9090
Grafana    → http://<jenkins-ip>:3000

---

## 📁 Project Structure <a name="project-structure"></a>

<img src="/docs/img/project_structure.png" width="600">

---

## 🚀 How to Deploy <a name="how-to-deploy"></a>

### Prerequisites
```bash
aws --version        # AWS CLI configured with IAM credentials
terraform --version  # v1.x+
eksctl version       # v0.x+
kubectl version      # v1.x+
docker --version     # Docker installed
```

### Step 1 — Provision AWS Infrastructure
```bash
cd infrastructure/terraform
terraform init
terraform apply
```
Creates: VPC, ECR repositories, IAM roles, Jenkins EC2

### Step 2 — Create EKS Cluster
```bash
eksctl create cluster \
  --name devops-demo \
  --region eu-north-1 \
  --nodegroup-name microservices-demo-workers \
  --node-type t3.small \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

### Step 3 — Install Jenkins on EC2
```bash
# SSH into Jenkins EC2
ssh -i jenkins-key.pem ubuntu@<jenkins-ip>

# Install Java 21
sudo apt-get install -y openjdk-21-jdk

# Install Docker
sudo apt-get install -y docker.io
sudo usermod -aG docker jenkins

# Download and start Jenkins
sudo mkdir -p /opt/jenkins
cd /opt/jenkins
sudo wget https://get.jenkins.io/war-stable/latest/jenkins.war
sudo java -jar jenkins.war --httpPort=8080
```

### Step 4 — Configure Jenkins
- Install plugins: `Pipeline, Git, GitHub Integration, Docker Pipeline`
- Add credentials: `github-credentials`, `aws-account-id`
- Create pipeline job pointing to `Jenkinsfile` in this repo
- Set up GitHub webhook: `http://<jenkins-ip>:8080/github-webhook/`

### Step 5 — Run Pipeline
```bash
git push origin main
# Pipeline triggers automatically via GitHub webhook
```

### Step 6 — Access Application
```bash
kubectl get svc frontend-external -n default
# Open EXTERNAL-IP in browser
```

### Step 7 — Setup Monitoring
```bash
# SSH into Jenkins EC2
sudo docker network create monitoring

# Run Prometheus
sudo docker run -d --name prometheus \
  --network monitoring -p 9090:9090 \
  -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

# Run Node Exporter
sudo docker run -d --name node-exporter \
  --network monitoring -p 9100:9100 \
  prom/node-exporter

# Run Grafana
sudo docker run -d --name grafana \
  --network monitoring -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana
```

### Step 8 — Destroy Resources (to save costs)
```bash
# Delete EKS cluster
eksctl delete cluster --region=eu-north-1 --name=devops-demo

# Destroy Terraform resources
cd infrastructure/terraform
terraform destroy
```
---

## 📸 Screenshots <a name="screenshots"></a>

### Jenkins CI/CD Pipeline
<img src="/docs/img/jenkins_pipeline.png" width="100%">

### All Pods Running on EKS
<img src="/docs/img/running_pods.png" width="100%">

### Grafana Monitoring Dashboard
<img src="/docs/img/grafana_dashboard.png" width="100%">

### AWS ECR Repositories
<img src="/docs/img/aws_ecr_11repos1.png" width="100%">
<img src="/docs/img/aws_ecr_11repos2.png" width="100%">
<img src="/docs/img/aws_ecr_11repos3.png" width="100%">

### EKS Cluster
<img src="/docs/img/aws_eks_cluster.png" width="100%">

### Live Application
<img src="/docs/img/live_website.png" width="100%">

---

## 💰 AWS Cost Estimate <a name="cost-estimate"></a>

| Resource | Instance Type | Cost |
|---|---|---|
| Jenkins EC2 | t3.micro | ~$0.01/hour |
| EKS Control Plane | — | ~$0.10/hour |
| EKS Worker Node 1 | t3.small | ~$0.02/hour |
| EKS Worker Node 2 | t3.small | ~$0.02/hour |
| ECR Storage | — | ~$0.10/GB/month |
| **Total while running** | | **~$0.15/hour** |

> 💡 **Cost Tip:** Run `eksctl delete cluster` and `terraform destroy` when not actively using the project. Recreate with one command when needed.

---

## 🎯 Key Learnings <a name="key-learnings"></a>

- Provisioning cloud infrastructure with **Terraform as code**
- Setting up a production-grade **Kubernetes cluster on AWS EKS**
- Building **automated CI/CD pipelines** with Jenkins
- **Containerizing microservices** and managing images in ECR
- Deploying to Kubernetes with **zero-downtime rolling updates**
- Monitoring infrastructure with **Prometheus and Grafana**
- Troubleshooting real-world issues:
  - RAM constraints on t3.micro (solved with swap space)
  - EKS node networking issues (solved with eksctl)
  - IAM permissions for Jenkins → EKS access
  - GPG key issues during Jenkins installation

---

## 👩‍💻 Author <a name="author"></a>

**Rishika Patil** — Cloud & DevOps Engineer

- 💼 [LinkedIn](https://www.linkedin.com/in/rishika-patil0808/)
- 🐙 [GitHub](https://github.com/rspatil08)
- 📧 rspatil.010716@gmail.com

---
