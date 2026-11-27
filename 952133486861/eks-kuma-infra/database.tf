resource "aws_db_instance" "kuma-db" {
  db_name                     = "kuma"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_kuma-db.name
  parameter_group_name        = aws_db_parameter_group.kuma-db-params.name
  allocated_storage           = 20
  apply_immediately           = true
  availability_zone           = aws_subnet.eks-data-a.availability_zone
  backup_retention_period     = 0
  copy_tags_to_snapshot       = true
  engine                      = "mariadb"
  engine_version              = "11.4"
  identifier                  = "kuma-db"
  instance_class              = "db.t3.micro"
  manage_master_user_password = true
  max_allocated_storage       = 100
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  upgrade_storage_config      = false
  username                    = "kuma"
  vpc_security_group_ids      = [aws_security_group.db_instance_kuma-db_group.id]
  tags = {
    Name           = "kuma-db"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_parameter_group" "kuma-db-params" {
  description  = "Managed by Struct8"
  family       = "mariadb11.4"
  name_prefix  = "kuma-db-params"
  skip_destroy = false
  lifecycle {
    create_before_destroy = true
  }
  parameter {
    name         = "character_set_server"
    apply_method = "pending-reboot"
    value        = "utf8mb4"
  }
  parameter {
    name         = "collation_server"
    apply_method = "pending-reboot"
    value        = "utf8mb4_unicode_ci"
  }
  tags = {
    Name           = "kuma-db-params"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_kuma-db" {
  name       = "kuma-db-subnet-group"
  subnet_ids = [aws_subnet.eks-data-a.id, aws_subnet.eks-data-b.id]
  tags = {
    Name           = "subnet_group_kuma-db"
    State          = "eks-kuma-infra"
    Struct8Creator = "Contato Struct"
  }
}
