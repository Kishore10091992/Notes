# Create App User Secret in Secrets Manager

resource "random_password" "vdr_app_password" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "vdr_app" {
  name = "rds/vdr/app-user"
}

resource "aws_secretsmanager_secret_version" "vdr_app_version" {
  secret_id = aws_secretsmanager_secret.vdr_app.id

  secret_string = jsonencode({
    username = "vdr_app_user"
    password = random_password.vdr_app_password.result
  })
}

# Read Master Credentials from Secrets Manager

data "aws_secretsmanager_secret" "rds_master" {
  name = "rds/vdr/master"
}

data "aws_secretsmanager_secret_version" "rds_master_version" {
  secret_id = data.aws_secretsmanager_secret.rds_master.id
}

locals {
  rds_master = jsondecode(
    data.aws_secretsmanager_secret_version.rds_master_version.secret_string
  )
}

# Configure MySQL Provider (Critical) ------> Terraform will connect directly to the RDS endpoint.

provider "mysql" {
  endpoint = aws_db_instance.vdr.endpoint
  username = local.rds_master.username
  password = local.rds_master.password
}

# Create Application User

resource "mysql_user" "vdr_app_user" {
  user               = "vdr_app_user"
  host               = "%"
  plaintext_password = random_password.vdr_app_password.result
}

# Grant Required Privileges -----> DML Privileges

resource "mysql_grant" "vdr_dml" {
  user       = mysql_user.vdr_app_user.user
  host       = mysql_user.vdr_app_user.host
  database   = "vdr"
  privileges = [
    "SELECT",
    "INSERT",
    "UPDATE",
    "DELETE"
  ]
}

# EXECUTE Privilege

resource "mysql_grant" "vdr_execute" {
  user       = mysql_user.vdr_app_user.user
  host       = mysql_user.vdr_app_user.host
  database   = "vdr"
  privileges = ["EXECUTE"]
}

# SHOW VIEW Privilege

resource "mysql_grant" "vdr_show_view" {
  user       = mysql_user.vdr_app_user.user
  host       = mysql_user.vdr_app_user.host
  database   = "vdr"
  privileges = ["SHOW VIEW"]
}