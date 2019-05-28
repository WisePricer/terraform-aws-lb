//
// Module specific Variables
//
variable "env" {
  description = "Environment (ex: `dev`, `qa`, `stage`, `prod`). (Second or top level namespace. Depending on namespacing options)"
  type        = "string"
  default     = "prod"
}

variable "name" {
  description = "Default name for the load balancer"
  default     = "load-balancer"
}

variable "enabled" {
  description = "Set to false to prevent the module from creating anything"
  default     = true
}

variable "certificate_additional_names" {
  description = "List of additional names of SSL Certificates to look up in ACM and use"
  type        = "list"
  default     = []
}

variable "certificate_name" {
  description = "The name of the default SSL Certificate to look up in ACM and use"
  default     = ""
}

//
// Load Balancer settings
//
variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing on NLB"
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection. Prevent LB from being deleted"
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 on ALB"
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  default     = "60"
}

variable "internal" {
  description = "Boolean determining if the LB is internal or externally facing."
  default     = true
}

variable "security_groups" {
  description = "The security groups with which we associate the LB. e.g. [\"sg-edcd9784\",\"sg-edcd9785\"]"
  type        = "list"
  default     = []
}

variable "subnets" {
  description = "A list of subnets to associate with the LB. e.g. ['subnet-1a2b3c4d','subnet-1a2b3c4e','subnet-1a2b3c4f']"
  type        = "list"
}

variable "type" {
  description = "Type of load balancer. (`application` or `network`)"
  default     = "application"
}

//
// Listener and Target Group settings
//
variable "lb_protocols" {
  description = "The protocols the LB accepts. e.g.: [\"HTTP\"]"
  type        = "list"
  default     = ["HTTP"]
}

variable "backend_port" {
  description = "The port the service on the EC2 instances listen on."
  default     = 80
}

variable "backend_protocol" {
  description = "The protocol the backend service speaks. Options: HTTP, HTTPS, TCP, SSL (secure tcp)."
  default     = "HTTP"
}

variable "ports" {
  description = "Default port set. Used fo all instance and LB port sets that are not defined"
  default     = "80"
}

variable "instance_http_ports" {
  description = "Backend HTTP instance (target group) ports"
  default     = ""
}

variable "instance_https_ports" {
  description = "Backend HTTPS instance (target group) ports"
  default     = ""
}

variable "instance_tcp_ports" {
  description = "Backend TCP instance (target group) ports"
  default     = ""
}

variable "lb_http_ports" {
  description = "Frontend HTTP listener ports"
  default     = ""
}

variable "lb_https_ports" {
  description = "Frontend HTTPS listener ports"
  default     = ""
}

variable "lb_tcp_ports" {
  description = "Frontend TCP listener ports"
  default     = ""
}

///
/// Health Checks
///
variable "health_check_healthy_threshold" {
  description = "Number of consecutive positive health checks before a backend instance is considered healthy."
  default     = 3
}

variable "health_check_interval" {
  description = "Interval in seconds on which the health check against backend hosts is tried."
  default     = 10
}

variable "health_check_matcher" {
  description = "The HTTP codes that are a success when checking TG health."
  default     = "200-299"

  # AWS default is 200-399
}

variable "health_check_path" {
  description = "The URL the ELB should use for health checks. e.g. /health"
  default     = "/"
}

variable "health_check_port" {
  description = "The port used by the health check if different from the traffic-port."
  default     = "traffic-port"
}

variable "health_check_protocol" {
  description = "The protocol used by the health check."
  default     = "HTTP"
}

variable "health_check_timeout" {
  description = "Seconds to leave a health check waiting before terminating it and calling the check unhealthy."
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive positive health checks before a backend instance is considered unhealthy."
  default     = 3
}

//
// Misc
//
variable "cookie_duration" {
  description = "If load balancer connection stickiness is desired, set this to the duration in seconds that cookie should be valid (e.g. 300). Otherwise, if no stickiness is desired, leave the default."
  default     = 0
}

variable "security_policy" {
  description = "The security policy if using HTTPS externally on the LB. See: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html"
  default     = "ELBSecurityPolicy-2016-08"
}

variable "vpc_id" {
  description = "VPC id where the LB and other resources will be deployed."
}
