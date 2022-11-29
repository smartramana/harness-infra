resource "aws_iam_policy" "delegate_aws_access" {
  name        = "delegate_aws_access"
  description = "Policy for harness delegate aws access"

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
       },
       {
           "Sid": "AssumeAdmin",
           "Effect": "Allow",
           "Action": "sts:AssumeRole",
           "Resource": "${aws_iam_role.rileysnyderharnessio-assumed.arn}"
       }
   ]
}
EOF
}

module "delegate" {
  source = "git::https://github.com/rssnyder/terraform-aws-harness-delegate-ecs-fargate.git?ref=0.0.3"
  #   source                    = "../../terraform-aws-harness-delegate-ecs-fargate"
  name                      = "ecs"
  harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:759984737373:secret:riley/delegate-zBsttc"
  delegate_policy_arn       = aws_iam_policy.delegate_aws_access.arn
  security_groups = [
    module.vpc.default_security_group_id
  ]
  subnets     = module.vpc.private_subnets
  init_script = <<EOF
apt-get update -y
apt-get install jq -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip -q awscliv2.zip \
  && ./aws/install \
  && aws --version
  EOF

}

# module "delegate-fallback" {
#   source                    = "git::https://github.com/rssnyder/terraform-aws-harness-delegate-ecs-fargate.git?ref=0.0.1"
#   source                    = "../../terraform-aws-harness-delegate-ecs-fargate"
#   name                      = "ecs-fallback"
#   harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
#   delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:759984737373:secret:riley/delegate-zBsttc"
#   delegate_policy_arn       = aws_iam_policy.delegate_aws_access.arn
#   security_groups = [
#     module.vpc.default_security_group_id
#   ]
#   subnets    = module.vpc.private_subnets
#   cluster_id = module.delegate.aws_ecs_cluster
# }

# Schedle task to only run durring work hours

data "aws_iam_policy_document" "ecs_scheduler_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_scheduler_lambda" {
  name               = "ecs_scheduler_lambda"
  assume_role_policy = data.aws_iam_policy_document.ecs_scheduler_lambda.json
}

resource "aws_iam_role_policy_attachment" "ecs_scheduler_lambda" {
  role       = aws_iam_role.ecs_scheduler_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_scheduler_lambda_logs" {
  role       = aws_iam_role.ecs_scheduler_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "ecs_scheduler" {
  type        = "zip"
  output_path = "/tmp/ecs_scheduler.zip"
  source {
    content  = <<EOF
from os import getenv

import boto3


def lambda_handler(event, context):
    """
    on an event, start or stop an ecs task
    """

    cluster = getenv("CLUSTER")
    service = getenv("SERVICE")

    action = event.get("action", "stop")

    client = boto3.client("ecs")

    if action == "start":
        print(f"starting {cluster}/{service}")
        client.update_service(
            cluster=cluster,
            service=service,
            desiredCount=1,
        )
    else:
        print(f"stopping {cluster}/{service}")
        client.update_service(
            cluster=cluster,
            service=service,
            desiredCount=0,
        )
EOF
    filename = "main.py"
  }
}

resource "aws_lambda_function" "ecs_scheduler" {

  filename         = data.archive_file.ecs_scheduler.output_path
  source_code_hash = data.archive_file.ecs_scheduler.output_base64sha256

  function_name = "ecs_scheduler"
  role          = aws_iam_role.ecs_scheduler_lambda.arn
  handler       = "main.lambda_handler"

  runtime = "python3.9"

  environment {
    variables = {
      CLUSTER = module.delegate.aws_ecs_cluster,
      SERVICE = module.delegate.aws_ecs_service
    }
  }
}

data "aws_iam_policy_document" "ecs_scheduler" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "scheduler.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_scheduler" {
  name               = "ecs_scheduler"
  assume_role_policy = data.aws_iam_policy_document.ecs_scheduler.json
}

resource "aws_iam_policy" "ecs_scheduler" {
  name        = "ecs_scheduler"
  description = "Policy for triggering lambda"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "Invoke",
           "Effect": "Allow",
           "Action": [
               "lambda:InvokeFunction"
           ],
           "Resource": [
              "${aws_lambda_function.ecs_scheduler.arn}"
           ]
       }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_scheduler" {
  role       = aws_iam_role.ecs_scheduler.name
  policy_arn = aws_iam_policy.ecs_scheduler.arn
}

resource "aws_scheduler_schedule" "ecs_scheduler_start" {
  name = "ecs_scheduler_start"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 13 ? * MON-FRI *)"

  target {
    arn      = aws_lambda_function.ecs_scheduler.arn
    role_arn = aws_iam_role.ecs_scheduler.arn
    input = jsonencode({
      action = "start"
    })
  }
}

resource "aws_scheduler_schedule" "ecs_scheduler_stop" {
  name = "ecs_scheduler_stop"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 21 ? * MON-FRI *)"

  target {
    arn      = aws_lambda_function.ecs_scheduler.arn
    role_arn = aws_iam_role.ecs_scheduler.arn
    input = jsonencode({
      action = "stop"
    })
  }
}