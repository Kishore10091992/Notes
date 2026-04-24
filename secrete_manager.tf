resource "random_password" "password" {
 length = 16
 special = true
 override_special   = "!#$%^&*()-_=+[]|:;<>?,."
}

resource "aws_secretsmanager_secret" "secret" {
 name = ""
}

resource "aws_secretsmanager_secret_version" "secret_version" {
 secret_id = aws_secretsmanager_secret.secret.id

 secret_string = jsonencode ({
  username = ""
  password = random_password.password.result
 })
}