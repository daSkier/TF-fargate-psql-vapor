## vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "vpc0-${var.environment_name}"
  }
}
output "aws_vpc_vpc" {
  description = "vpc"
  value       = aws_vpc.vpc
}

## gateways
resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "igw0-${var.environment_name}"
  }
  vpc_id = aws_vpc.vpc.id
}
resource "aws_eip" "ngw_eip" {
  vpc = true
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  depends_on    = [aws_internet_gateway.igw]
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "ngw0-${var.environment_name}"
  }
}

## public subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "public-subnet${count.index}-${var.environment_name}"
  }
  vpc_id = aws_vpc.vpc.id
}
output "aws_subnet_public_subnet" {
  description = "public subnet"
  value       = aws_subnet.public_subnet
}

## public routing table
resource "aws_route_table" "public_route_table" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt0-${var.environment_name}"
  }
  vpc_id = aws_vpc.vpc.id
}
resource "aws_main_route_table_association" "public_main_route_table" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_subnet_route_table_association" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

## private subnets
resource "aws_subnet" "private_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  cidr_block              = "10.0.${count.index + length(data.aws_availability_zones.available.names)}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "private-subnet${count.index}-${var.environment_name}"
  }
  vpc_id = aws_vpc.vpc.id
}
output "aws_subnet_private_subnet" {
  description = "private subnet id"
  value       = aws_subnet.private_subnet.*
}

## private routing table
resource "aws_route_table" "private_route_table" {
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "private-rt0-${var.environment_name}"
  }
  vpc_id = aws_vpc.vpc.id
}
resource "aws_route_table_association" "private_subnet_route_table_association" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

## security groups

## allows all traffic inside of the vpc itself
## allows outbound traffic from the vpc
resource "aws_security_group" "vpc" {
  name   = "vpc-${var.environment_name}"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = "true"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  #   ingress {
  #     description = "shell ssh"
  #     from_port   = 22
  #     to_port     = 22
  #     protocol    = "tcp"
  #     security_groups = [
  #       "${aws_security_group.shell.id}"
  #     ]
  #   }
}
output "aws_security_group_vpc" {
  value = aws_security_group.vpc
}

# Use this if you want to access the DB from a specific IP address
# resource "aws_security_group" "ops_support" {
#   name   = "ops-support-${var.environment_name}"
#   vpc_id = aws_vpc.vpc.id
#   ingress {
#     description = "local machine DB access"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = [
#       "your.local.ip.address/32",
#     ]
#   }
# }
# output "aws_security_group_ops_support" {
#   description = "aws_security_group ops_support"
#   value       = ["${aws_security_group.ops_support}"]
# }

## rds
resource "aws_security_group" "rds_dbs" {
  name   = "rds-dbs-${var.environment_name}"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 0
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.vapor_server_sg.id]
  }

  ingress {
    from_port       = 0
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.vapor_update_sg.id]
  }

  ingress {
    from_port       = 0
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.vapor_migrate_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_db_subnet_group" "rds_dbs" {
  name = "rds-dbs-${var.environment_name}"
  subnet_ids = [
    #   for subnet in aws_subnet.private_subnet :
    #   subnet.id
    #This should be switched with above for prod deployment
    for subnet in aws_subnet.public_subnet :
    subnet.id
  ]
  tags = {
    Name = "rds-dbs-${var.environment_name}"
  }
}
