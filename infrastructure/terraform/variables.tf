/*==============================================================================
Every Variable Has This Structure

variable "variable_name" {
  description = "what this variable is for"
  type        = string / number / list
  default     = "default value"
}
================================================================================*/

/*==============================================================================
How variables.tf and terraform.tfvars Work Together
variables.tf          terraform.tfvars
─────────────         ────────────────
defines the           sets the actual
variable exists   +   values you want
and its type          to use

variable "aws_region"     aws_region = "ap-south-1"
  type = string       →   
  default = "ap-south-1"  (overrides the default)
==================================================================================*/

/*=============================
Variable 1 — AWS Region
===============================*/
variable "aws_region" {
  description = "AWS region"
  type = string
  default = "eu-north-1"
}
/*=====================================================================================================
Tells Terraform:  which AWS region to create everything in
Your value:       ap-south-1 (Mumbai)
Why variable:     tomorrow if you want to switch to us-east-1
                  you change only this one line
=======================================================================================================*/

/*=============================
Variable 2 — Project Name
===============================*/
variable "project_name" {
  description = "Project name used for naming resources"
  type = string
  default = "microservices-demo"
}
/*=====================================================================================================
Tells Terraform:  a name to tag all resources with
Used for:         naming things like
                  "microservices-demo-vpc"
                  "microservices-demo-jenkins"
                  "microservices-demo-eks-cluster-role"
Why useful:       when you have multiple projects in AWS
                  you can tell which resource belongs to which project
=======================================================================================================*/

/*=============================
Variable 3 — EKS Cluster Name
===============================*/
variable "eks_cluster_name" {
  description = "EKS cluster name"
  type = string
  default = "devops-demo"
}
/*=====================================================================================================
Tells Terraform:  what to name your Kubernetes cluster
Used in:          aws_eks_cluster resource in main.tf
                  also used in Jenkins to connect kubectl
=======================================================================================================*/

/*===================================
Variable 4 — EKS Node Instance Type
=====================================*/
variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type = string
  default = "t2.micro"
}
/*=====================================================================================================
Tells Terraform:  what size EC2 machines to use as K8s worker nodes
t3.medium means:  2 CPU, 4GB RAM — enough to run our microservices
Cost impact:      bigger instance = more expensive per hour
                  t3.medium ≈ $0.05/hour per node
=======================================================================================================*/

/*===================================
Variables 5, 6, 7 — EKS Node Count
=====================================*/
variable "eks_desired_nodes" {
  description = "Desired number of worker nodes"
  type = number
  default = 2
}

variable "eks_min_nodes" {
  description = "Minimum number of nodes"
  type = number
  default = 1
}

variable "eks_max_nodes" {
  description = "Maximum number of nodes"
  type = number
  default = 3
}
/*=====================================================================================================
These 3 work together to control auto-scaling:

Low traffic:   EKS scales down to 1 node  (saves money)
Normal:        EKS runs 2 nodes           (our default)
High traffic:  EKS scales up to 3 nodes   (handles load)

For learning:  we set desired=2, but you can change to
               desired=1 to save more money
=======================================================================================================*/

/*================================================
Variable 8 — Jenkins Instance Type
==================================================*/
variable "jenkins_instance_type" {
  description = "EC2 instance type for Jenkins"
  type = string
  default = "t2.micro"
}
/*=====================================================================================================
Tells Terraform:  what size EC2 machine Jenkins runs on
t3.medium:        enough RAM to run Jenkins + build Docker images
If builds are slow you'd change this to t3.large
=======================================================================================================*/

/*================================================
Variable 9 — Jenkins Key Name
==================================================*/
variable "jenkins_key_name" {
  description = "EC2 key pair name for SSH access to Jenkins"
  type = string
  default = "jenkins-key"
}
/*=====================================================================================================
Tells Terraform:  which SSH key pair to attach to Jenkins EC2
Why needed:       so you can SSH into Jenkins server like this:
                  ssh -i jenkins-key.pem ubuntu@<jenkins-ip>

Important:        this name must exactly match the key pair
                  you create in AWS Console
                  we named ours "jenkins-key" so it matches
=======================================================================================================*/

/*================================================
Variable 10 — Services List
==================================================*/
variable "services" {
  description = "List of microservices for ECR repositories"
  type = list(string)
  default = [ 
    "frontend",
    "shoppingassistantservice",
    "productcatalogservice",
    "currencyservice",
    "paymentservice",
    "shippingservice",
    "emailservice",
    "checkoutservice",
    "recommendationservice",
    "adservice",
    "loadgenerator"
   ]
}
/*=====================================================================================================
Tells Terraform:  create one ECR repository for each service in this list
type = list:      it's a list of strings, not just one value
How it's used:    in main.tf we loop through this list:

  for_each = toset(var.services)
      ↓
  creates 11 ECR repos automatically
  instead of writing 11 separate resource blocks
=======================================================================================================*/