# ALB Instance
resource "aws_lb" "vapor_server_alb" {
  name               = "${var.service_name}-${var.environment_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.vapor_server_alb_sg.id]
  subnets            = aws_subnet.public_subnet.*.id

  enable_deletion_protection = false

  tags = {
    Name = "${var.service_name}-${var.environment_name}-alb"
  }
}

# ALB Listener HTTP
resource "aws_lb_listener" "vapor_server_listener_http" {
  load_balancer_arn = aws_lb.vapor_server_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener HTTPS
resource "aws_lb_listener" "vapor_server_listener_https" {
  load_balancer_arn = aws_lb.vapor_server_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.new_vapor_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vapor_server_target_group.arn
  }
}

# Target Group
resource "aws_lb_target_group" "vapor_server_target_group" {
  name        = "${var.service_name}-${var.environment_name}-alb-target-group"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = var.healthcheck_path
    interval            = 10
    matcher             = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group
resource "aws_security_group" "vapor_server_alb_sg" {
  name        = "${var.service_name}-${var.environment_name}-alb-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group that allows HTTP & HTTPS traffic to load balancer from anywhere"

  ingress {
    from_port        = 0
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-${var.environment_name}-alb-sg"
  }
}