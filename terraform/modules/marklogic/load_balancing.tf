resource "aws_lb" "ml_lb" {
  name = "marklogic-lb-${var.environment}"
  internal = true
  # load_balancer_type = "network"
  subnets = var.private_subnets[*].id
  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }
  security_groups = [aws_security_group.ml_lb.id]
}

resource "aws_lb_target_group" "ml" {
  count = length(local.lb_ports)

  name     = "ml-target-${var.environment}-${count.index}"
  port     = local.lb_ports[count.index]
  protocol = "HTTP"
  vpc_id   = var.vpc.id
  deregistration_delay = 60
  health_check {
    interval = 10 #seconds
    port = 7997
    unhealthy_threshold = 5
    healthy_threshold = 5
  }
  stickiness {
    enabled = true
    type = "lb_cookie"
    cookie_duration = 3600
  }
}

resource "aws_lb_listener" "ml" {
  count = length(aws_lb_target_group.ml)

  load_balancer_arn = aws_lb.ml_lb.arn
  port              = aws_lb_target_group.ml[count.index].port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml[count.index].arn
  }
}
