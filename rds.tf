# RDS Instance
resource "aws_db_instance" "rds" {
  identifier                            = "${var.service_name}-${var.environment_name}-db"
  allocated_storage                     = "20"
  storage_type                          = "gp2"
  engine                                = "postgres"
  engine_version                        = "13.4"
  instance_class                        = "db.t3.micro"
  performance_insights_enabled          = true 
  performance_insights_retention_period = 7
  name                                  = var.psql_db_name
  username                              = var.psql_db_user
  password                              = aws_secretsmanager_secret_version.vapor_rds_password_version.secret_string
  db_subnet_group_name                  = aws_db_subnet_group.rds_dbs.name
  vpc_security_group_ids                = [aws_security_group.rds_dbs.id]
  skip_final_snapshot                   = true
  deletion_protection                   = false
  publicly_accessible                   = true
}