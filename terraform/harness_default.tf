data "harness_platform_project" "default" {
  identifier = "Default_Project_1662659562703"
  name       = "Default Project"
  org_id     = data.harness_platform_organization.default.id
}

resource "harness_platform_environment" "dev" {
  identifier = "dev"
  name       = "dev"
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.default.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: dev
  identifier: dev
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: default
  projectIdentifier: default
  variables: []
EOF
}

resource "harness_platform_infrastructure" "dev_sa" {
  identifier      = "sa"
  name            = "sa"
  org_id          = data.harness_platform_organization.default.id
  project_id      = data.harness_platform_project.default.id
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
  projectIdentifier: default
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