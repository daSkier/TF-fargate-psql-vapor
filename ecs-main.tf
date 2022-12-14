# ECS Cluster
resource "aws_ecs_cluster" "vapor_cluster" {
  name = "${var.service_name}-${var.environment_name}-server-cluster"
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

# To repull/redeploy with updated images
# aws ecs update-service --cluster <cluster name ARN> --service <service name ARN> --force-new-deployment

# ECS task definition template 
data "template_file" "vapor_server_task_template" {
  template = file("vaporV4.json")

  vars = {
    service_name   = var.service_name
    env_name       = var.environment_name
    container_port = var.container_port
    ecr_image      = var.ecr_image
    cw_log_group   = aws_cloudwatch_log_group.vapor_server_logs.name
    psql_url       = "postgresql://${var.psql_db_user}:${aws_secretsmanager_secret_version.vapor_rds_password_version.secret_string}@${aws_db_instance.rds.address}:${aws_db_instance.rds.port}/${var.psql_db_name}?sslmode=require"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "vapor_server_task" {
  family                   = "${var.service_name}-${var.environment_name}-server-task"
  container_definitions    = data.template_file.vapor_server_task_template.rendered
  task_role_arn            = data.aws_iam_role.psvaporv4_task_role.arn
  execution_role_arn       = data.aws_iam_role.psvaporv4_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 4096
  memory                   = 8192
}


# ECS Service
resource "aws_ecs_service" "vapor_server_service" {
  name    = "${var.service_name}-${var.environment_name}-server-service"
  cluster = aws_ecs_cluster.vapor_cluster.id
  depends_on = [
    aws_lb_target_group.vapor_server_target_group,
    # aws_lb_listener.vapor_server_listener_https, #need to come back for this
    aws_lb_listener.vapor_server_listener_http,
  ]

  task_definition                    = aws_ecs_task_definition.vapor_server_task.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 400
  launch_type                        = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_subnet.*.id
    security_groups  = [aws_security_group.vapor_server_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vapor_server_target_group.arn
    container_name   = "${var.service_name}-${var.environment_name}-server"
    container_port   = var.container_port
  }
}

# Security Group
resource "aws_security_group" "vapor_server_sg" {
  name        = "${var.service_name}-${var.environment_name}-server-ecs-sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0 #var.container_port
    security_groups = [aws_security_group.vapor_server_alb_sg.id]
    self            = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-${var.environment_name}-ecs-sg"
  }
}

# Cloudwatch log group 
resource "aws_cloudwatch_log_group" "vapor_server_logs" {
  name = "${var.service_name}-${var.environment_name}"
}

#psvaporv4 execution role
data "aws_iam_role" "psvaporv4_execution_role" {
  name = "PSVaporV4ExecutionRole"
}

data "aws_iam_role" "psvaporv4_task_role" {
  name = "PSVaporV4TaskRole"
}

# resource "aws_appautoscaling_target" "vapor_autoscaling" {
#   max_capacity       = var.max_containers
#   min_capacity       = var.min_containers
#   resource_id        = "service/${aws_ecs_cluster.vapor_cluster.name}/${aws_ecs_service.vapor_server_service.name}"
#   role_arn           = data.aws_iam_role.psvaporv4_execution_role.arn
#   scalable_dimension = "ecs:service:DesiredCount"
#   service_namespace  = "ecs"

#   depends_on = [aws_ecs_service.vapor_server_service]
# }

# resource "aws_appautoscaling_policy" "vapor_cpu_scaling" {
#   name               = "${var.service_name}-${var.environment_name}-cpu-autoscaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.vapor_autoscaling.resource_id
#   scalable_dimension = aws_appautoscaling_target.vapor_autoscaling.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.vapor_autoscaling.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.cpu_scaling_target_value

#     scale_in_cooldown  = 300
#     scale_out_cooldown = 300

#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageCPUUtilization"
#     }
#   }

#   depends_on = [aws_appautoscaling_target.vapor_autoscaling]
# }

# resource "aws_appautoscaling_policy" "vapor_mem_scaling" {
#   name               = "${var.service_name}-${var.environment_name}-mem-autoscaling-policy"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.vapor_autoscaling.resource_id
#   scalable_dimension = aws_appautoscaling_target.vapor_autoscaling.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.vapor_autoscaling.service_namespace

#   target_tracking_scaling_policy_configuration {
#     target_value = var.mem_scaling_target_value

#     scale_in_cooldown  = 300
#     scale_out_cooldown = 300

#     predefined_metric_specification {
#       predefined_metric_type = "ECSServiceAverageMemoryUtilization"
#     }
#   }

#   depends_on = [aws_appautoscaling_target.vapor_autoscaling]
# }
