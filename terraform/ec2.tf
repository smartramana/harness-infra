data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "instance" {
  name        = "instance"
  description = "Allow traffic for harness"
  vpc_id      = data.aws_vpc.sa-lab.id

  ingress {
    description     = "vpc sg"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [data.aws_security_group.sa-lab-default.id]
  }

  ingress {
    description = "vpc cidr"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.sa-lab.cidr_block]
  }

  ingress {
    description = "drone"
    from_port   = 9079
    to_port     = 9079
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.sa-lab.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow traffic for websites"
  vpc_id      = data.aws_vpc.sa-lab.id

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "instance" {
  name               = "riley_instance"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.instance.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforSSM" {
  role       = aws_iam_role.instance.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

# resource "aws_iam_role_policy_attachment" "AmazonEC2RoleforEC2FullAccess" {
#   role       = aws_iam_role.instance.id
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
# }

resource "aws_iam_policy" "instance" {
  name        = "riley_instance"
  description = "Policy for rileys ec2 instances"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "GetArtifacts",
           "Effect": "Allow",
           "Action": [
               "s3:*"
           ],
           "Resource": [
              "${aws_s3_bucket.riley-snyder-harness-io.arn}",
              "${aws_s3_bucket.riley-snyder-harness-io.arn}/*"
           ]
       }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance.arn
}

resource "aws_iam_instance_profile" "riley" {
  name = "riley_instances"
  role = aws_iam_role.instance.id
}

resource "aws_instance" "code_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.2xlarge"
  key_name      = "riley"

  subnet_id                   = data.aws_subnets.sa-lab-private.ids[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.instance.id]

  iam_instance_profile = aws_iam_instance_profile.riley.id

  root_block_device {
    volume_size = "20"
  }

  user_data = <<EOF
#!/bin/sh

# source: https://github.com/coder/deploy-code-server/blob/main/deploy-vm/launch-code-server.sh

# install code-server service system-wide
export HOME=/root
curl -fsSL https://code-server.dev/install.sh | sh

# add our helper server to redirect to the proper URL for --link
git clone https://github.com/bpmct/coder-cloud-redirect-server
cd coder-cloud-redirect-server
cp coder-cloud-redirect.service /etc/systemd/system/
cp coder-cloud-redirect.py /usr/bin/

# create a code-server user
adduser --disabled-password --gecos "" coder
echo "coder ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/coder
usermod -aG sudo coder

# copy ssh keys from root
cp -r /root/.ssh /home/coder/.ssh
chown -R coder:coder /home/coder/.ssh

# configure code-server to use --link with the "coder" user
mkdir -p /home/coder/.config/code-server
touch /home/coder/.config/code-server/config.yaml
echo "bind-addr: 0.0.0.0:${var.vscode_port}
auth: password
password: ${var.vscode_password}
cert: false" > /home/coder/.config/code-server/config.yaml
chown -R coder:coder /home/coder/.config

# start and enable code-server and our helper service
systemctl enable --now code-server@coder
systemctl enable --now coder-cloud-redirect
EOF

  tags = {
    Name        = "riley_code_server"
    owner       = "riley_snyder_harness_io"
    ttl         = "-1"
    will_delete = "soon"
  }

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}
