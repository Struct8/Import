terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State3/main.tfstate"
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

resource "aws_iam_instance_profile" "nat-instance_profile" {
  name = "nat-instance_profile"
  path = "/"
  role = aws_iam_role.nat-instance_role.name
  tags = {
    Name           = "nat-instance_profile"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_instance_profile" "web-server-asg_profile" {
  name = "web-server-asg_profile"
  path = "/"
  role = aws_iam_role.web-server-asg_role.name
  tags = {
    Name           = "web-server-asg_profile"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "nat-instance_role" {
  name                  = "nat-instance_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "nat-instance_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "web-server-asg_role" {
  name                  = "web-server-asg_role"
  assume_role_policy    = "{\"Statement\":[{\"Action\":\"sts:AssumeRole\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"}}],\"Version\":\"2012-10-17\"}"
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "web-server-asg_role"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: NETWORK ###

resource "aws_vpc" "alb-web-servers" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"
  tags = {
    Name           = "alb-web-servers"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-a" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.3.1.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-subnet-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-b" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.3.3.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-subnet-b"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "private-subnet-c" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.3.5.0/24"
  map_public_ip_on_launch             = false
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "private-subnet-c"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-a" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2a"
  cidr_block                          = "10.3.0.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-subnet-a"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-bx" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2b"
  cidr_block                          = "10.3.2.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-subnet-bx"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_subnet" "public-subnet-c" {
  vpc_id                              = aws_vpc.alb-web-servers.id
  availability_zone                   = "us-west-2c"
  cidr_block                          = "10.3.4.0/24"
  map_public_ip_on_launch             = true
  private_dns_hostname_type_on_launch = "ip-name"
  tags = {
    Name           = "public-subnet-c"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "internet-gateway"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route" "route_private-route-table_to_nat-instance_ipv4" {
  network_interface_id   = aws_instance.nat-instance.primary_network_interface_id
  route_table_id         = aws_route_table.private-route-table.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "route_public-route-table_to_internet-gateway_ipv4" {
  gateway_id             = aws_internet_gateway.internet-gateway.id
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "private-route-table"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.alb-web-servers.id
  tags = {
    Name           = "public-route-table"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_a_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-a.id
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_b_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-b.id
}

resource "aws_route_table_association" "aws_route_table_association_private_subnet_c_private_route_table" {
  route_table_id = aws_route_table.private-route-table.id
  subnet_id      = aws_subnet.private-subnet-c.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_a_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-a.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_bx_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-bx.id
}

resource "aws_route_table_association" "aws_route_table_association_public_subnet_c_public_route_table" {
  route_table_id = aws_route_table.public-route-table.id
  subnet_id      = aws_subnet.public-subnet-c.id
}

resource "aws_security_group" "autoscaling_group_web-server-asg_group" {
  name        = "autoscaling_group_web-server-asg_group"
  vpc_id      = aws_vpc.alb-web-servers.id
  description = "Managed by Terraform"
  tags = {
    Name           = "autoscaling_group_web-server-asg_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "instance_nat-instance_group" {
  name        = "instance_nat-instance_group"
  vpc_id      = aws_vpc.alb-web-servers.id
  description = "Managed by Terraform"
  tags = {
    Name           = "instance_nat-instance_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group" "lb_application-load-balancer_group" {
  name        = "lb_application-load-balancer_group"
  vpc_id      = aws_vpc.alb-web-servers.id
  description = "Managed by Terraform"
  tags = {
    Name           = "lb_application-load-balancer_group"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_security_group_rule" "rule_autoscaling_group_web_server_asg_group_egress_all_protocols" {
  security_group_id = aws_security_group.autoscaling_group_web-server-asg_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_instance_group_egress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_instance_nat_instance_group_ingress_all_protocols" {
  security_group_id = aws_security_group.instance_nat-instance_group.id
  cidr_blocks       = ["10.3.0.0/16"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_egress_all_protocols" {
  security_group_id = aws_security_group.lb_application-load-balancer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_ingress_all_protocols" {
  security_group_id = aws_security_group.lb_application-load-balancer_group.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  type              = "ingress"
}

resource "aws_security_group_rule" "rule_lb_application_load_balancer_group_to_autoscaling_group_web_server_asg_group_tcp_80" {
  security_group_id        = aws_security_group.autoscaling_group_web-server-asg_group.id
  source_security_group_id = aws_security_group.lb_application-load-balancer_group.id
  description              = "Allow from lb_application-load-balancer_group (tcp:80-80)"
  from_port                = 80
  protocol                 = "tcp"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_lb" "application-load-balancer" {
  name                             = "application-load-balancer"
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.lb_application-load-balancer_group.id]
  subnets                          = [aws_subnet.public-subnet-a.id, aws_subnet.public-subnet-bx.id, aws_subnet.public-subnet-c.id]
  tags = {
    Name           = "application-load-balancer"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_listener" "http-listener" {
  load_balancer_arn                    = aws_lb.application-load-balancer.arn
  port                                 = 80
  protocol                             = "HTTP"
  routing_http_response_server_enabled = true
  default_action {
    order            = 1
    target_group_arn = aws_lb_target_group.web-target-group.arn
    type             = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.web-target-group.arn
        weight = 1
      }
    }
  }
  tags = {
    Name           = "http-listener"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lb_target_group" "web-target-group" {
  name                              = "web-target-group"
  vpc_id                            = aws_vpc.alb-web-servers.id
  deregistration_delay              = "300"
  ip_address_type                   = "ipv4"
  load_balancing_algorithm_type     = "round_robin"
  load_balancing_anomaly_mitigation = "off"
  load_balancing_cross_zone_enabled = "use_load_balancer_configuration"
  port                              = 80
  protocol                          = "HTTP"
  protocol_version                  = "HTTP1"
  slow_start                        = 0
  target_type                       = "instance"
  health_check {
    enabled             = true
    healthy_threshold   = 3
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
    Name           = "web-target-group"
    State          = "State3"
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

resource "aws_instance" "nat-instance" {
  subnet_id                   = aws_subnet.public-subnet-a.id
  ami                         = "ami-0467666181e60a1ee"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.nat-instance_profile.name
  instance_type               = "t4g.nano"
  private_ip                  = "10.3.0.215"
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.instance_nat-instance_group.id]
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
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
    }
  }
  lifecycle {
    ignore_changes = [user_data]
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
    Name           = "nat-instance"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

data "aws_ami" "AMI_Data_Source_web-server-launch-template" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_launch_template" "web-server-launch-template" {
  image_id        = data.aws_ami.AMI_Data_Source_web-server-launch-template.id
  name            = "web-server-launch-template"
  default_version = 1
  description     = "Web server launch template: Graviton t4g.nano Spot, AL2023 arm64, IMDSv2 required. user_data installs Apache (with swap to avoid OOM) and serves a live IMDSv2 instance-info page at /."
  instance_type   = "t4g.nano"
  user_data = base64encode(<<-EOFUData
#!/bin/bash


# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
NAME    = "web-server-asg"
REGION  = "us-west-2"
ACCOUNT = "952133486861"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

#!/bin/bash
# Instance Info web page for Amazon Linux 2023 (x86_64 or arm64/Graviton).
#
# Serves a styled HTML page that reports the EC2 instance's own metadata, read
# LIVE from the Instance Metadata Service v2 (IMDSv2, token-required) on every
# request. Placed behind a load balancer, refreshing the page shows a different
# instance each time -- id, AZ, subnet, private IP, instance type, disks, etc.
#
# The site ROOT ("/") returns the page directly with HTTP 200 (no redirect), so
# the load balancer health check can target "/" with the default 200 matcher.
#
# Reusable across templates: it takes no arguments and hard-codes nothing about
# the environment. Point an EC2/Launch Template user_data field at this file.
#
# Notes:
#   - Small instances (t3.nano / t4g.nano, 512 MB) OOM-kill `dnf install`, so we
#     add a little swap FIRST. This is the same guard the NAT bootstrap uses; the
#     web page failing to install Apache was exactly this OOM.
#
# Listens on port 80.
LOGFILE="/var/log/user-data.log"
exec >"$LOGFILE" 2>&1
set -x

# A little swap so dnf does not get OOM-killed on a 512 MB instance.
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=512 2>/dev/null
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
fi

echo "Installing Apache (httpd)..."
dnf install -y httpd

# The page is generated per request by a CGI script so a browser refresh always
# shows fresh metadata (and, behind a load balancer, a different instance).
cat > /var/www/cgi-bin/info << 'CGI_EOF'
#!/bin/bash
# Reads this instance's metadata via IMDSv2 and prints an HTML page.

# --- IMDSv2: get a session token first (this is what makes it "v2 secure") ---
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

# Helper: read one metadata path with the token; prints empty string if absent.
meta() {
  curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    "http://169.254.169.254/latest/meta-data/$1"
}

INSTANCE_ID=$(meta instance-id)
INSTANCE_TYPE=$(meta instance-type)
AMI_ID=$(meta ami-id)
HOSTNAME_LOCAL=$(meta local-hostname)
PRIVATE_IP=$(meta local-ipv4)
PUBLIC_IP=$(meta public-ipv4)
AZ=$(meta placement/availability-zone)
AZ_ID=$(meta placement/availability-zone-id)
REGION=$(meta placement/region)
MAC=$(meta network/interfaces/macs/ | head -n1 | tr -d '/')
VPC_ID=$(meta "network/interfaces/macs/$MAC/vpc-id")
SUBNET_ID=$(meta "network/interfaces/macs/$MAC/subnet-id")
SECURITY_GROUPS=$(meta security-groups | tr '\n' ' ')
ARCH=$(uname -m)
KERNEL=$(uname -r)
UPTIME=$(uptime -p)

# Disks and memory come from the OS, not from IMDS.
DISKS=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT --noheadings 2>/dev/null | sed 's/^/    /')
ROOT_DISK=$(df -h / | awk 'NR==2 {print $2" total, "$3" used, "$4" free ("$5")"}')
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
CPU_COUNT=$(nproc)
NOW=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# CGI header, then the HTML body.
echo "Content-type: text/html"
echo ""

cat << HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>EC2 Instance Info</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: radial-gradient(1200px 600px at 20% -10%, #1e3a5f 0%, #0b1220 55%, #070b14 100%);
      color: #e6edf3; display: flex; align-items: center; justify-content: center; padding: 32px;
    }
    .card {
      width: 100%; max-width: 880px; background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.08); border-radius: 18px; padding: 32px 36px;
      box-shadow: 0 20px 60px rgba(0,0,0,0.45); backdrop-filter: blur(6px);
    }
    .head { display: flex; align-items: center; gap: 16px; margin-bottom: 4px; }
    .dot { width: 12px; height: 12px; border-radius: 50%; background: #3fb950; box-shadow: 0 0 12px #3fb950; }
    h1 { font-size: 22px; margin: 0; font-weight: 650; letter-spacing: .2px; }
    .sub { color: #8b98a5; font-size: 13px; margin: 2px 0 24px 28px; }
    .hero { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 26px; }
    .chip {
      background: linear-gradient(135deg, #2563eb, #1d4ed8); color: #fff;
      padding: 8px 14px; border-radius: 999px; font-size: 13px; font-weight: 600;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    }
    .chip.alt { background: linear-gradient(135deg, #7c3aed, #6d28d9); }
    .chip.az  { background: linear-gradient(135deg, #0891b2, #0e7490); }
    .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px 28px; }
    .row { display: flex; flex-direction: column; gap: 3px; padding: 12px 14px;
      background: rgba(255,255,255,0.03); border-radius: 12px; border: 1px solid rgba(255,255,255,0.06); }
    .k { font-size: 11px; text-transform: uppercase; letter-spacing: .6px; color: #8b98a5; }
    .v { font-size: 15px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; word-break: break-all; }
    .full { grid-column: 1 / -1; }
    pre { margin: 0; font-size: 13px; line-height: 1.5; white-space: pre-wrap; color: #c9d5e0; }
    .foot { margin-top: 24px; display: flex; justify-content: space-between; align-items: center;
      color: #6b7684; font-size: 12px; flex-wrap: wrap; gap: 8px; }
    .refresh { color: #58a6ff; text-decoration: none; font-weight: 600; }
    .refresh:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="card">
    <div class="head"><span class="dot"></span><h1>EC2 Instance Info</h1></div>
    <div class="sub">Live metadata read via IMDSv2 &middot; refresh to hit another instance behind the load balancer</div>

    <div class="hero">
      <span class="chip">$INSTANCE_ID</span>
      <span class="chip alt">$INSTANCE_TYPE</span>
      <span class="chip az">$AZ</span>
    </div>

    <div class="grid">
      <div class="row"><span class="k">Availability Zone</span><span class="v">$${AZ:-n/a}</span></div>
      <div class="row"><span class="k">AZ ID</span><span class="v">$${AZ_ID:-n/a}</span></div>
      <div class="row"><span class="k">Region</span><span class="v">$${REGION:-n/a}</span></div>
      <div class="row"><span class="k">Instance Type</span><span class="v">$${INSTANCE_TYPE:-n/a}</span></div>
      <div class="row"><span class="k">Private IPv4</span><span class="v">$${PRIVATE_IP:-n/a}</span></div>
      <div class="row"><span class="k">Public IPv4</span><span class="v">$${PUBLIC_IP:-none (private subnet)}</span></div>
      <div class="row"><span class="k">VPC</span><span class="v">$${VPC_ID:-n/a}</span></div>
      <div class="row"><span class="k">Subnet</span><span class="v">$${SUBNET_ID:-n/a}</span></div>
      <div class="row"><span class="k">Local Hostname</span><span class="v">$${HOSTNAME_LOCAL:-n/a}</span></div>
      <div class="row"><span class="k">MAC</span><span class="v">$${MAC:-n/a}</span></div>
      <div class="row"><span class="k">AMI</span><span class="v">$${AMI_ID:-n/a}</span></div>
      <div class="row"><span class="k">Architecture</span><span class="v">$ARCH</span></div>
      <div class="row"><span class="k">vCPUs</span><span class="v">$CPU_COUNT</span></div>
      <div class="row"><span class="k">Memory</span><span class="v">$MEM_USED / $MEM_TOTAL</span></div>
      <div class="row"><span class="k">Root Disk</span><span class="v">$ROOT_DISK</span></div>
      <div class="row"><span class="k">Kernel</span><span class="v">$KERNEL</span></div>
      <div class="row full"><span class="k">Security Groups</span><span class="v">$${SECURITY_GROUPS:-n/a}</span></div>
      <div class="row full"><span class="k">Block Devices</span><pre>$DISKS</pre></div>
    </div>

    <div class="foot">
      <span>Uptime: $UPTIME</span>
      <a class="refresh" href="/">&#8635; Refresh</a>
      <span>Rendered $NOW</span>
    </div>
  </div>
</body>
</html>
HTML
CGI_EOF

chmod +x /var/www/cgi-bin/info

# Serve the CGI at the site ROOT so "GET /" returns 200 directly (no redirect).
# ScriptAlias maps every request under / to the info script; the LB health check
# can then use the default path "/" with the default 200 matcher.
cat > /etc/httpd/conf.d/instance-info.conf << 'CONF_EOF'
# Run the info CGI for the site root and everything under it.
ScriptAlias / "/var/www/cgi-bin/info"
<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options +ExecCGI
    Require all granted
</Directory>
CONF_EOF

echo "Enabling and starting Apache..."
systemctl enable --now httpd

echo "Done. Instance info page is live on port 80 (served directly at /)."


EOFUData
)
  vpc_security_group_ids = [aws_security_group.autoscaling_group_web-server-asg_group.id]
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
  iam_instance_profile {
    name = aws_iam_instance_profile.web-server-asg_profile.name
  }
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
    }
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
    Name           = "web-server-asg"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
  }
  tags = {
    Name           = "web-server-launch-template"
    State          = "State3"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_autoscaling_group" "web-server-asg" {
  name                      = "web-server-asg"
  default_instance_warmup   = 0
  desired_capacity          = 3
  health_check_grace_period = 180
  health_check_type         = "ELB"
  max_instance_lifetime     = 0
  max_size                  = 3
  min_size                  = 3
  target_group_arns         = [aws_lb_target_group.web-target-group.arn]
  vpc_zone_identifier       = [aws_subnet.private-subnet-a.id, aws_subnet.private-subnet-b.id, aws_subnet.private-subnet-c.id]
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }
  capacity_reservation_specification {
    capacity_reservation_preference = "default"
  }
  launch_template {
    version = "1"
    id      = aws_launch_template.web-server-launch-template.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "web-server-asg"
  }
  tag {
    key                 = "State"
    propagate_at_launch = true
    value               = "State3"
  }
  tag {
    key                 = "Struct8Creator"
    propagate_at_launch = true
    value               = "Contato Struct"
  }
}


