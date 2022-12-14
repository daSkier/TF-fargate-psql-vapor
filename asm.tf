# Secrets
resource "aws_secretsmanager_secret" "vapor_rds_secret" {
  name                    = "${var.service_name}-${var.environment_name}-rds-secret"
  description             = "holds the relevant connection information for the rds instance"
  recovery_window_in_days = 0
}

resource "random_password" "generated_rds_password" {
  length           = 22
  special          = true
  override_special = "!#-_=+"
}

resource "aws_secretsmanager_secret_version" "vapor_rds_password_version" {
  secret_id     = aws_secretsmanager_secret.vapor_rds_secret.id
  secret_string = random_password.generated_rds_password.result
}