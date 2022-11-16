module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "sa-lab"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # enable_flow_log                      = true
  # create_flow_log_cloudwatch_iam_role  = true
  # create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "type"                         = "public"
    "vpc"                          = "sa-lab"
    "kubernetes.io/cluster/sa-lab" = "shared"
    "kubernetes.io/role/elb"       = 1
  }

  private_subnet_tags = {
    "type"                            = "private"
    "vpc"                             = "sa-lab"
    "kubernetes.io/cluster/sa-lab"    = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow traffic for websites"
  vpc_id      = module.vpc.vpc_id

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

resource "aws_security_group" "instance" {
  name        = "instance"
  description = "Allow traffic for harness"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "vpc sg"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [module.vpc.default_security_group_id]
  }

  ingress {
    description = "vpc cidr"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  ingress {
    description = "drone"
    from_port   = 9079
    to_port     = 9079
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}