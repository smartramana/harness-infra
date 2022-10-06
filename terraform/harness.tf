data "harness_platform_organization" "default" {
  identifier = "default"
  name       = "default"
}

resource "harness_platform_project" "development" {
  identifier = "development"
  name       = "development"
  org_id     = data.harness_platform_organization.default.id
}

resource "harness_platform_usergroup" "approvers" {
  identifier         = "approvers"
  name               = "approvers"
  org_id             = data.harness_platform_organization.default.id
  project_id         = harness_platform_project.development.id
  externally_managed = false
  users = [
    "riley.snyder@harness.io"
  ]
  notification_configs {
    type        = "EMAIL"
    group_email = "riley.snyder@harness.io"
  }
}

resource "harness_platform_connector_github" "Github" {
  identifier      = "Github"
  name            = "Github"
  url             = "https://github.com"
  connection_type = "Account"
  validation_repo = "rssnyder/test"

  delegate_selectors = ["riley-sa-gcp"]

  api_authentication {
    token_ref = "account.gh_pat"
  }

  credentials {
    http {
      username  = "rssnyder"
      token_ref = "account.gh_pat"
    }
  }
}