data "aws_iam_group" "administrators" {
  group_name = "Administrators"
}

resource "aws_iam_user" "rileysnyderharnessio" {
  name = "riley.snyder@harness.io"
}

resource "aws_iam_user_group_membership" "rileysnyderharnessio-administrators" {
  user = aws_iam_user.rileysnyderharnessio.name

  groups = [
    data.aws_iam_group.administrators.group_name
  ]
}

resource "aws_iam_user" "rileysnyderharnessio-connector" {
  name = "riley.snyder@harness.io-connector"
}

resource "aws_iam_user_group_membership" "rileysnyderharnessio-connector-administrators" {
  user = aws_iam_user.rileysnyderharnessio-connector.name

  groups = [
    data.aws_iam_group.administrators.group_name
  ]
}
