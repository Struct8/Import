resource "aws_ecs_cluster" "backup-lab-cluster" {
  name = "backup-lab-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name           = "backup-lab-cluster"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

locals {
  container_def_efs-writer_efs-writer_1 = {
    name      = "efs-writer"
    image     = "public.ecr.aws/aws-cli/aws-cli:latest"
    essential = true
    cpu       = 256
    memory    = 512
    environment = [
      {
        name  = "NAME"
        value = "efs-writer"
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
        name  = "AWS_EFS_FILE_SYSTEM_ID_0"
        value = tostring(aws_efs_file_system.lab-data.id)
      },
      {
        name  = "AWS_DYNAMODB_TABLE_NAME_0"
        value = "lab-orders"
      }
    ]
    mountPoints = [
      {
        sourceVolume  = "lab-data"
        containerPath = "/mnt/efs"
        readOnly      = false
      }
    ]
    systemControls         = []
    volumesFrom            = []
    command                = ["set -e; T=$AWS_DYNAMODB_TABLE_NAME_0; test -n \"$T\" || { echo \"AWS_DYNAMODB_TABLE_NAME_0 is not set\"; exit 1; }; D=/mnt/efs/writer; mkdir -p $D; TS=$(date -u +%Y%m%dT%H%M%SZ); echo \"efs-writer run at $TS\" > $D/$TS.txt; echo $TS >> /mnt/efs/runs.log; N=$(ls $D | wc -l); echo \"files in $D: $N\"; CUST=$(echo alice bruno carla diego | cut -d' ' -f$((RANDOM % 4 + 1))); AMT=$(printf '%d.%02d' $((RANDOM % 900 + 10)) $((RANDOM % 100))); aws dynamodb put-item --table-name \"$T\" --item \"{\\\"order_id\\\":{\\\"S\\\":\\\"run-$TS\\\"},\\\"customer\\\":{\\\"S\\\":\\\"$CUST\\\"},\\\"amount\\\":{\\\"N\\\":\\\"$AMT\\\"},\\\"created_at\\\":{\\\"S\\\":\\\"$TS\\\"},\\\"efs_files\\\":{\\\"N\\\":\\\"$N\\\"}}\"; echo \"item run-$TS written to $T: $CUST $AMT\"; echo \"items in $T: $(aws dynamodb scan --table-name \"$T\" --select COUNT --query Count --output text)\"; echo \"root of the file system:\"; ls -la /mnt/efs"]
    entryPoint             = ["/bin/bash", "-c"]
    privileged             = false
    readonlyRootFilesystem = false
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.logs-efs-writer.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "efs-writer"
      }
    }
  }
}

resource "aws_ecs_task_definition" "efs-writer" {
  container_definitions    = jsonencode([local.container_def_efs-writer_efs-writer_1])
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.execution_role_ecs_efs-writer.arn
  family                   = "efs-writer"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.task_role_ecs_efs-writer.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
  tags = {
    Name           = "efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
  volume {
    name = "lab-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.lab-data.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.ap_efs-writer_lab-data.id
        iam             = "ENABLED"
      }
    }
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_definition_efs-writer_st_aws-backup-lab_attach, aws_iam_role_policy_attachment.ecs_task_definition_efs-writer_execution_st_aws-backup-lab_attach]
}
