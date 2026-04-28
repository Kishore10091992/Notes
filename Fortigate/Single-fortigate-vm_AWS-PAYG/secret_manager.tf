resource "aws_secretsmanager_secret" "fgt_admin" {
  name        = "fortigate/${var.fgvm_sm}/admin"
  description = "FortiGate admin access details"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "fgt_admin_value" {
  secret_id = aws_secretsmanager_secret.fgt_admin.id

  secret_string = jsonencode({
    public_ip = aws_eip.FGTPublicIP.public_ip
    username  = "admin"
    password  = aws_instance.fgtvm.id
  })
}