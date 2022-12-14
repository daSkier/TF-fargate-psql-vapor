# ECS Cluster
resource "aws_ecs_cluster" "vapor_migrate_cluster" {
  name = "${var.service_name}-${var.environment_name}-migrate"
  depends_on = [
    aws_nat_gateway.ngw,
    aws_subnet.private_subnet,
    aws_route_table.private_route_table,
  ]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Revert task
data "template_file" "vapor_revert_task_template" {
  template = file("vaporV4-revert.json")

  vars = {
    service_name   = var.service_name
    env_name       = var.environment_name
    container_port = var.container_port
    ecr_image      = var.ecr_image
    cw_log_group   = aws_cloudwatch_log_group.vapor_migrate_logs.name
    psql_url       = "postgresql://${var.psql_db_user}:${aws_secretsmanager_secret_version.vapor_rds_password_version.secret_string}@${aws_db_instance.rds.address}:${aws_db_instance.rds.port}/${var.psql_db_name}?sslmode=require"
  }
}

resource "aws_ecs_task_definition" "vapor_revert_task" {
  family                   = "${var.service_name}-${var.environment_name}-revert-task"
  container_definitions    = data.template_file.vapor_revert_task_template.rendered
  task_role_arn            = data.aws_iam_role.psvaporv4_task_role.arn
  execution_role_arn       = data.aws_iam_role.psvaporv4_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
}

# Migrate task
data "template_file" "vapor_migrate_task_template" {
  template = file("vaporV4-migrate.json")

  vars = {
    service_name   = var.service_name
    env_name       = var.environment_name
    container_port = var.container_port
    ecr_image      = var.ecr_image
    cw_log_group   = aws_cloudwatch_log_group.vapor_migrate_logs.name
    psql_url       = "postgresql://${var.psql_db_user}:${aws_secretsmanager_secret_version.vapor_rds_password_version.secret_string}@${aws_db_instance.rds.address}:${aws_db_instance.rds.port}/${var.psql_db_name}?sslmode=require"
  }
}

resource "aws_ecs_task_definition" "vapor_migrate_task" {
  family                   = "${var.service_name}-${var.environment_name}-migrate-task"
  container_definitions    = data.template_file.vapor_migrate_task_template.rendered
  task_role_arn            = data.aws_iam_role.psvaporv4_task_role.arn
  execution_role_arn       = data.aws_iam_role.psvaporv4_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
}

# Init Import task
data "template_file" "vapor_initImport_task_template" {
  template = file("vaporV4-initImport.json")

  vars = {
    service_name   = var.service_name
    env_name       = var.environment_name
    container_port = var.container_port
    ecr_image      = var.ecr_image
    cw_log_group   = aws_cloudwatch_log_group.vapor_migrate_logs.name
    psql_url       = "postgresql://${var.psql_db_user}:${aws_secretsmanager_secret_version.vapor_rds_password_version.secret_string}@${aws_db_instance.rds.address}:${aws_db_instance.rds.port}/${var.psql_db_name}?sslmode=require"
  }
}

resource "aws_ecs_task_definition" "vapor_initImport_task" {
  family                   = "${var.service_name}-${var.environment_name}-initImport-task"
  container_definitions    = data.template_file.vapor_initImport_task_template.rendered
  task_role_arn            = data.aws_iam_role.psvaporv4_task_role.arn
  execution_role_arn       = data.aws_iam_role.psvaporv4_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
}

# Security Group
resource "aws_security_group" "vapor_migrate_sg" {
  name        = "${var.service_name}-${var.environment_name}-migrate-ecs-sg"
  description = "no inbound access"
  vpc_id      = aws_vpc.vpc.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-${var.environment_name}-migrate-ecs-sg"
  }
}

# Cloudwatch log group 
resource "aws_cloudwatch_log_group" "vapor_migrate_logs" {
  name = "${var.service_name}-${var.environment_name}-migrate"
}
