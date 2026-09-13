terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/Import/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

resource "aws_iam_instance_profile" "k6-load-generator_profile" {
  name = "k6-load-generator_profile"
  path = "/"
  role = aws_iam_role.k6-load-generator_role.name
  tags = {
    Name           = "k6-load-generator_profile"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "nat-a_profile" {
  name = "nat-a_profile"
  path = "/"
  role = aws_iam_role.nat-a_role.name
  tags = {
    Name           = "nat-a_profile"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "k6-load-generator_role" {
  name                  = "k6-load-generator_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "k6-load-generator_role"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-a_role" {
  name                  = "nat-a_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "nat-a_role"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "loadtest-asg-simple" {
  cidr_block           = "10.60.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "loadtest-asg-simple"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                              = aws_vpc.loadtest-asg-simple.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.60.11.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                              = aws_vpc.loadtest-asg-simple.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.60.0.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-b"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                              = aws_vpc.loadtest-asg-simple.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.60.1.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                              = aws_vpc.loadtest-asg-simple.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.60.2.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-b"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-k6" {
  vpc_id                              = aws_vpc.loadtest-asg-simple.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.60.3.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-k6"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "igw-k6" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "igw-k6"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_rt-private1_to_nat-a_ipv4" {
  network_interface_id   = aws_instance.nat-a.primary_network_interface_id
  route_table_id         = aws_route_table.rt-private1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_rt-public1_to_igw-k6_ipv4" {
  gateway_id             = aws_internet_gateway.igw-k6.id
  route_table_id         = aws_route_table.rt-public1.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "rt-private1" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "rt-private1"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "rt-public1" {
  vpc_id = aws_vpc.loadtest-asg-simple.id
  tags = {
    Name           = "rt-public1"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_a_rt_private1" {
  route_table_id = aws_route_table.rt-private1.id
  subnet_id      = aws_subnet.private-a.id
}

resource "aws_route_table_association" "aws_route_table_association_private_b_rt_private1" {
  route_table_id = aws_route_table.rt-private1.id
  subnet_id      = aws_subnet.private-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_a_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-a.id
}

resource "aws_route_table_association" "aws_route_table_association_public_b_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-b.id
}

resource "aws_route_table_association" "aws_route_table_association_public_k6_rt_public1" {
  route_table_id = aws_route_table.rt-public1.id
  subnet_id      = aws_subnet.public-k6.id
}

resource "aws_security_group" "autoscaling_group_hub-asg_group" {
  name        = "autoscaling_group_hub-asg_group"
  vpc_id      = aws_vpc.loadtest-asg-simple.id
  description = "Managed by Terraform"
  lifecycle {
    ignore_changes = [revoke_rules_on_delete]
  }
  tags = {
    Name           = "autoscaling_group_hub-asg_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_k6-load-generator_group" {
  name        = "instance_k6-load-generator_group"
  vpc_id      = aws_vpc.loadtest-asg-simple.id
  description = "Managed by Terraform"
  lifecycle {
    ignore_changes = [revoke_rules_on_delete]
  }
  tags = {
    Name           = "instance_k6-load-generator_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-a_group" {
  name        = "instance_nat-a_group"
  vpc_id      = aws_vpc.loadtest-asg-simple.id
  description = "Managed by Terraform"
  lifecycle {
    ignore_changes = [revoke_rules_on_delete]
  }
  tags = {
    Name           = "instance_nat-a_group"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_hub_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_hub-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_hub_asg_group_ingress_tcp_8080" {
  security_group_id = aws_security_group.autoscaling_group_hub-asg_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "Hub HTTP from k6 generator (direct, ALB disabled during minimal test)"
  from_port         = 8080
  protocol          = "tcp"
  to_port           = 8080
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_autoscaling_group_hub_asg_group_ingress_tcp_8080" {
  security_group_id        = aws_security_group.autoscaling_group_hub-asg_group.id
  source_security_group_id = "sg-056ed8737d5a3efdd"
  description              = "Hub HTTP from the ALB target group"
  from_port                = 8080
  protocol                 = "tcp"
  to_port                  = 8080
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_k6-load-generator_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_k6-load-generator_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "k6 web dashboard, forwarded from the NAT instance"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_k6_load_generator_group_ingress_tcp_5665" {
  security_group_id        = aws_security_group.instance_k6-load-generator_group.id
  source_security_group_id = "sg-056ed8737d5a3efdd"
  description              = "k6 web dashboard from the ALB"
  from_port                = 5665
  protocol                 = "tcp"
  to_port                  = 5665
  type                     = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["10.60.0.0/16"]
  description       = "NAT: all traffic from the VPC to be routed out"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_instance_nat_a_group_ingress_tcp_5665" {
  security_group_id = aws_security_group.instance_nat-a_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "k6 web dashboard from the internet"
  from_port         = 5665
  protocol          = "tcp"
  to_port           = 5665
  type              = "ingress"
}

resource "aws_lb" "alb-hub" {
  name                             = "alb-hub"
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60
  load_balancer_type               = "application"
  subnets                          = [aws_subnet.public-a.id, aws_subnet.public-b.id]
  tags = {
    Name           = "alb-hub"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-dashboard" {
  load_balancer_arn                    = aws_lb.alb-hub.arn
  port                                 = 5665
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-k6-dashboard.arn
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg-k6-dashboard.arn
        weight = 1
      }
    }
  }
  tags = {
    Name           = "listener-dashboard"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "listener-http" {
  load_balancer_arn                    = aws_lb.alb-hub.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.tg-hub.arn
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg-hub.arn
        weight = 1
      }
    }
  }
  tags = {
    Name           = "listener-http"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "tg-hub" {
  name                              = "tg-hub"
  vpc_id                            = aws_vpc.loadtest-asg-simple.id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 8080
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  target_type                       = "instance"
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
  tags = {
    Name           = "tg-hub"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
  target_group_health {
    dns_failover {
      minimum_healthy_targets_count      = "1"
      minimum_healthy_targets_percentage = "off"
    }
    unhealthy_state_routing {
      minimum_healthy_targets_count      = 1
      minimum_healthy_targets_percentage = "off"
    }
  }
}

resource "aws_lb_target_group" "tg-k6-dashboard" {
  name                              = "tg-k6-dashboard"
  vpc_id                            = aws_vpc.loadtest-asg-simple.id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 5665
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  target_type                       = "ip"
  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  stickiness {
    cookie_duration = 86400
    enabled         = false
    type            = "lb_cookie"
  }
  tags = {
    Name           = "tg-k6-dashboard"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
  target_group_health {
    dns_failover {
      minimum_healthy_targets_count      = "1"
      minimum_healthy_targets_percentage = "off"
    }
    unhealthy_state_routing {
      minimum_healthy_targets_count      = 1
      minimum_healthy_targets_percentage = "off"
    }
  }
}




### CATEGORY: COMPUTE ###

resource "aws_instance" "k6-load-generator" {
  subnet_id                   = aws_subnet.public-k6.id
  ami                         = "ami-0467666181e60a1ee"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6-load-generator_profile.name
  instance_type               = "t4g.nano"
  private_ip                  = "10.60.3.159"
  vpc_security_group_ids      = [aws_security_group.instance_k6-load-generator_group.id]
  cpu_options {
    core_count       = 2
    threads_per_core = 1
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
  enclave_options {
    enabled = false
  }
  lifecycle {
    ignore_changes = [user_data, user_data_replace_on_change]
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    encrypted   = false
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name           = "k6-load-generator"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_instance" "nat-a" {
  subnet_id                   = aws_subnet.public-a.id
  ami                         = "ami-0469a6bed63b8634c"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-a_profile.name
  instance_type               = "t3.nano"
  private_ip                  = "10.60.1.151"
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.instance_nat-a_group.id]
  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
  enclave_options {
    enabled = false
  }
  lifecycle {
    ignore_changes = [user_data, user_data_replace_on_change]
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Name           = "nat-a"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_launch_template" "hub-lt" {
  image_id        = "ami-0467666181e60a1ee"
  name            = "hub-lt"
  default_version = 1
  description     = "ASG launch template. user_data hub-docker.sh installs Docker, clones struct8-hub, builds the arm64 image and runs the Hub with the load-test endpoint enabled. arm64 AMI for t4g. The boot build takes about 5 min, which is why the ASG grace period is high."
  instance_type   = "t4g.nano"
  user_data = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
HUB_LOADTEST="on"
HUB_PORT="8080"
BOOT_GEN="3"
NAME="hub-asg"
REGION="us-west-2"
ACCOUNT="952133486861"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

#!/bin/bash
# Struct8 Hub on Docker - generic EC2 bootstrap for Amazon Linux 2023.
#
# Reusable across templates: any EC2 or Auto Scaling group that should run the
# Struct8 Hub container points its user_data at a COPY of this script (the
# struct8-templates repo forbids sharing a folder between templates, so each
# template keeps its own copy).
#
# What it does, on boot:
#   1. installs Docker,
#   2. gets the Hub source (git clone of Struct8/struct8-hub) and builds the
#      container image from image/ -- the image is not published to any
#      registry, and building from source keeps this independent of one,
#   3. runs the container, restarting it on reboot.
#
# The image is "one file, no dependencies" (image/index.mjs + Dockerfile), so
# the build is small and fast.
#
# Everything tunable is a NODE ENVIRONMENT VARIABLE, so the same script serves
# every template without an edit. The generator writes them to
# /etc/profile.d/struct8_vars.sh as `export KEY = "value"` (spaces + quotes),
# which is NOT valid shell to source, so we parse the value out instead.
#
#   HUB_PORT       port the container listens on and is published on. Default 8080.
#   HUB_LOADTEST   'on' enables the load-test endpoint (POST /loadtest?ms=N).
#                  Default unset (off). Only set it where load testing is the point.
#   HUB_REF        git ref (branch/tag/commit) of struct8-hub to build. Default 'main'.
#   HUB_POLL       optional: name a wired queue to consume (see the Hub docs).
#
# The Hub itself discovers its neighbours from the environment variables the
# generator injects from the diagram's wires; nothing about the topology is set
# here.
set -uo pipefail
LOGFILE="/var/log/user-data.log"
exec >"$LOGFILE" 2>&1
set -x

VARS=/etc/profile.d/struct8_vars.sh
getvar() { [ -f "$VARS" ] && awk -F= -v k="$1" '$0 ~ ("^[[:space:]]*export[[:space:]]+" k "[[:space:]]*=") {gsub(/[ "]/,"",$2); print $2; exit}' "$VARS"; }

HUB_PORT="$(getvar HUB_PORT)";       HUB_PORT="$${HUB_PORT:-8080}"
HUB_LOADTEST="$(getvar HUB_LOADTEST)"
HUB_REF="$(getvar HUB_REF)";         HUB_REF="$${HUB_REF:-main}"
HUB_POLL="$(getvar HUB_POLL)"
echo "HUB_PORT=$HUB_PORT HUB_LOADTEST=$${HUB_LOADTEST:-<off>} HUB_REF=$HUB_REF HUB_POLL=$${HUB_POLL:-<none>}"

echo "Updating the system..."
dnf update -y

echo "Installing Docker and git..."
dnf install -y docker git
systemctl enable docker
systemctl start docker

echo "Fetching the Hub source ($HUB_REF)..."
rm -rf /opt/struct8-hub
git clone --depth 1 --branch "$HUB_REF" https://github.com/Struct8/struct8-hub /opt/struct8-hub \
  || git clone --depth 1 https://github.com/Struct8/struct8-hub /opt/struct8-hub

echo "Building the Hub image..."
docker build -t struct8-hub:local /opt/struct8-hub/image

# The Hub reads the wires from its OWN environment. The generator wrote them to
# /etc/struct8_env; pass that whole file into the container so discovery works,
# then add the runtime knobs on top.
ENV_ARGS=()
[ -f /etc/struct8_env ] && ENV_ARGS+=(--env-file /etc/struct8_env)
ENV_ARGS+=(-e "PORT=$${HUB_PORT}")
[ -n "$${HUB_LOADTEST:-}" ] && ENV_ARGS+=(-e "HUB_LOADTEST=$${HUB_LOADTEST}")
[ -n "$${HUB_POLL:-}" ]     && ENV_ARGS+=(-e "HUB_POLL=$${HUB_POLL}")

echo "Running the Hub container on port $${HUB_PORT}..."
docker rm -f struct8-hub 2>/dev/null || true
docker run -d \
  --name struct8-hub \
  --restart unless-stopped \
  -p "$${HUB_PORT}:$${HUB_PORT}" \
  "$${ENV_ARGS[@]}" \
  struct8-hub:local

echo "Done. Hub is starting on port $${HUB_PORT}. GET / is health; POST / fans out."
[ -n "$${HUB_LOADTEST:-}" ] && echo "Load-test endpoint enabled: POST /loadtest?ms=N"

EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_hub-asg_group.id]
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
      volume_size           = 8
      volume_type           = "gp3"
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "hub-asg"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "hub-lt"
    State          = "loadtest-asg-simple"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "hub-asg" {
  name                      = "hub-asg"
  default_instance_warmup   = 420
  desired_capacity          = 1
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  health_check_grace_period = 600
  health_check_type         = "ELB"
  max_instance_lifetime     = 0
  max_size                  = 1
  min_size                  = 1
  target_group_arns         = [aws_lb_target_group.tg-hub.arn]
  vpc_zone_identifier       = [aws_subnet.private-a.id, aws_subnet.private-b.id]
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "default"
  }
  launch_template {
    version = "1"
    id      = aws_launch_template.hub-lt.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "hub-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "loadtest-asg-simple"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}


