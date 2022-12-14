#Vapor Vars
variable "service_name" {
  type        = string
  default     = "vapor4"
  description = "the service name to be used with stack creation"
  sensitive   = false
}
variable "environment_name" {
  type        = string
  default     = "dev1"
  description = "the env name to be used with stack creation"
  sensitive   = false
}
variable "container_port" {
  type        = number
  default     = 8080
  description = "the port for accessing the fargate container"
  sensitive   = false
}
variable "load_balancer_port" {
  type        = number
  default     = 443
  description = "the port for incoming traffic to the load balancer"
  sensitive   = false
}
variable "healthcheck_path" {
  type        = string
  default     = "/healthcheck"
  description = "the route for checking if the fargate service is running/healthy"
  sensitive   = false
}
variable "hosted_zone_name" {
  type        = string
  default     = "yourdomain.com"
  description = "the domain to use"
  sensitive   = false
}
variable "min_containers" {
  type        = number
  default     = 1
  description = "the minimum number of fargate containers"
  sensitive   = false
}
variable "max_containers" {
  type        = number
  default     = 10
  description = "the minimum number of fargate containers"
  sensitive   = false
}
variable "cpu_scaling_target_value" {
  type        = number
  default     = 70
  description = "the target CPU utilization value (%)"
  sensitive   = false
}
variable "mem_scaling_target_value" {
  type        = number
  default     = 80
  description = "the target CPU utilization value (%)"
  sensitive   = false
}
#Postgres db name
#- Must contain 1 to 63 letters, numbers, or underscores.
#- Must begin with a letter or an underscore. Subsequent characters can be letters, underscores, or digits (0-9).
#- Can't be a word reserved by the specified database engine
variable "psql_db_name" {
  type        = string
  default     = "VaporV4"
  description = "the minimum number of fargate containers"
  sensitive   = false
}

variable "psql_db_user" {
  type        = string
  default     = "rdsAdmin"
  description = "the username for the rds instance"
  sensitive   = false
}

variable "ecr_image" {
  type        = string
  default     = "your.ecr.location.amazonaws.com/repo:tag"
  description = "the ecr image to use for the vapor server"
  sensitive   = false
}

locals {
  vpc_cidr_block     = "10.2.0.0/16"
  public_subnets     = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnets    = ["10.2.10.0/24", "10.2.20.0/24"]
  availability_zones = ["us-west-2b", "us-west-2c"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}
