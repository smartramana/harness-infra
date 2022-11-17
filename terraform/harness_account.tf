resource "harness_platform_connector_github" "Github" {
  identifier      = "Github"
  name            = "Github"
  url             = "https://github.com"
  connection_type = "Account"
  validation_repo = "rssnyder/test"

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

resource "harness_platform_connector_docker" "dockerhub" {
  identifier = "dockerhub"
  name       = "dockerhub"
  type       = "DockerHub"
  url        = "https://index.docker.io/v2/"

  credentials {
    username     = "rileysnyderharnessio"
    password_ref = "account.dockerhub"
  }
}

resource "harness_platform_connector_aws" "sales" {
  identifier = "sales"
  name       = "sales"

  manual {
    access_key     = "AKIA3B4U6ZRO63H37QA3"
    secret_key_ref = "account.salesadminkey"
  }
}