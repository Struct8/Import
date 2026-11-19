resource "aws_ecs_capacity_provider" "wp-capacity" {
  name = "wp-capacity"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asgWordpress.arn
    managed_draining               = "ENABLED"
    managed_termination_protection = "DISABLED"
    managed_scaling {
      instance_warmup_period    = 300
      maximum_scaling_step_size = 10000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
  tags = {
    Name           = "wp-capacity"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster" "wp-cluster" {
  name = "wp-cluster"
  tags = {
    Name           = "wp-cluster"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_ecs_cluster_capacity_providers" "assoc_cp_to_wp-cluster" {
  cluster_name       = aws_ecs_cluster.wp-cluster.name
  capacity_providers = [aws_ecs_capacity_provider.wp-capacity.name]
}

resource "aws_ecs_service" "wordpress_service" {
  name                              = "wordpress_service"
  cluster                           = aws_ecs_cluster.wp-cluster.id
  desired_count                     = 2
  enable_ecs_managed_tags           = true
  force_delete                      = true
  health_check_grace_period_seconds = 600
  propagate_tags                    = "TASK_DEFINITION"
  scheduling_strategy               = "REPLICA"
  task_definition                   = "${aws_ecs_task_definition.wordpress.family}:${aws_ecs_task_definition.wordpress.revision}"
  capacity_provider_strategy {
    base              = 0
    capacity_provider = aws_ecs_capacity_provider.wp-capacity.name
    weight            = 1
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    container_name   = "wordpress"
    container_port   = 443
    target_group_arn = aws_lb_target_group.tgWordpress.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.autoscaling_group_asgWordpress_group.id, aws_security_group.ecs_task_definition_wordpress_group.id]
    subnets          = [aws_subnet.appA.id, aws_subnet.appB.id]
  }
  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }
  tags = {
    Name           = "wordpress_service"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_lb_listener_rule.ruleFromCloudFront]
}

resource "aws_ecs_task_definition" "Struct8Probe_debug-wp_wordpress" {
  container_definitions    = jsonencode([{"name":"probe","image":"${local.container_def_wordpress_wordpress_1.image}","essential":true,"entryPoint":["/bin/sh","-c","echo \"struct8 probe: host=$1 port=$2\"\ngetent hosts \"$1\" || nslookup \"$1\" 2>/dev/null || echo \"no DNS answer\"\nping -c 3 -W 2 \"$1\" 2>/dev/null || echo \"no ICMP reply (filtered, or not permitted in this container; not conclusive)\"\nif command -v nc >/dev/null 2>&1; then\n  if nc -z -w 5 \"$1\" \"$2\" 2>/dev/null; then echo \"port $2 open\"; else echo \"port $2 closed or filtered\"; fi\nelif command -v bash >/dev/null 2>&1; then\n  if timeout 5 bash -c 'exec 3<>/dev/tcp/\"$1\"/\"$2\"' _ \"$1\" \"$2\" 2>/dev/null; then echo \"port $2 open\"; else echo \"port $2 closed or filtered\"; fi\nelse\n  echo \"port $2 not tested: this image has neither nc nor bash\"\nfi","probe"],"command":["localhost","80"],"logConfiguration":{"logDriver":"awslogs","options":{"awslogs-group":"${aws_cloudwatch_log_group.Struct8Probe_debug-wp_wordpress_logs.name}","awslogs-region":"${data.aws_region.current.region}","awslogs-stream-prefix":"probe"}}}])
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role_ecs_wordpress.arn
  family                   = "Struct8Probe-t1eAUxGPRo-vo6lIyc15I-wordpress"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
}

locals {
  container_def_wordpress_otel-collector = {
    name              = "otel-collector"
    image             = "public.ecr.aws/aws-observability/aws-otel-collector:v0.50.0"
    essential         = false
    memory            = 128
    memoryReservation = 64
    environment = [
      {
        name = "AOT_CONFIG_CONTENT"
        value = <<EOF
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:4318
processors:
  memory_limiter:
    check_interval: 1s
    limit_percentage: 80
    spike_limit_percentage: 25
  batch:
    timeout: 5s
exporters:
  awsxray:
service:
  pipelines:
    traces:
      receivers:
        - otlp
      processors:
        - memory_limiter
        - batch
      exporters:
        - awsxray
        EOF
      },
      {
        name  = "AWS_REGION"
        value = tostring(data.aws_region.current.region)
      },
      {
        name  = "NAME"
        value = "wordpress"
      },
      {
        name  = "REGION"
        value = tostring(data.aws_region.current.region)
      },
      {
        name  = "ACCOUNT"
        value = tostring(data.aws_caller_identity.current.account_id)
      },
      {
        name  = "AWS_ECS_CAPACITY_PROVIDER_NAME_0"
        value = "wp-capacity"
      },
      {
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = tostring(aws_efs_file_system.wpContent.id)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.primary_endpoint_address)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_READER_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.reader_endpoint_address)
      },
      {
        name  = "AWS_RDS_CLUSTER_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.cluster_identifier)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENGINE_0"
        value = tostring(aws_rds_cluster.wp-aurora.engine)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENDPOINT_0"
        value = tostring(aws_rds_cluster.wp-aurora.endpoint)
      },
      {
        name  = "AWS_RDS_CLUSTER_PORT_0"
        value = tostring(aws_rds_cluster.wp-aurora.port)
      },
      {
        name  = "AWS_RDS_CLUSTER_DB_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.database_name)
      },
      {
        name  = "AWS_RDS_CLUSTER_SECRET_ARN_0"
        value = tostring(one(aws_rds_cluster.wp-aurora.master_user_secret[*].secret_arn))
      },
      {
        name  = "AWS_RDS_CLUSTER_ARN_0"
        value = tostring(aws_rds_cluster.wp-aurora.arn)
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "wp-pro-media-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      },
      {
        name  = "AWS_SESV2_EMAIL_IDENTITY_NAME_0"
        value = "wpMail"
      },
      {
        name  = "AWS_S3_BUCKET_NAME_SETUP"
        value = "wp-pro-setup-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      },
      {
        name  = "AWS_XRAY_GROUP_NAME_0"
        value = "wordpressTraces"
      },
      {
        name  = "WP_SETUP_SCRIPT_BUCKET"
        value = tostring(aws_s3_object.wpSetupScript.bucket)
      },
      {
        name  = "WP_SETUP_SCRIPT_KEY"
        value = tostring(aws_s3_object.wpSetupScript.key)
      },
      {
        name  = "WP_SETUP_SCRIPT_ETAG"
        value = tostring(aws_s3_object.wpSetupScript.etag)
      }
    ]
    mountPoints            = []
    systemControls         = []
    volumesFrom            = []
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logsWordpress.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "otel-collector"
      }
    }
  }
  container_def_wordpress_wordpress_1 = {
    name              = "wordpress"
    image             = "public.ecr.aws/docker/library/wordpress:latest"
    essential         = true
    cpu               = 1024
    memory            = 768
    memoryReservation = 512
    stopTimeout       = 30
    portMappings = [
      {
        protocol      = "tcp"
        containerPort = 443
        hostPort      = 443
      }
    ]
    environment = [
      {
        name  = "WORDPRESS_DB_HOST"
        value = tostring(aws_rds_cluster.wp-aurora.endpoint)
      },
      {
        name  = "WORDPRESS_DB_NAME"
        value = tostring(aws_rds_cluster.wp-aurora.database_name)
      },
      {
        name  = "WORDPRESS_DB_USER"
        value = "wordpress"
      },
      {
        name  = "WORDPRESS_CONFIG_EXTRA"
        value = "define('WP_HOME', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); define('WP_SITEURL', 'https://wp.${data.aws_route53_zone.zoneWordpress.name}'); $_SERVER['HTTP_HOST'] = 'wp.${data.aws_route53_zone.zoneWordpress.name}'; define('FORCE_SSL_ADMIN', true); define('DISALLOW_FILE_EDIT', true); define('MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); define('WP_REDIS_HOST', '${aws_elasticache_replication_group.wpRedis.primary_endpoint_address}'); define('WP_REDIS_PORT', 6379); define('WP_REDIS_SCHEME', 'tls'); define('AS3CF_SETTINGS', serialize(array('provider' => 'aws', 'use-server-roles' => true, 'bucket' => '${aws_s3_bucket.wpMedia.bucket}', 'region' => '${data.aws_region.current.region}', 'copy-to-s3' => true, 'enable-object-prefix' => true, 'object-prefix' => 'wp-content/media/', 'use-yearmonth-folders' => true, 'object-versioning' => true, 'delivery-provider' => 'aws', 'serve-from-s3' => true, 'enable-delivery-domain' => true, 'delivery-domain' => 'wp.${data.aws_route53_zone.zoneWordpress.name}', 'force-https' => true, 'remove-local-file' => false))); define('WPOSES_AWS_USE_EC2_IAM_ROLE', true); define('WPOSES_SETTINGS', serialize(array('region' => '${data.aws_region.current.region}', 'send-via-ses' => true, 'completed-setup' => true, 'enable-open-tracking' => false, 'enable-click-tracking' => false, 'enable-health-report' => false, 'log-duration' => 30)));"
      },
      {
        name  = "WP_DB_BOOTSTRAP"
        value = "<?php mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT); $q = chr(39); $b = chr(96); $user = getenv('WORDPRESS_DB_USER'); $m = null; for ($i = 1; $i <= 20 && $m === null; $i++) { try { $c = mysqli_init(); $c->real_connect(getenv('WORDPRESS_DB_HOST'), getenv('DB_ADMIN_USER'), getenv('DB_ADMIN_PASSWORD'), '', 3306, null, MYSQLI_CLIENT_SSL | MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT); $m = $c; } catch (mysqli_sql_exception $e) { fwrite(STDERR, 'db-bootstrap: attempt ' . $i . ': ' . $e->getMessage() . PHP_EOL); sleep(10); } } if ($m === null) { exit(1); } $account = $q . $m->real_escape_string($user) . $q . '@' . $q . '%' . $q; $password = $q . $m->real_escape_string(getenv('WORDPRESS_DB_PASSWORD')) . $q; $m->query('CREATE USER IF NOT EXISTS ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('ALTER USER ' . $account . ' IDENTIFIED BY ' . $password . ' REQUIRE SSL'); $m->query('GRANT ALL PRIVILEGES ON ' . $b . str_replace($b, $b . $b, getenv('WORDPRESS_DB_NAME')) . $b . '.* TO ' . $account); echo 'db-bootstrap: database user ' . $user . ' is ready' . PHP_EOL;"
      },
      {
        name  = "WP_AUTO_SETUP"
        value = "true"
      },
      {
        name  = "WP_DEMO_CONTENT"
        value = "true"
      },
      {
        name  = "WP_SITE_URL"
        value = "https://wp.${data.aws_route53_zone.zoneWordpress.name}"
      },
      {
        name  = "WP_SITE_TITLE"
        value = "My WordPress site"
      },
      {
        name  = "WP_ADMIN_USER"
        value = "wpadmin"
      },
      {
        name  = "WP_ADMIN_EMAIL"
        value = "admin@${data.aws_route53_zone.zoneWordpress.name}"
      },
      {
        name  = "WP_LOCALE"
        value = "en_US"
      },
      {
        name  = "WP_TIMEZONE"
        value = "UTC"
      },
      {
        name  = "WP_TRACING"
        value = "true"
      },
      {
        name  = "OTEL_SERVICE_NAME"
        value = "wordpress"
      },
      {
        name  = "WP_SHOP"
        value = "true"
      },
      {
        name  = "APACHE_MAX_WORKERS"
        value = "12"
      },
      {
        name  = "NAME"
        value = "wordpress"
      },
      {
        name  = "REGION"
        value = tostring(data.aws_region.current.region)
      },
      {
        name  = "ACCOUNT"
        value = tostring(data.aws_caller_identity.current.account_id)
      },
      {
        name  = "AWS_ECS_CAPACITY_PROVIDER_NAME_0"
        value = "wp-capacity"
      },
      {
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = tostring(aws_efs_file_system.wpContent.id)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.primary_endpoint_address)
      },
      {
        name  = "AWS_ELASTICACHE_REPLICATION_GROUP_READER_ENDPOINT_0"
        value = tostring(aws_elasticache_replication_group.wpRedis.reader_endpoint_address)
      },
      {
        name  = "AWS_RDS_CLUSTER_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.cluster_identifier)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENGINE_0"
        value = tostring(aws_rds_cluster.wp-aurora.engine)
      },
      {
        name  = "AWS_RDS_CLUSTER_ENDPOINT_0"
        value = tostring(aws_rds_cluster.wp-aurora.endpoint)
      },
      {
        name  = "AWS_RDS_CLUSTER_PORT_0"
        value = tostring(aws_rds_cluster.wp-aurora.port)
      },
      {
        name  = "AWS_RDS_CLUSTER_DB_NAME_0"
        value = tostring(aws_rds_cluster.wp-aurora.database_name)
      },
      {
        name  = "AWS_RDS_CLUSTER_SECRET_ARN_0"
        value = tostring(one(aws_rds_cluster.wp-aurora.master_user_secret[*].secret_arn))
      },
      {
        name  = "AWS_RDS_CLUSTER_ARN_0"
        value = tostring(aws_rds_cluster.wp-aurora.arn)
      },
      {
        name  = "AWS_S3_BUCKET_NAME_0"
        value = "wp-pro-media-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      },
      {
        name  = "AWS_SESV2_EMAIL_IDENTITY_NAME_0"
        value = "wpMail"
      },
      {
        name  = "AWS_S3_BUCKET_NAME_SETUP"
        value = "wp-pro-setup-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
      },
      {
        name  = "AWS_XRAY_GROUP_NAME_0"
        value = "wordpressTraces"
      },
      {
        name  = "WP_SETUP_SCRIPT_BUCKET"
        value = tostring(aws_s3_object.wpSetupScript.bucket)
      },
      {
        name  = "WP_SETUP_SCRIPT_KEY"
        value = tostring(aws_s3_object.wpSetupScript.key)
      },
      {
        name  = "WP_SETUP_SCRIPT_ETAG"
        value = tostring(aws_s3_object.wpSetupScript.etag)
      }
    ]
    secrets = [
      {
        name      = "WORDPRESS_DB_PASSWORD"
        valueFrom = data.aws_secretsmanager_secret.wpSecrets.arn
      },
      {
        name      = "DB_ADMIN_USER"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:username::"
      },
      {
        name      = "DB_ADMIN_PASSWORD"
        valueFrom = "${aws_rds_cluster.wp-aurora.master_user_secret[0].secret_arn}:password::"
      },
      {
        name      = "WP_ADMIN_PASSWORD"
        valueFrom = data.aws_ssm_parameter.wpAdminPassword.arn
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "wpContent"
        containerPath = "/var/www/html/wp-content/uploads"
        readOnly      = false
      }
    ]
    systemControls         = []
    volumesFrom            = []
    command                = ["sh", "-c", "set -e; mkdir -p /etc/ssl/private; openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj /CN=wordpress -addext basicConstraints=critical,CA:FALSE -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem; a2enmod ssl; a2ensite default-ssl; printenv WP_DB_BOOTSTRAP > /tmp/db-bootstrap.php; php /tmp/db-bootstrap.php; rm -f /tmp/db-bootstrap.php; c=''; j() { echo \"$c\" | grep -o \"$1\"'\":\"[^\"]*' | cut -d'\"' -f3; }; n=0; until c=$(curl -fsS \"http://169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI\") && curl -fsS --retry 2 --aws-sigv4 \"aws:amz:$REGION:s3\" --user \"$(j AccessKeyId):$(j SecretAccessKey)\" -H \"x-amz-security-token: $(j Token)\" -o /tmp/wp-auto-setup.sh \"https://$WP_SETUP_SCRIPT_BUCKET.s3.$REGION.amazonaws.com/$WP_SETUP_SCRIPT_KEY\" && [ \"$(md5sum < /tmp/wp-auto-setup.sh | cut -d' ' -f1)\" = \"$WP_SETUP_SCRIPT_ETAG\" ]; do n=$((n+1)); [ \"$n\" -lt 6 ] || { echo 'setup script: download failed'; exit 1; }; sleep 5; done; bash /tmp/wp-auto-setup.sh; rm -f /tmp/wp-auto-setup.sh; unset WP_DB_BOOTSTRAP WP_ADMIN_PASSWORD DB_ADMIN_USER DB_ADMIN_PASSWORD; exec docker-entrypoint.sh apache2-foreground"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logsWordpress.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "wordpress"
      }
    }
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  container_definitions    = jsonencode([local.container_def_wordpress_otel-collector, local.container_def_wordpress_wordpress_1])
  cpu                      = "1024"
  execution_role_arn       = aws_iam_role.execution_role_ecs_wordpress.arn
  family                   = "wordpress"
  memory                   = "768"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  task_role_arn            = aws_iam_role.task_role_ecs_wordpress.arn
  tags = {
    Name           = "wordpress"
    State          = "wordpress-professional"
    Struct8Creator = "Contato Struct"
  }
  volume {
    name = "wpContent"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wpContent.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.ap_wordpress_wpContent.id
        iam             = "ENABLED"
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_wordpress_st_wordpress-professional_attach, aws_iam_role_policy_attachment.ecs_task_definition_wordpress_execution_st_wordpress-professional_attach]
}
