resource "aws_cloudwatch_log_metric_filter" "taskserver_errorlog_all" {
  depends_on     = [module.marklogic_log_group.log_group_names]
  log_group_name = local.taskserver_error_log_group_name
  name           = "taskserver-errorlog-count-all-${var.environment}"
  pattern        = ""
  metric_transformation {
    name          = "taskserver-errorlog-count-all-transform-${var.environment}"
    namespace     = "${var.environment}/MarkLogic"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "taskserver_errorlog_warning" {
  depends_on     = [module.marklogic_log_group.log_group_names]
  log_group_name = local.taskserver_error_log_group_name
  name           = "taskserver-errorlog-count-warning-${var.environment}"
  pattern        = "\"Warning:\""
  metric_transformation {
    name          = "taskserver-errorlog-count-warning-transform-${var.environment}"
    namespace     = "${var.environment}/MarkLogic"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "taskserver_errorlog_error" {
  depends_on     = [module.marklogic_log_group.log_group_names]
  log_group_name = local.taskserver_error_log_group_name
  name           = "taskserver-errorlog-count-error-${var.environment}"
  pattern        = "\"Error:\""
  metric_transformation {
    name          = "taskserver-errorlog-count-error-transform-${var.environment}"
    namespace     = "${var.environment}/MarkLogic"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

locals {
  read_iops = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeReadOps", "VolumeId", "${volume.id}", { "id" : "readOps_${replace(volume.availability_zone, "-", "_")}", "stat" : "Sum", "visible" : false }]
  ]
  write_iops = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeWriteOps", "VolumeId", "${volume.id}", { "id" : "writeOps_${replace(volume.availability_zone, "-", "_")}", "stat" : "Sum", "visible" : false }]
  ]
  throughput = [for volume in aws_ebs_volume.marklogic_data_volumes :
    [{
      "expression" : "(readOps_${replace(volume.availability_zone, "-", "_")} + writeOps_${replace(volume.availability_zone, "-", "_")})/PERIOD(readOps_${replace(volume.availability_zone, "-", "_")})",
      "label" : "${volume.availability_zone}",
      "id" : "throughput_${replace(volume.availability_zone, "-", "_")}"
    }]
  ]
  read_iops_visible = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeReadOps", "VolumeId", "${volume.id}", { "id" : "readOps_${replace(volume.availability_zone, "-", "_")}", "stat" : "Sum" }]
  ]
  write_iops_visible = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeWriteOps", "VolumeId", "${volume.id}", { "id" : "writeOps_${replace(volume.availability_zone, "-", "_")}", "stat" : "Sum" }]
  ]
  queue_length = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeQueueLength", "VolumeId", "${volume.id}", { "region" : data.aws_region.current.name, "label" : "${volume.availability_zone}" }]
  ]
  idle_time = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeIdleTime", "VolumeId", "${volume.id}", { "region" : data.aws_region.current.name, "label" : "${volume.availability_zone}" }]
  ]
  read_time = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeTotalReadTime", "VolumeId", "${volume.id}", { "stat" : "Average", "region" : data.aws_region.current.name, "label" : "${volume.availability_zone}" }]
  ]
  write_time = [for volume in aws_ebs_volume.marklogic_data_volumes :
    ["AWS/EBS", "VolumeTotalWriteTime", "VolumeId", "${volume.id}", { "stat" : "Average", "region" : data.aws_region.current.name, "label" : "${volume.availability_zone}" }]
  ]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-marklogic"
  dashboard_body = jsonencode(
    {
      "widgets" : [
        {
          "height" : 3,
          "width" : 24,
          "y" : 0,
          "x" : 0,
          "type" : "alarm",
          "properties" : {
            "title" : "",
            "alarms" : [
              aws_cloudwatch_metric_alarm.cpu_utilisation_high.arn,
              aws_cloudwatch_metric_alarm.memory_utilisation_high.arn,
              aws_cloudwatch_metric_alarm.memory_utilisation_high_sustained.arn,
              aws_cloudwatch_metric_alarm.system_disk_utilisation_high.arn,
              aws_cloudwatch_metric_alarm.data_disk_utilisation_high.arn,
              aws_cloudwatch_metric_alarm.data_disk_utilisation_high_sustained.arn,
              aws_cloudwatch_metric_alarm.healthy_host_low.arn,
              aws_cloudwatch_metric_alarm.unhealthy_host_high.arn,
            ]
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 9,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "disk_used_percent", "path", "/var/opt/MarkLogic", { id : "m1", stat : "Minimum" }],
              ["...", { id : "m2" }],
              ["...", { id : "m3", stat : "Maximum" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "setPeriodToTimeRange" : false,
            "sparkline" : true,
            "trend" : true,
            "title" : "Data drive disk usage",
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 3,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "disk_used_percent", "path", "/", { id : "m1", stat : "Minimum" }],
              ["...", { id : "m2" }],
              ["...", { id : "m3", stat : "Maximum" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "setPeriodToTimeRange" : false,
            "sparkline" : true,
            "trend" : true,
            "title" : "System drive disk usage",
            "yAxis" : {
              "left" : {
                "max" : 100,
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 3,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [aws_cloudwatch_log_metric_filter.taskserver_errorlog_all.metric_transformation[0].namespace,
              aws_cloudwatch_log_metric_filter.taskserver_errorlog_all.metric_transformation[0].name]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "period" : 900,
            "stat" : "Sum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 9,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [aws_cloudwatch_log_metric_filter.taskserver_errorlog_error.metric_transformation[0].namespace,
              aws_cloudwatch_log_metric_filter.taskserver_errorlog_error.metric_transformation[0].name]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "period" : 900,
            "stat" : "Sum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 15,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              [aws_cloudwatch_log_metric_filter.taskserver_errorlog_warning.metric_transformation[0].namespace,
              aws_cloudwatch_log_metric_filter.taskserver_errorlog_warning.metric_transformation[0].name]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "period" : 900,
            "stat" : "Sum"
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 3,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "cpu_usage_active", { id : "m1", stat : "Minimum" }],
              ["...", { id : "m2" }],
              ["...", { id : "m3", stat : "Maximum" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "period" : 300,
            "stat" : "Average",
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 9,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "view" : "timeSeries",
            "stacked" : false,
            "metrics" : [
              ["${var.environment}/MarkLogic", "mem_used_percent", { id : "m1", stat : "Minimum" }],
              ["...", { id : "m2" }],
              ["...", { id : "m3", stat : "Maximum" }]
            ],
            "region" : data.aws_region.current.name,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 3,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "diskio_reads"],
              [".", "diskio_writes"]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "period" : 300,
            "stat" : "Sum",
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 9,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "diskio_write_bytes"],
              [".", "diskio_read_bytes"]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Sum",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 21,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "diskio_iops_in_progress"]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Maximum",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 15,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "diskio_io_time"],
              [".", "diskio_read_time"],
              [".", "diskio_write_time"]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Sum",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 15,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["${var.environment}/MarkLogic", "swap_used_percent", { id : "m1", stat : "Minimum" }],
              ["...", { id : "m2" }],
              ["...", { id : "m3", stat : "Maximum" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 21,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/NetworkELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.ml["8001"].arn_suffix, "LoadBalancer", aws_lb.ml_lb.arn_suffix],
              ["AWS/NetworkELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.ml["8001"].arn_suffix, "LoadBalancer", aws_lb.ml_lb.arn_suffix, { stat : "Maximum" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Minimum",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 15,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/S3", "BucketSizeBytes", "BucketName", module.daily_backup_bucket.bucket, "StorageType", "StandardStorage", { "color" : "#17becf" }],
              [{ "expression" : "weekly_standard+weekly_glacier", "label" : "Weekly backups", "color" : "#9467bd" }],
              ["AWS/S3", "BucketSizeBytes", "BucketName", module.weekly_backup_bucket.bucket, "StorageType", "StandardStorage", { "visible" : false, "id" : "weekly_standard" }],
              ["AWS/S3", "BucketSizeBytes", "BucketName", module.weekly_backup_bucket.bucket, "StorageType", "GlacierInstantRetrievalStorage", { "visible" : false, "id" : "weekly_glacier" }],
              ["AWS/S3", "BucketSizeBytes", "BucketName", var.backup_replication_bucket.name, "StorageType", "GlacierInstantRetrievalStorage", { "color" : "#c5b0d5" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 86400,
            "title" : "Backup size"
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 21,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : [
              ["AWS/S3", "OperationsPendingReplication", "SourceBucket", module.weekly_backup_bucket.bucket, "DestinationBucket", var.backup_replication_bucket.name, "RuleId", local.replication_rule_id, { "color" : "#17becf" }],
              [".", "OperationsFailedReplication", ".", ".", ".", ".", ".", ".", { "color" : "#d62728" }]
            ],
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "period" : 300,
            "title" : "Backup replication"
            "yAxis" : {
              "left" : {
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 5,
          "width" : 24,
          "y" : 27,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${local.taskserver_error_log_group_name}' | fields @timestamp, @message, @logStream, @log\n| filter @message like /Error/\n| sort @timestamp desc\n| limit 5",
            "region" : data.aws_region.current.name,
            "stacked" : false,
            "title" : "Recent Error log group entries: ${local.taskserver_error_log_group_name}",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 24,
          "y" : 32,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${local.taskserver_error_log_group_name}' | fields @timestamp, @message, @logStream, @log\n| filter @message like /Warning/\n| sort @timestamp desc\n| limit 5",
            "region" : data.aws_region.current.name,
            "stacked" : false,
            "title" : "Recent Warning log group entries: ${local.taskserver_error_log_group_name}",
            "view" : "table"
          }
        },
        {
          "height" : 5,
          "width" : 24,
          "y" : 37,
          "x" : 0,
          "type" : "log",
          "properties" : {
            "query" : "SOURCE '${local.taskserver_error_log_group_name}' | fields @timestamp, @message, @logStream, @log\n| sort @timestamp desc\n| limit 5",
            "region" : data.aws_region.current.name,
            "stacked" : false,
            "title" : "Recent log group entries: ${local.taskserver_error_log_group_name}",
            "view" : "table"
          }
        },
        {
          "height" : 24,
          "width" : 24,
          "y" : 42,
          "x" : 0,
          "type" : "explorer",
          "properties" : {
            "metrics" : [
              {
                "metricName" : "CPUUtilization",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              },
              {
                "metricName" : "NetworkIn",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              },
              {
                "metricName" : "NetworkOut",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              },
              {
                "metricName" : "NetworkPacketsIn",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              },
              {
                "metricName" : "NetworkPacketsOut",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              },
              {
                "metricName" : "StatusCheckFailed",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Sum"
              },
              {
                "metricName" : "Memory % Committed Bytes In Use",
                "resourceType" : "AWS::EC2::Instance",
                "stat" : "Average"
              }
            ],
            "aggregateBy" : {
              "key" : "",
              "func" : ""
            },
            "labels" : [
              {
                "key" : "marklogic:stack:name",
                "value" : local.stack_name
              }
            ],
            "widgetOptions" : {
              "legend" : {
                "position" : "bottom"
              },
              "view" : "timeSeries",
              "stacked" : false,
              "rowsPerPage" : 50,
              "widgetsPerRow" : 3
            },
            "period" : 300,
            "splitBy" : "",
            "region" : data.aws_region.current.name
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 48,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : concat(local.read_iops, local.write_iops, local.throughput),
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume throughput",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "IOPS",
                "showUnits" : false,
                "min" : 0
              }
            },
            "annotations" : {
              "horizontal" : [
                {
                  "label" : "IOPS limit",
                  "value" : var.data_volume.iops
                }
              ]
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 48,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : local.read_iops_visible,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume read IOPS",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Read ops/300s",
                "showUnits" : false,
                "min" : 0
              }
            },
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 48,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : local.write_iops_visible,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume write IOPS",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Write ops/300s",
                "showUnits" : false,
                "min" : 0
              }
            },
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 48,
          "x" : 18,
          "type" : "metric",
          "properties" : {
            "metrics" : local.idle_time,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume idle time",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Idle time",
                "min" : 0,
                "max" : 60
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 54,
          "x" : 0,
          "type" : "metric",
          "properties" : {
            "metrics" : local.queue_length,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume queue length",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Queue length",
                "showUnits" : false,
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 54,
          "x" : 6,
          "type" : "metric",
          "properties" : {
            "metrics" : local.read_time,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume read time",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Read time",
                "min" : 0
              }
            }
          }
        },
        {
          "height" : 6,
          "width" : 6,
          "y" : 54,
          "x" : 12,
          "type" : "metric",
          "properties" : {
            "metrics" : local.write_time,
            "view" : "timeSeries",
            "stacked" : false,
            "region" : data.aws_region.current.name,
            "stat" : "Average",
            "title" : "EBS volume write time",
            "period" : 300,
            "yAxis" : {
              "left" : {
                "label" : "Write time",
                "min" : 0
              }
            }
          }
        }
      ]
    }
  )
}
