# TF-fargate-psql-vapor

## Background
This is a lightly modified version of the Terraform setup I previously used for hosting my vapor app on AWS Fargate. 

### Components: 
- VPC with an internet gateway (public IP address), nat gateway and security groups
- ECS Fargate clusters with appropriate task configuration
- RDS for PSQL
- Application Load Balancer (ALB)
- Route53 domain configuration
- ACM for SSL cert setup
- ASM for secret management

### Dependencies: 
- an existing ECR repo
- a domain managed with route53
