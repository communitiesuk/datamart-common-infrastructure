variable "host_names" {
  description = "Target names"
  type        = list(string)
  default     = ["MarkLogic-ASG-1", "MarkLogic-ASG-2", "MarkLogic-ASG-3"]
}

resource "aws_ssm_maintenance_window_target" "ml_servers" {
  for_each      = toset(var.host_names)
  window_id     = var.patch_maintenance_window.window_id
  name          = "marklogic-${var.environment}"
  description   = "MarkLogic servers from the ${var.environment} environment"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:Name"
    values = [each.value]
  }
  targets {
    key    = "tag:marklogic:stack:name"
    values = [local.stack_name]
  }
}

# Yum update output, non-sensitive
# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ml_patch" {
  name              = "${local.app_log_group_base_name}-ssm-patch"
  retention_in_days = var.patch_cloudwatch_log_expiration_days
}

resource "aws_s3_object" "ml_check_forest_state_xquery_script" {
  bucket = module.config_files_bucket.bucket
  key    = "check_forest_state.xqy"
  source = "${path.module}/check_forest_state.xqy"
  etag   = filemd5("${path.module}/check_forest_state.xqy")
}

resource "aws_s3_object" "ml_check_forest_state_shell_script" {
  bucket = module.config_files_bucket.bucket
  key    = "check_forest_state.sh"
  source = "${path.module}/check_forest_state.sh"
  etag   = filemd5("${path.module}/check_forest_state.sh")
}

resource "aws_s3_object" "ml_final_forest_state_script" {
  bucket = module.config_files_bucket.bucket
  key    = "final_forest_state.xqy"
  source = "${path.module}/final_forest_state.xqy"
  etag   = filemd5("${path.module}/final_forest_state.xqy")
}

resource "aws_ssm_maintenance_window_task" "ml_patch" {
  count           = length(var.host_names)
  name            = "marklogic-patch-${var.environment}"
  window_id       = var.patch_maintenance_window.window_id
  max_concurrency = 1
  max_errors      = 0
  priority        = count.index
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  cutoff_behavior = "CONTINUE_TASK"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.ml_servers[var.host_names[count.index]].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment         = "Yum update security"
      timeout_seconds = 1800

      service_role_arn = var.patch_maintenance_window.service_role_arn
      notification_config {
        notification_arn    = var.patch_maintenance_window.errors_sns_topic_arn
        notification_events = ["TimedOut", "Cancelled", "Failed"]
        notification_type   = "Command"
      }

      parameter {
        name = "commands"
        values = [
          templatefile("${path.module}/patch.sh",
            {
              ENVIRONMENT             = var.environment,
              MARKLOGIC_CONFIG_BUCKET = module.config_files_bucket.bucket,
              AWS_REGION              = data.aws_region.current.name
          })
        ]
      }

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.ml_patch.name
        cloudwatch_output_enabled = true
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "ml_restart" {
  count           = length(var.host_names)
  name            = "marklogic-restart-${var.environment}"
  window_id       = var.patch_maintenance_window.window_id
  max_concurrency = 1
  max_errors      = 0
  priority        = length(var.host_names) + count.index
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  cutoff_behavior = "CONTINUE_TASK"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.ml_servers[var.host_names[count.index]].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment         = "Restart marklogic"
      timeout_seconds = 1800

      service_role_arn = var.patch_maintenance_window.service_role_arn
      notification_config {
        notification_arn    = var.patch_maintenance_window.errors_sns_topic_arn
        notification_events = ["TimedOut", "Cancelled", "Failed"]
        notification_type   = "Command"
      }

      parameter {
        name = "commands"
        values = [
          templatefile("${path.module}/restart_server.sh",
            {
              ENVIRONMENT             = var.environment,
              MARKLOGIC_CONFIG_BUCKET = module.config_files_bucket.bucket,
              AWS_REGION              = data.aws_region.current.name
        })]
      }

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.ml_patch.name
        cloudwatch_output_enabled = true
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "ml_final_forest_check" {
  name            = "marklogic-restart-${var.environment}"
  window_id       = var.patch_maintenance_window.window_id
  max_concurrency = 1
  max_errors      = 0
  priority        = 2 * length(var.host_names) # Must run after ml_patch and ml_restart have completed
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  cutoff_behavior = "CONTINUE_TASK"

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.ml_servers["MarkLogic-ASG-1"].id]
  }

  task_invocation_parameters {
    run_command_parameters {
      comment         = "Final forest state check"
      timeout_seconds = 1800

      service_role_arn = var.patch_maintenance_window.service_role_arn
      notification_config {
        notification_arn    = var.patch_maintenance_window.errors_sns_topic_arn
        notification_events = ["TimedOut", "Cancelled", "Failed"]
        notification_type   = "Command"
      }

      parameter {
        name = "commands"
        values = [
          templatefile("${path.module}/final_forest_state.sh",
            {
              ENVIRONMENT             = var.environment,
              MARKLOGIC_CONFIG_BUCKET = module.config_files_bucket.bucket,
              AWS_REGION              = data.aws_region.current.name
        })]
      }

      cloudwatch_config {
        cloudwatch_log_group_name = aws_cloudwatch_log_group.ml_patch.name
        cloudwatch_output_enabled = true
      }
    }
  }
}
