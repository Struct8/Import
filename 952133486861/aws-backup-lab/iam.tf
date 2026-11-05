data "aws_iam_policy_document" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowWriteLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.logs-efs-writer.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab" {
  name        = "ecs_task_definition_efs-writer_execution_st_aws-backup-lab"
  description = "Access Policy for efs-writer (Role: execution)"
  policy      = data.aws_iam_policy_document.ecs_task_definition_efs-writer_execution_st_aws-backup-lab_doc.json
}

data "aws_iam_policy_document" "ecs_task_definition_efs-writer_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowPutAndCountItems"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:Scan"]
    resources = [aws_dynamodb_table.lab-orders.arn, "${aws_dynamodb_table.lab-orders.arn}/*"]
  }
  statement {
    sid       = "AllowEFSBasicAccess"
    effect    = "Allow"
    actions   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientRootAccess", "elasticfilesystem:ClientWrite"]
    resources = ["${aws_efs_file_system.lab-data.arn}:*"]
  }
}

resource "aws_iam_policy" "ecs_task_definition_efs-writer_st_aws-backup-lab" {
  name        = "ecs_task_definition_efs-writer_st_aws-backup-lab"
  description = "Access Policy for efs-writer"
  policy      = data.aws_iam_policy_document.ecs_task_definition_efs-writer_st_aws-backup-lab_doc.json
}

data "aws_iam_policy_document" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_doc" {
  statement {
    sid       = "AllowSchedulerToRunTask"
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = ["${aws_ecs_task_definition.efs-writer.arn_without_revision}:*"]
  }
  statement {
    sid       = "AllowSchedulerToPassTaskRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_ecs_task_definition.efs-writer.execution_role_arn, aws_ecs_task_definition.efs-writer.task_role_arn]
  }
  statement {
    sid       = "AllowSchedulerToTagTask"
    effect    = "Allow"
    actions   = ["ecs:TagResource"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      values   = ["RunTask"]
      variable = "ecs:CreateAction"
    }
  }
}

resource "aws_iam_policy" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab" {
  name        = "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab"
  description = "Access Policy for efs-writer-every-5-min"
  policy      = data.aws_iam_policy_document.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_doc.json
}

resource "aws_iam_role" "efs-writer-every-5-min_role" {
  name = "efs-writer-every-5-min_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "scheduler.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "efs-writer-every-5-min_role"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "execution_role_ecs_efs-writer" {
  name = "execution_role_ecs_efs-writer"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "execution_role_ecs_efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "role_backup_backup-lab-hourly" {
  name = "role_backup_backup-lab-hourly"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "backup.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "role_backup_backup-lab-hourly"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "task_role_ecs_efs-writer" {
  name = "task_role_ecs_efs-writer"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "task_role_ecs_efs-writer"
    State          = "aws-backup-lab"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_efs-writer_execution_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_efs-writer_execution_st_aws-backup-lab.arn
  role       = aws_iam_role.execution_role_ecs_efs-writer.name
}

resource "aws_iam_role_policy_attachment" "ecs_task_definition_efs-writer_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.ecs_task_definition_efs-writer_st_aws-backup-lab.arn
  role       = aws_iam_role.task_role_ecs_efs-writer.name
}

resource "aws_iam_role_policy_attachment" "role_backup_backup-lab-hourly_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.role_backup_backup-lab-hourly.name
}

resource "aws_iam_role_policy_attachment" "role_backup_backup-lab-hourly_restores" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.role_backup_backup-lab-hourly.name
}

resource "aws_iam_role_policy_attachment" "role_backup_backup-lab-hourly_s3_backup" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.role_backup_backup-lab-hourly.name
}

resource "aws_iam_role_policy_attachment" "role_backup_backup-lab-hourly_s3_restore" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.role_backup_backup-lab-hourly.name
}

resource "aws_iam_role_policy_attachment" "scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab_attach" {
  policy_arn = aws_iam_policy.scheduler_schedule_efs-writer-every-5-min_st_aws-backup-lab.arn
  role       = aws_iam_role.efs-writer-every-5-min_role.name
}
