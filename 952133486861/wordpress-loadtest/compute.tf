data "local_file" "UserData_k6Generator" {
  filename = "${path.module}/.external_modules/struct8-templates/templates/vpc-k6-load-generator/v3/user_data/k6-bootstrap.sh"
}

data "aws_ami" "AMI_Data_Source_k6Generator" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-arm64"]
  }
}

resource "aws_instance" "k6Generator" {
  subnet_id                   = aws_subnet.pubLoadTest.id
  ami                         = data.aws_ami.AMI_Data_Source_k6Generator.id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k6Generator_profile.name
  instance_type               = "t4g.small"
  user_data_base64 = base64encode(<<-EOFUData
#!/bin/bash

# --- BEGIN STRUCT8 VARIABLES ---
cat << 'EOFENV' > /etc/struct8_env
K6_SCENARIO="wordpress"
K6_PANEL="on"
NAME="k6Generator"
REGION="${data.aws_region.current.region}"
ACCOUNT="${data.aws_caller_identity.current.account_id}"
TARGET_URL="https://wp.cloudman.pro/"
EOFENV
cat /etc/struct8_env >> /etc/environment
sed 's/^/export /' /etc/struct8_env > /etc/profile.d/struct8_vars.sh
chmod +x /etc/profile.d/struct8_vars.sh
chmod 644 /etc/struct8_env
# --- END STRUCT8 VARIABLES ---

${data.local_file.UserData_k6Generator.content}
EOFUData
)
  user_data_replace_on_change = true
  vpc_security_group_ids      = [aws_security_group.instance_k6Generator_group.id]
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    encrypted   = true
    iops        = 3000
    throughput  = 125
    volume_size = 8
    volume_type = "gp3"
  }
  tags = {
    Struct8Debug   = "2zeRq_EaN5iT0PSAbe6RL"
    Name           = "k6Generator"
    State          = "wordpress-loadtest"
    Struct8Creator = "Contato Struct"
  }
}
