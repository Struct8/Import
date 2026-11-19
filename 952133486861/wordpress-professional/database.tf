resource "aws_db_subnet_group" "subnet_group_wp-aurora" {
  name       = "wp-aurora-subnet-group"
  subnet_ids = [aws_subnet.dataA.id, aws_subnet.dataB.id]
  tags = {
    Name           = "subnet_group_wp-aurora"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_rds_cluster" "wp-aurora" {
  database_name               = "wordpress"
  db_subnet_group_name        = aws_db_subnet_group.subnet_group_wp-aurora.name
  kms_key_id                  = data.aws_kms_key.kmsWordpress.arn
  apply_immediately           = true
  backup_retention_period     = 7
  cluster_identifier          = "wp-aurora"
  copy_tags_to_snapshot       = true
  database_insights_mode      = "standard"
  enable_http_endpoint        = true
  engine                      = "aurora-mysql"
  engine_version              = "8.4.mysql_aurora.8.4.8"
  manage_master_user_password = true
  master_username             = "dbadmin"
  monitoring_interval         = 0
  network_type                = "IPV4"
  port                        = 3306
  skip_final_snapshot         = true
  storage_encrypted           = true
  vpc_security_group_ids      = [aws_security_group.rds_cluster_wp-aurora_group.id]
  serverlessv2_scaling_configuration {
    max_capacity             = 4
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
  tags = {
    "Struct8:Backup:wpDailyBackup-uZbC08JN" = true
    Name                                    = "wp-aurora"
    State                                   = "wordpress-professional"
    Struct8Creator                          = "Contato Struct"
  }
}

resource "aws_rds_cluster_instance" "wp-aurora-writer" {
  cluster_identifier    = aws_rds_cluster.wp-aurora.id
  copy_tags_to_snapshot = true
  engine                = aws_rds_cluster.wp-aurora.engine
  identifier            = "wp-aurora-writer"
  instance_class        = "db.serverless"
  promotion_tier        = 1
  tags = {
    Name           = "wp-aurora-writer"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elasticache_replication_group" "wpRedis" {
  kms_key_id                 = data.aws_kms_key.kmsWordpress.arn
  replication_group_id       = "wp-object-cache"
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group_wpRedis.name
  at_rest_encryption_enabled = true
  automatic_failover_enabled = true
  cluster_mode               = "disabled"
  description                = "WordPress object cache for wp_options, postmeta and transients."
  engine_version             = "7.1"
  node_type                  = "cache.t4g.micro"
  num_cache_clusters         = 2
  security_group_ids         = [aws_security_group.elasticache_replication_group_wpRedis_group.id]
  snapshot_retention_limit   = 7
  transit_encryption_enabled = true
  tags = {
    Name           = "wpRedis"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elasticache_subnet_group" "subnet_group_wpRedis" {
  name       = "wpredis-subnet-group"
  subnet_ids = [aws_subnet.dataA.id, aws_subnet.dataB.id]
  tags = {
    Name           = "subnet_group_wpRedis"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}
