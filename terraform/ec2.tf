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

resource "aws_iam_instance_profile" "minikube" {
  name = "riley_instance"
  role = aws_iam_role.instance.id
}

resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.xlarge"
  key_name      = "riley"

  subnet_id                   = module.vpc.private_subnets[0]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.instance.id]

  iam_instance_profile = aws_iam_instance_profile.minikube.id

  root_block_device {
    volume_size = "20"
  }

  user_data = templatefile("${path.module}/user-data.txt", {})

  tags = {
    Name = "riley-minikube"
  }

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

# resource "aws_instance" "windows" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.xlarge"
#   key_name      = "riley"

#   subnet_id                   = module.vpc.public_subnets[0]
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.instance.id]

#   iam_instance_profile = aws_iam_instance_profile.minikube.id

#   root_block_device {
#     volume_size = "20"
#   }

#   user_data = templatefile("${path.module}/user-data.txt", {})

#   tags = {
#     Name = "riley-minikube"
#   }

#   lifecycle {
#     ignore_changes = [
#       ami
#     ]
#   }
# }