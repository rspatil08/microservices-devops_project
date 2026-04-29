/*===================================================================================================
main.tf has 8 sections:

1. Provider          →  connects Terraform to AWS
2. Data Sources      →  reads existing info from AWS
3. ECR Repositories  →  creates Docker image storage
4. VPC               →  creates the network
5. IAM Roles         →  creates permissions
6. EKS Cluster       →  creates Kubernetes cluster
7. Security Group    →  creates firewall rules for Jenkins
8. EC2 for Jenkins   →  creates Jenkins server
======================================================================================================*/

/*=============================
Section 1 — Provider
===============================*/
provider "aws" {
  region = var.aws_region
}
/*=====================================================================================================
What it means:   tells Terraform "we are working with AWS"
var.aws_region:  picks up "ap-south-1" from terraform.tfvars
Think of it as:  the first thing you do when you open
                 AWS console — you select a region
                 Terraform does the same here automatically
=======================================================================================================*/

/*=============================
Section 2 — Data Sources
===============================*/
data "aws_caller_identity" "current" {
}
/*=====================================================================================================
What it means:   reads your AWS account ID automatically
Why needed:      ECR repository URLs contain your account ID:
                 552357224711.dkr.ecr.ap-south-1.amazonaws.com/frontend
                 ↑ this number
                 instead of hardcoding it, Terraform fetches it
=======================================================================================================*/
data "aws_availability_zones" "available" {
  state = "available"
}
/*=====================================================================================================
What it means:   asks AWS "which availability zones exist
                 in ap-south-1 that are currently available?"
AWS gives back:  ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
Why needed:      we spread our subnets across 2 AZs
                 for high availability
                 if one AZ goes down, app still runs in the other
=======================================================================================================*/
data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]  # Canonical

    filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
/*=====================================================================================================
What it means:   finds the latest Ubuntu 22.04 AMI automatically
owners:          099720109477 is Canonical's official AWS account
                 (company that makes Ubuntu)
                 using their ID ensures you get genuine Ubuntu
most_recent:     always gets the latest patched version
Why useful:      AMI IDs change per region and get updated
                 hardcoding an AMI ID would break in other regions
                 this finds the right one automatically
=======================================================================================================*/

/*=============================
Section 3 — ECR Repositories
===============================*/
resource "aws_ecr_repository" "services" {
    for_each = toset(var.services)
    name = each.value
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
      scan_on_push = true
    }
}
/*=====================================================================================================
What it means:   creates one ECR repo for each service in your list
for_each:        loops through all 11 services automatically
                 instead of writing 11 separate resource blocks

toset():         converts the list to a set so Terraform
                 can loop through it properly

each.value:      the current service name in the loop
                 first iteration  → "frontend"
                 second iteration → "cartservice"
                 and so on...

Result:          11 ECR repositories created automatically:
                 552357224711.dkr.ecr.ap-south-1.amazonaws.com/frontend
                 552357224711.dkr.ecr.ap-south-1.amazonaws.com/cartservice
                 ... and 9 more
=======================================================================================================*/

/*=====================================================================================================
What it means:   every time Jenkins pushes a Docker image to ECR
                 AWS automatically scans it for security vulnerabilities
Why important:   catches things like outdated libraries with known CVEs
                 before they reach production
This is:         a DevOps security best practice
=======================================================================================================*/

/*=============================
Section 4 — VPC (Network)
===============================*/
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
}
/*=====================================================================================================
What it means:   creates a private network on AWS for your project
cidr_block:      10.0.0.0/16 means your network can have
                 65,536 IP addresses (10.0.0.0 to 10.0.255.255)
dns_hostnames:   lets AWS resources talk to each other by name
                 instead of IP address
Think of VPC as: your own private building inside AWS
                 nothing gets in or out unless you allow it
=======================================================================================================*/
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    count = 2
    cidr_block = "10.0.${count.index}.0/24"
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[count.index]
}
/*=====================================================================================================
What it means:   creates 2 subnets inside your VPC
count = 2:       runs this block twice automatically
                 subnet 1 → 10.0.0.0/24 in ap-south-1a
                 subnet 2 → 10.0.1.0/24 in ap-south-1b

map_public_ip:   any EC2 or node launched here
                 automatically gets a public IP address

Why 2 subnets    EKS requires subnets in at least 2 AZs
in 2 AZs:        if ap-south-1a goes down
                 your app keeps running in ap-south-1b

Think of subnet: as a floor inside your building (VPC)
                 each floor is in a different zone
=======================================================================================================*/
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
}
/*=====================================================================================================
What it means:   creates a door from your VPC to the internet
Without this:    nothing inside your VPC can reach the internet
                 Jenkins can't download packages
                 EKS nodes can't pull Docker images
Think of it as:  the main entrance/exit of your building
=======================================================================================================*/
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}
/*=====================================================================================================
route table:     a set of rules that says where traffic goes
0.0.0.0/0:       means "all internet traffic"
gateway_id:      send it through the internet gateway

association:     connects the route table to both subnets
                 so both subnets can reach the internet

Think of it as:  road signs inside your building
                 "to reach the internet → use this door"
=======================================================================================================*/

/*=============================
Section 5 — IAM Roles
===============================*/

# ── IAM Role for EKS Cluster ─────────────────────────────────────

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "sts:AssumeRole",
      "Principal" : { "Service" : "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}
/*=====================================================================================================
What it means:   gives EKS permission to manage AWS resources
                 on your behalf

assume_role:     allows the EKS service specifically to use this role
policy_attachment: gives EKS the AmazonEKSClusterPolicy
                   which allows it to create load balancers,
                   manage networking, etc.

Think of it as:  an ID badge for your EKS cluster
                 "this cluster is allowed to do these things"
=======================================================================================================*/

# ── IAM ROLE FOR EKS WORKER NODES ─────────────────────────────────────

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "sts:AssumeRole",
      "Principal" : { "Service" : "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.eks_nodes.name
}
/*=====================================================================================================
eks_worker_node_policy:  lets nodes join the EKS cluster
eks_cni_policy:          lets nodes set up pod networking
                         (CNI = Container Network Interface)
                         pods need IP addresses → this policy
                         allows nodes to assign them
eks_ecr_policy:          lets nodes PULL Docker images from ECR
                         ReadOnly → nodes can download images
                         but cannot push or delete them

Think of it as:  3 ID badges for your worker nodes:
                 1. "allowed to join the cluster"
                 2. "allowed to set up networking"
                 3. "allowed to download Docker images"
=======================================================================================================*/

# ── IAM ROLE FOR JENKINS EC2 ─────────────────────────────────────
resource "aws_iam_role" "jenkins" {
  name = "${var.project_name}-jenkins-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : "sts:AssumeRole",
      "Principal" : { "Service" : "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
    role = aws_iam_role.jenkins.name
}

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.jenkins.name
}

resource "aws_iam_instance_profile" "jenkins" {
    name = "${var.project_name}-jenkins-profile"
    role = aws_iam_role.jenkins.name
}
/*=====================================================================================================
Key difference between all 3 roles at a glance:
_______________________________________________________________________________________________
| Role	           |  Runs on	            |  ECR Access	              |  EKS Access        |
|------------------|------------------------|-----------------------------|--------------------|
| Jenkins role	   |  EC2 (Jenkins server)	|  Full (push images)	      |  Deploy apps       |
| EKS Cluster role |  EKS control plane	    |  None	                      |  Manage cluster    |
| EKS Node role	   |  EC2 (worker nodes)	|  Read only (pull images)    |  Join cluster      |
|______________________________________________________________________________________________|

=======================================================================================================*/

/*=============================
Section 6 — EKS Cluster
===============================*/
resource "aws_eks_cluster" "main" {
    name = var.eks_cluster_name
    role_arn = aws_iam_role.eks_cluster.arn
    version = "1.31"

    vpc_config {
      subnet_ids = aws_subnet.public[*].id
    }

    depends_on = [ 
        aws_iam_role_policy_attachment.eks_cluster_policy
     ]
}
/*=====================================================================================================
name:        "devops-demo" from your tfvars
role_arn:    attaches the IAM role we created above
version:     Kubernetes version 1.31 (stable, recent)
vpc_config:  puts the cluster inside your VPC
             [*] means both subnets

depends_on:  very important —
             tells Terraform "don't create the EKS cluster
             until the IAM role policy is attached"
             without this, cluster creation might fail
             because permissions aren't ready yet
=======================================================================================================*/
resource "aws_eks_node_group" "workers" {
  cluster_name   = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-workers"
  node_role_arn = aws_iam_role.eks_nodes.arn
  subnet_ids = aws_subnet.public[*].id
  instance_types = [var.eks_node_instance_type]

  scaling_config {
    desired_size = var.eks_desired_nodes
    min_size     = var.eks_min_nodes
    max_size     = var.eks_max_nodes
  }

  depends_on = [ 
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
   ]
}
/*=====================================================================================================
What it means:   creates the actual EC2 machines that
                 run your microservice pods

cluster_name:    attaches these nodes to your EKS cluster
instance_types:  t3.medium from your tfvars
scaling_config:  desired=2, min=1, max=3 from your tfvars

Think of EKS cluster vs node group:
  EKS cluster    =  the Kubernetes control plane
                    (the brain — manages everything)
  Node group     =  the worker machines
                    (the muscles — actually run your pods)
=======================================================================================================*/

/*=======================================
Section 7 — Security Group for Jenkins
=========================================*/
resource "aws_security_group" "jenkins" {
    name = "${var.project_name}-jenkins-sg"
    description = "Security group for Jenkins server"
    vpc_id = aws_vpc.main.id
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
/*=====================================================================================================
Think of security group as:  a firewall with rules

ingress = incoming traffic rules:
  port 22    →  SSH access
               you need this to log into Jenkins EC2
               ssh -i jenkins-key.pem ubuntu@<ip>

  port 8080  →  Jenkins UI access
               you need this to open Jenkins in browser
               http://<jenkins-ip>:8080

egress = outgoing traffic rules:
  port 0, protocol -1  →  allow ALL outbound traffic
  Why:  Jenkins needs to:
        - download packages from internet
        - push images to ECR
        - deploy to EKS
        - send webhook responses to GitHub

cidr_blocks 0.0.0.0/0:  means from any IP address
Note:  in real production you'd restrict port 22
       to only your IP address
       for learning, open is fine
=======================================================================================================*/

/*=======================================
Section 8 — EC2 for Jenkins
=========================================*/
resource "aws_instance" "jenkins" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.jenkins_instance_type
    subnet_id = aws_subnet.public[0].id
    vpc_security_group_ids = [aws_security_group.jenkins.id]
    iam_instance_profile = aws_iam_instance_profile.jenkins.name
    key_name = var.jenkins_key_name

    root_block_device {
      volume_size = 20
      volume_type = "gp3"
    }

    user_data = <<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y openjdk-17-jdk docker.io curl wget

    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | apt-key add -
    sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update -y
    apt-get install -y jenkins

    usermod -aG docker jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOT
}
/*=====================================================================================================
ami:                   Ubuntu 22.04 fetched automatically
instance_type:         t3.medium from tfvars
subnet_id:             place it in first public subnet
                       so it gets a public IP
security_group:        apply the firewall rules we defined above
iam_instance_profile:  attach the Jenkins IAM role
                       so Jenkins can push to ECR and deploy to EKS
                       WITHOUT storing any AWS credentials on the server
key_name:              attach jenkins-key for SSH access

root_block_device:     20GB storage for Jenkins
                       enough for Docker images, build artifacts
volume_type gp3:       faster and cheaper than gp2

user_data:             THIS IS THE MAGIC PART ↓
                       shell script that runs automatically
                       when EC2 starts for the first time
                       installs Java, Docker, Jenkins
                       so you don't have to SSH in and do it manually

=======================================================================================================*/