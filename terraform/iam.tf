data "aws_iam_group" "administrators" {
  group_name = "Administrators"
}

resource "aws_iam_user" "rileysnyderharnessio" {
  name = "riley.snyder@harness.io"
}

# resource "aws_iam_user_group_membership" "rileysnyderharnessio-administrators" {
#   user = aws_iam_user.rileysnyderharnessio.name

#   groups = [
#     data.aws_iam_group.administrators.group_name
#   ]
# }

resource "aws_iam_user" "rileysnyderharnessio-connector" {
  name = "riley.snyder@harness.io-connector"
}

# resource "aws_iam_user_group_membership" "rileysnyderharnessio-connector-administrators" {
#   user = aws_iam_user.rileysnyderharnessio-connector.name

#   groups = [
#     data.aws_iam_group.administrators.group_name
#   ]
# }

data "aws_iam_policy_document" "rileysnyderharnessio-assumed" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.rileysnyderharnessio.arn,
        aws_iam_user.rileysnyderharnessio-connector.arn,
        module.delegate.aws_iam_role_task
      ]
    }
  }
}

resource "aws_iam_role" "rileysnyderharnessio-assumed" {
  name               = "rileysnyderharnessio-assumed"
  assume_role_policy = data.aws_iam_policy_document.rileysnyderharnessio-assumed.json
}

resource "aws_iam_role_policy_attachment" "rileysnyderharnessio-assumed-AdministratorAccess" {
  role       = aws_iam_role.rileysnyderharnessio-assumed.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "rileysnyderharnessio-assumed-again" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.rileysnyderharnessio-assumed.arn
      ]
    }
  }
}

resource "aws_iam_role" "rileysnyderharnessio-assumed-again" {
  name               = "rileysnyderharnessio-assumed-again"
  assume_role_policy = data.aws_iam_policy_document.rileysnyderharnessio-assumed-again.json
}

resource "aws_iam_role_policy_attachment" "rileysnyderharnessio-assumed-again-AdministratorAccess" {
  role       = aws_iam_role.rileysnyderharnessio-assumed-again.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "rileysnyderharnessio-assumed-again-final" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.rileysnyderharnessio-assumed-again.arn
      ]
    }
  }
}

resource "aws_iam_role" "rileysnyderharnessio-assumed-again-final" {
  name               = "rileysnyderharnessio-assumed-again-final"
  assume_role_policy = data.aws_iam_policy_document.rileysnyderharnessio-assumed-again-final.json
}

resource "aws_iam_role_policy_attachment" "rileysnyderharnessio-assumed-again-final-AdministratorAccess" {
  role       = aws_iam_role.rileysnyderharnessio-assumed-again-final.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
