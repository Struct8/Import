resource "aws_elastic_beanstalk_application" "beanstalk-wordpress" {
  name = "beanstalk-wordpress"
  tags = {
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_elastic_beanstalk_application_version" "beanstalk-uptime-kuma_version" {
  name        = "beanstalk-uptime-kuma-${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app/${f}")}"])), 0, 16)}"
  application = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  bucket      = aws_s3_bucket.beanstalk-wordpress-versions.id
  key         = aws_s3_object.beanstalk-uptime-kuma_bundle.key
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elastic_beanstalk_application_version" "beanstalk-wordpress-web_version" {
  name        = "beanstalk-wordpress-web-${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app/${f}")}"])), 0, 16)}"
  application = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  bucket      = aws_s3_bucket.beanstalk-wordpress-versions.id
  key         = aws_s3_object.beanstalk-wordpress-web_bundle.key
  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "eb_struct8-templates_beanstalk-uptime-kuma" {
  output_path = "${path.module}/eb_struct8-templates_beanstalk-uptime-kuma_${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app/${f}")}"])), 0, 16)}.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/kuma/app"
  type        = "zip"
}

resource "aws_elastic_beanstalk_environment" "beanstalk-uptime-kuma" {
  name                   = "beanstalk-uptime-kuma"
  solution_stack_name    = "64bit Amazon Linux 2023 v4.14.0 running Docker"
  application            = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  version_label          = aws_elastic_beanstalk_application_version.beanstalk-uptime-kuma_version.name
  wait_for_ready_timeout = "20m"
  setting {
    name      = "MatcherHTTPCode"
    namespace = "aws:elasticbeanstalk:environment:process:default"
    value     = "200-399"
  }
  setting {
    name      = "NAME"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-uptime-kuma"
  }
  setting {
    name      = "REGION"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_region.current.region}"
  }
  setting {
    name      = "ACCOUNT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_caller_identity.current.account_id}"
  }
  setting {
    name      = "AWS_ELASTIC_BEANSTALK_APPLICATION_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-wordpress"
  }
  setting {
    name      = "AWS_DB_INSTANCE_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.identifier}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENGINE_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.engine}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENDPOINT_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.endpoint}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_DB_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.db_name}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_SECRET_ARN_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_USER_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}:username::"
  }
  setting {
    name      = "AWS_EFS_FILE_SYSTEM_ID_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_efs_file_system.wp-eb-files.id}"
  }
  setting {
    name      = "AWS_ECR_REPOSITORY_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "kuma-image"
  }
  setting {
    name      = "AWS_ECR_REPOSITORY_URL_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_ecr_repository.kuma-image.repository_url}"
  }
  setting {
    name      = "AWS_EFS_ACCESS_POINT_ID_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_efs_access_point.ap_beanstalk-uptime-kuma_wp-eb-files.id}"
  }
  setting {
    name      = "VPCId"
    namespace = "aws:ec2:vpc"
    value     = aws_vpc.vpc-beanstalk-wordpress.id
  }
  setting {
    name      = "Subnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.wp-app-a.id},${aws_subnet.wp-app-b.id}"
  }
  setting {
    name      = "EnvironmentType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "LoadBalanced"
  }
  setting {
    name      = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "application"
  }
  setting {
    name      = "LoadBalancerIsShared"
    namespace = "aws:elasticbeanstalk:environment"
    value     = true
  }
  setting {
    name      = "SharedLoadBalancer"
    namespace = "aws:elbv2:loadbalancer"
    value     = aws_lb.wp-shared-alb.arn
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:elbv2:loadbalancer"
    value     = join(",", aws_lb.wp-shared-alb.security_groups)
  }
  setting {
    name      = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value     = "t4g.small"
  }
  setting {
    name      = "SupportedArchitectures"
    namespace = "aws:ec2:instances"
    value     = "arm64"
  }
  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = "1"
  }
  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = "1"
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_security_group.elastic_beanstalk_environment_beanstalk-uptime-kuma_group.id
  }
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_iam_instance_profile.beanstalk-uptime-kuma_profile.name
  }
  tags = {
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_lb_listener.wp-shared-http, terraform_data.seed_kuma-image]
}

data "archive_file" "eb_struct8-templates_beanstalk-wordpress-web" {
  output_path = "${path.module}/eb_struct8-templates_beanstalk-wordpress-web_${substr(sha1(join(",", [for f in sort(fileset("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app", "**")) : "${f}:${filesha1("${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app/${f}")}"])), 0, 16)}.zip"
  source_dir  = "${path.module}/.external_modules/struct8-templates/templates/beanstalk-wordpress/v3/wordpress/app"
  type        = "zip"
}

resource "aws_elastic_beanstalk_environment" "beanstalk-wordpress-web" {
  name                   = "beanstalk-wordpress-web"
  solution_stack_name    = "64bit Amazon Linux 2023 v4.14.0 running Docker"
  application            = aws_elastic_beanstalk_application.beanstalk-wordpress.name
  version_label          = aws_elastic_beanstalk_application_version.beanstalk-wordpress-web_version.name
  wait_for_ready_timeout = "20m"
  setting {
    name      = "NAME"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-wordpress-web"
  }
  setting {
    name      = "REGION"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_region.current.region}"
  }
  setting {
    name      = "ACCOUNT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${data.aws_caller_identity.current.account_id}"
  }
  setting {
    name      = "AWS_ELASTIC_BEANSTALK_APPLICATION_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "beanstalk-wordpress"
  }
  setting {
    name      = "AWS_DB_INSTANCE_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.identifier}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENGINE_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.engine}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_ENDPOINT_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.endpoint}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_DB_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_db_instance.wp-eb-db.db_name}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_SECRET_ARN_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}"
  }
  setting {
    name      = "AWS_DB_INSTANCE_USER_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${one(aws_db_instance.wp-eb-db.master_user_secret[*].secret_arn)}:username::"
  }
  setting {
    name      = "AWS_SSM_PARAMETER_NAME_ADMIN"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "ebWpAdminPassword"
  }
  setting {
    name      = "AWS_EFS_FILE_SYSTEM_ID_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_efs_file_system.wp-eb-files.id}"
  }
  setting {
    name      = "AWS_ECR_REPOSITORY_NAME_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "wp-image"
  }
  setting {
    name      = "AWS_ECR_REPOSITORY_URL_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_ecr_repository.wp-image.repository_url}"
  }
  setting {
    name      = "AWS_EFS_ACCESS_POINT_ID_0"
    namespace = "aws:elasticbeanstalk:application:environment"
    value     = "${aws_efs_access_point.ap_beanstalk-wordpress-web_wp-eb-files.id}"
  }
  setting {
    name      = "VPCId"
    namespace = "aws:ec2:vpc"
    value     = aws_vpc.vpc-beanstalk-wordpress.id
  }
  setting {
    name      = "Subnets"
    namespace = "aws:ec2:vpc"
    value     = "${aws_subnet.wp-app-a.id},${aws_subnet.wp-app-b.id}"
  }
  setting {
    name      = "EnvironmentType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "LoadBalanced"
  }
  setting {
    name      = "LoadBalancerType"
    namespace = "aws:elasticbeanstalk:environment"
    value     = "application"
  }
  setting {
    name      = "LoadBalancerIsShared"
    namespace = "aws:elasticbeanstalk:environment"
    value     = true
  }
  setting {
    name      = "SharedLoadBalancer"
    namespace = "aws:elbv2:loadbalancer"
    value     = aws_lb.wp-shared-alb.arn
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:elbv2:loadbalancer"
    value     = join(",", aws_lb.wp-shared-alb.security_groups)
  }
  setting {
    name      = "InstanceTypes"
    namespace = "aws:ec2:instances"
    value     = "t4g.small"
  }
  setting {
    name      = "SupportedArchitectures"
    namespace = "aws:ec2:instances"
    value     = "arm64"
  }
  setting {
    name      = "MinSize"
    namespace = "aws:autoscaling:asg"
    value     = "2"
  }
  setting {
    name      = "MaxSize"
    namespace = "aws:autoscaling:asg"
    value     = "4"
  }
  setting {
    name      = "SecurityGroups"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_security_group.elastic_beanstalk_environment_beanstalk-wordpress-web_group.id
  }
  setting {
    name      = "IamInstanceProfile"
    namespace = "aws:autoscaling:launchconfiguration"
    value     = aws_iam_instance_profile.beanstalk-wordpress-web_profile.name
  }
  tags = {
    State          = "beanstalk-wordpress"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_lb_listener.wp-shared-http, terraform_data.seed_wp-image]
}
