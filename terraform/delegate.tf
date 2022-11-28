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
