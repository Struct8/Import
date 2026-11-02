resource "aws_db_instance" "wp-eb-db" {
  db_name                     = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_wp-eb-db.name
  allocated_storage           = 20
  availability_zone           = aws_subnet.wp-data-a.availability_zone
  backup_retention_period     = 0
  copy_tags_to_snapshot       = true
  engine                      = "mariadb"
  engine_version              = "11.4"
  identifier                  = "wp-eb-db"
  instance_class              = "db.t4g.micro"
  manage_master_user_password = true
  max_allocated_storage       = 100
  skip_final_snapshot         = true
  storage_encrypted           = true
  storage_type                = "gp3"
  upgrade_storage_config      = false
  username                    = "admin"
  vpc_security_group_ids      = [aws_security_group.db_instance_wp-eb-db_group.id]
  tags = {
    Name           = "wp-eb-db"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_db_subnet_group" "subnet_group_wp-eb-db" {
  name       = "wp-eb-db-subnet-group"
  subnet_ids = [aws_subnet.wp-data-a.id, aws_subnet.wp-data-b.id]
  tags = {
    Name           = "subnet_group_wp-eb-db"
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}
