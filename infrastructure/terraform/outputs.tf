output "ecr_repository_urls" {
  description = "ECR repository URLs for all services"
  value = {
    for svc, repo in aws_ecr_repository.services :
    svc => repo.repository_url
  }
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "eks_vpc_id" {
  description = "eksctl VPC ID"
  value       = data.aws_vpc.eks.id
}

output "eks_public_subnets" {
  description = "eksctl public subnet IDs"
  value       = data.aws_subnets.eks_public.ids
}