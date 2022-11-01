resource "aws_s3_bucket" "riley-snyder-harness-io" {
  bucket = "riley-snyder-harness-io"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "riley-snyder-harness-io" {
  bucket = aws_s3_bucket.riley-snyder-harness-io.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "riley-snyder-harness-io" {
  bucket = aws_s3_bucket.riley-snyder-harness-io.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "ccm" {
  source                  = "git::https://github.com/rssnyder/terraform-aws-harness-ccm.git?ref=main"
  external_id             = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
  additional_external_ids = ["harness:891928451355:V2iSB2gRR_SxBs0Ov5vqCQ"]
  enable_events           = true
  enable_optimization     = true
  prefix                  = "riley-"
}

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
