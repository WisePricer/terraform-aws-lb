#
# Setup AWS LB (ALB/NLB)
#   and S3 for logging, retrieve SSL cert from ACM
#   ?? security groups, dns
#
# AWS provider 1.6 has bugs that prevent NLBs management. Issue #2708
# Currently supporting 1.5.0
#
# https://www.terraform.io/docs/providers/aws/r/lb.html
# https://www.terraform.io/docs/providers/aws/r/lb_listener.html
# https://www.terraform.io/docs/providers/aws/r/lb_listener_rule.html
# https://www.terraform.io/docs/providers/aws/r/lb_target_group.html
# https://www.terraform.io/docs/providers/aws/r/lb_target_group_attachment.html
# https://www.terraform.io/docs/providers/aws/d/acm_certificate.html
#

data "aws_acm_certificate" "this" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTPS")
    ? 1 : 0}"

  domain = "${var.certificate_name}"
}

data "aws_acm_certificate" "additional" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTPS")
    ? length(var.certificate_additional_names) : 0
  }"

  domain = "${var.certificate_additional_names[count.index]}"
}

module "enabled" {
  source  = "git::https://github.com/WiserSolutions/terraform-local-boolean.git"
  value   = "${var.enabled}"
}

resource "aws_lb" "application" {
  count              = "${module.enabled.value && var.type == "application" ? 1 : 0}"
  name               = "${var.name}"
  internal           = "${var.internal}"
  load_balancer_type = "${var.type}"

  enable_deletion_protection = "${var.enable_deletion_protection}"
  enable_http2               = "${var.enable_http2}"
  idle_timeout               = "${var.idle_timeout}"
  security_groups            = ["${var.security_groups}"]
  subnets                    = ["${var.subnets}"]
  tags 
  {
    Name = "${var.name}-lb-application"
  }
}

resource "aws_lb" "network" {
  count              = "${module.enabled.value && var.type == "network" ? 1 : 0}"
  name               = "${var.name}-lb-network"
  internal           = "${var.internal}"
  load_balancer_type = "${var.type}"

  enable_cross_zone_load_balancing = "${var.enable_cross_zone_load_balancing}"
  enable_deletion_protection       = "${var.enable_deletion_protection}"
  idle_timeout                     = "${var.idle_timeout}"
  subnets                          = ["${var.subnets}"]
  tags 
  {
    Name = "${var.name}-lb-network"
  }
}

locals {
  // Set default to any port set that has not been specified
  instance_http_ports  = "${length(compact(split(",", var.instance_http_ports))) > 0 ? var.instance_http_ports : var.ports}"
  instance_https_ports = "${length(compact(split(",", var.instance_https_ports))) > 0 ? var.instance_https_ports : var.ports}"
  instance_tcp_ports   = "${length(compact(split(",", var.instance_tcp_ports))) > 0 ? var.instance_tcp_ports : var.ports}"
  lb_http_ports        = "${length(compact(split(",", var.lb_http_ports))) > 0 ? var.lb_http_ports : var.ports}"
  lb_https_ports       = "${length(compact(split(",", var.lb_https_ports))) > 0 ? var.lb_https_ports : var.ports}"
  lb_tcp_ports         = "${length(compact(split(",", var.lb_tcp_ports))) > 0 ? var.lb_tcp_ports : var.ports}"
}

resource "aws_lb_target_group" "application-http" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTP")
    ? length(compact(split(",", local.instance_http_ports))) : 0}"

  name = "${var.name}"

  port     = "${element(compact(split(",",local.instance_http_ports)), count.index)}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    port                = "${var.health_check_port}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    timeout             = "${var.health_check_timeout}"
    protocol            = "${var.health_check_protocol}"
    matcher             = "${var.health_check_matcher}"
  }

  # ALB only. Cannot be defined for network LB
  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${var.cookie_duration > 0 ? var.cookie_duration : 1}"
    enabled         = "${var.cookie_duration > 0 ? true : false}"
  }
  tags 
  {
    Name = {"${var.name}-aws_lb_target_group_http_app"}
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "application-https" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTPS")
    ? length(compact(split(",", local.instance_https_ports))) : 0}"

  name = "${var.name}-aws_lb_target_group_https_app"

  port     = "${element(compact(split(",",local.instance_https_ports)), count.index)}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    interval            = "${var.health_check_interval}"
    path                = "${var.health_check_path}"
    port                = "${var.health_check_port}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    timeout             = "${var.health_check_timeout}"
    protocol            = "${var.health_check_protocol}"
    matcher             = "${var.health_check_matcher}"
  }

  # ALB only. Cannot be defined for network LB
  stickiness {
    type            = "lb_cookie"
    cookie_duration = "${var.cookie_duration > 0 ? var.cookie_duration : 1}"
    enabled         = "${var.cookie_duration > 0 ? true : false}"
  }

  tags 
  {
    Name = {"${var.name}-aws_lb_target_group_https_app"}
  } 

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "network" {
  count = "${
    module.enabled.value &&
    var.type == "network"
    ? length(compact(split(",", local.instance_tcp_ports))) : 0}"

  name = "${var.name}-aws_lb_target_group_network"

  health_check = "${list(local.healthcheck)}"
  port         = "${element(compact(split(",",local.instance_tcp_ports)), count.index)}"
  protocol     = "TCP"
  stickiness   = []
  tags 
  {
    Name = "${var.name}-aws_lb_target_group_network"
  } 
  vpc_id       = "${var.vpc_id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTP")
    ? length(compact(split(",", local.lb_http_ports))) : 0}"

  load_balancer_arn = "${element(concat(aws_lb.application.*.arn, aws_lb.network.*.arn, list("")), 0)}"
  port              = "${element(compact(split(",",local.lb_http_ports)), count.index)}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${element(concat(aws_lb_target_group.application-http.*.arn), count.index)}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "https" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTPS")
    ? length(compact(split(",", local.lb_https_ports))) : 0}"

  load_balancer_arn = "${element(concat(aws_lb.application.*.arn, aws_lb.network.*.arn, list("")), 0)}"
  port              = "${element(compact(split(",",local.lb_https_ports)), count.index)}"
  protocol          = "HTTPS"
  certificate_arn   = "${element(concat(data.aws_acm_certificate.this.*.arn, list("")), 0)}"
  ssl_policy        = "${var.security_policy}"

  default_action {
    target_group_arn = "${element(concat(aws_lb_target_group.application-https.*.arn), count.index)}"
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https" {
  count = "${
    module.enabled.value &&
    var.type == "application" &&
    contains(var.lb_protocols, "HTTPS")
    ? length(var.certificate_additional_names) : 0 }"

  listener_arn    = "${element(aws_lb_listener.https.*.arn, 0)}"
  certificate_arn = "${element(data.aws_acm_certificate.additional.*.arn, count.index)}"
}

resource "aws_lb_listener" "network" {
  count = "${
    module.enabled.value &&
    var.type == "network"
    ? length(compact(split(",", local.lb_tcp_ports))) : 0}"

  load_balancer_arn = "${element(concat(aws_lb.application.*.arn, aws_lb.network.*.arn, list("")), 0)}"
  port              = "${element(compact(split(",",local.lb_tcp_ports)), count.index)}"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${element(concat(aws_lb_target_group.network.*.arn), count.index)}"
    type             = "forward"
  }
}

# Build NLB Target Group health check stansa
locals {
  health_base = {
    interval            = "10"
    port                = "${var.health_check_port}"
    healthy_threshold   = "${var.health_check_healthy_threshold}"
    unhealthy_threshold = "${var.health_check_unhealthy_threshold}"
    protocol            = "${var.health_check_protocol}"
  }

  http = {
    path    = "${var.health_check_path}"
    matcher = "200-399"
    timeout = "6"
  }

  h_keys      = "${join(",", keys(local.health_base))}"
  h_vals      = "${join(",", values(local.health_base))}"
  http_keys   = "${join(",", keys(local.http))}"
  http_vals   = "${join(",", values(local.http))}"
  keys        = "${ var.health_check_protocol == "TCP" ? local.h_keys : "${local.h_keys},${local.http_keys}" }"
  vals        = "${ var.health_check_protocol == "TCP" ? local.h_vals : "${local.h_vals},${local.http_vals}" }"
  healthcheck = "${zipmap(split(",", local.keys), split(",", local.vals))}"
}

