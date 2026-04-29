Overall Structure

main.tf has 8 sections:

1. Provider          →  connects Terraform to AWS
2. Data Sources      →  reads existing info from AWS
3. ECR Repositories  →  creates Docker image storage
4. VPC               →  creates the network
5. IAM Roles         →  creates permissions
6. EKS Cluster       →  creates Kubernetes cluster
7. Security Group    →  creates firewall rules for Jenkins
8. EC2 for Jenkins   →  creates Jenkins server
---------------------------------------------------------------------------------------------------------

