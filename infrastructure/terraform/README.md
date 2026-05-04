Overall Structure

main.tf has 8 sections:

Provider → connects Terraform to AWS
Data Sources → reads existing info from AWS
ECR Repositories → creates Docker image storage
VPC → creates the network
IAM Roles → creates permissions
EKS Cluster → creates Kubernetes cluster
Security Group → creates firewall rules for Jenkins
EC2 for Jenkins → creates Jenkins server