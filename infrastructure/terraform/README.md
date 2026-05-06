Overall Structure

main.tf has 8 sections:

| Component        | Function                                |
|------------------|-----------------------------------------|
| Provider         | Connects Terraform to AWS               |
| Data Sources     | Reads existing info from AWS            |
| ECR Repositories | Creates Docker image storage            |
| VPC              | Creates the network                     |
| IAM Roles        | Creates permissions                     |
| EKS Cluster      | Creates Kubernetes cluster              |
| Security Group   | Creates firewall rules for Jenkins      |
| EC2 for Jenkins  | Creates Jenkins server                  |