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
    "4JCQs46YTxKawHSWVW6nLA"
  ]
  notification_configs {
    type        = "EMAIL"
    group_email = "riley.snyder@harness.io"
  }
}

resource "harness_platform_connector_github" "Github" {
  identifier      = "Github"
  name            = "Github"
  url             = "https://github.com/rssnyder"
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

resource "harness_platform_connector_artifactory" "harnessartifactory" {
  identifier = "harnessartifactory"
  name       = "harness-artifactory"
  url        = "https://harness.jfrog.io/artifactory/"
}

resource "harness_platform_connector_aws" "sales" {
  identifier = "sales"
  name       = "sales"

  manual {
    access_key     = "AKIA3B4U6ZRO63H37QA3"
    secret_key_ref = "account.salesadminkey"
  }
}

resource "harness_platform_connector_prometheus" "saprom" {
  identifier         = "saprom"
  name               = "sa-prom"
  url                = "http://prometheus-kube-prometheus-prometheus.prometheus.svc.cluster.local:9090/"
  delegate_selectors = ["riley-sa-gcp"]
}

resource "harness_platform_environment" "dev" {
  identifier = "dev"
  name       = "dev"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.development.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: dev
  identifier: dev
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: default
  projectIdentifier: development
  variables: []
EOF
}

resource "harness_platform_infrastructure" "dev_sa" {
  identifier      = "sa"
  name            = "sa"
  org_id          = data.harness_platform_organization.default.id
  project_id      = harness_platform_project.development.id
  env_id          = harness_platform_environment.dev.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: sa
  identifier: sa
  description: ""
  tags: {}
  orgIdentifier: default
  projectIdentifier: development
  environmentRef: dev
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: account.sagcp
    namespace: riley-dev-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

resource "harness_platform_environment" "stage" {
  identifier = "stage"
  name       = "stage"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.development.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: stage
  identifier: stage
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: default
  projectIdentifier: development
  variables: []
EOF
}

resource "harness_platform_infrastructure" "stage_sa" {
  identifier      = "sa"
  name            = "sa"
  org_id          = data.harness_platform_organization.default.id
  project_id      = harness_platform_project.development.id
  env_id          = harness_platform_environment.stage.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: sa
  identifier: sa
  description: ""
  tags: {}
  orgIdentifier: default
  projectIdentifier: development
  environmentRef: stage
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: account.sagcp
    namespace: riley-stage-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}