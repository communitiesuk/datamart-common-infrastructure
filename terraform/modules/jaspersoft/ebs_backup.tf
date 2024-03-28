data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
  version = "2012-10-17"
}

#resource "aws_iam_role" "ebs_backup" {
#  name               = "aws-backup-service-role-${var.environment}"
#  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
#}

data "aws_iam_role" "existing_ebs_backup" {
  name = "aws-backup-service-role-${var.environment}"
}

data "aws_iam_policy" "service_backup" {
  name = "AWSBackupServiceRolePolicyForBackup"
}

data "aws_iam_policy" "service_restore" {
  name = "AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy_attachment" "service_backup" {
  policy_arn = data.aws_iam_policy.service_backup.arn
  role       = data.aws_iam_role.existing_ebs_backup.name
}

resource "aws_iam_role_policy_attachment" "service_restore" {
  policy_arn = data.aws_iam_policy.service_restore.arn
  role       = data.aws_iam_role.existing_ebs_backup.name
}

locals {
  ebs_backups = {
    schedule          = "cron(0 0 ? * SUN *)"
    start_window      = "00:00-01:00"
    completion_window = "01:00-02:00"
    retention_days    = 14
  }
}

resource "aws_backup_vault" "ebs" {
  name          = "jasper-reports-backup-vault-${var.environment}"
  force_destroy = true
}

resource "aws_backup_plan" "ebs" {
  name = "jasper-reports-backup-plan-${var.environment}"

  rule {
    rule_name         = "jasper-reports-backup-rule-${var.environment}"
    target_vault_name = aws_backup_vault.ebs.name
    schedule          = local.ebs_backups.schedule
    completion_window = 360

    lifecycle {
      delete_after = local.ebs_backups.retention_days
    }
  }
}

data "aws_ebs_volumes" "selected_volumes" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}jaspersoft-server"]
  }
}

resource "aws_backup_selection" "ebs" {
  iam_role_arn = data.aws_iam_role.existing_ebs_backup.arn
  name         = "jasper-reports-ebs-volumes-${var.environment}"
  plan_id      = aws_backup_plan.ebs.id
  resources    = [for volume in data.aws_ebs_volumes.selected_volumes.ids : volume]
}

# SNS topic for errors with the backup. Non-sensitive.
# tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "ebs_backup_completed" {
  name = "jasper-reports-ebs-backup-errors-${var.environment}"
}

data "aws_iam_policy_document" "ebs_backup_sns" {
  statement {
    actions = ["sns:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    resources = [aws_sns_topic.ebs_backup_completed.arn]
  }
}

resource "aws_sns_topic_policy" "ebs_backup" {
  arn    = aws_sns_topic.ebs_backup_completed.arn
  policy = data.aws_iam_policy_document.ebs_backup_sns.json
}

resource "aws_backup_vault_notifications" "ebs_backup_completed" {
  backup_vault_name   = aws_backup_vault.ebs.name
  sns_topic_arn       = aws_sns_topic.ebs_backup_completed.arn
  backup_vault_events = ["BACKUP_JOB_COMPLETED"]
}

resource "aws_sns_topic_subscription" "ebs_backup_errors" {
  for_each = toset(var.ebs_backup_error_notification_emails)

  topic_arn = aws_sns_topic.ebs_backup_completed.arn
  protocol  = "email"
  endpoint  = each.value

  filter_policy = jsonencode({
    State = [{ "anything-but" : "COMPLETED" }]
  })
}
