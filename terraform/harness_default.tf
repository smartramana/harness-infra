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
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.default.id}
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
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.default.id}
  environmentRef: ${harness_platform_environment.dev.id}
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: account.sagcp
    namespace: riley-${harness_platform_environment.dev.id}-<+service.name>
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

resource "harness_platform_service" "delegate" {
  identifier = "delegate"
  name       = "delegate"
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.default.id
  yaml       = <<EOF
service:
  name: delegate
  identifier: delegate
  tags: {}
  serviceDefinition:
    spec:
      manifests:
        - manifest:
            identifier: delegate
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.rssnyder
                  gitFetchType: Branch
                  paths:
                    - delegate.yaml
                  repoName: template
                  branch: main
              valuesPaths:
                - delegate_values.yaml
                - namespace.yaml
              skipResourceVersioning: false
      artifacts:
        primary:
          primaryArtifactRef: <+input>
          sources:
            - spec:
                connectorRef: account.dockerhub
                imagePath: <+pipeline.stages.test.spec.execution.steps.test.spec.repo>
                tag: <+pipeline.variables.test_tag>
              identifier: delegate
              type: DockerRegistry
      variables:
        - name: namespace
          type: String
          description: ""
          value: riley-${harness_platform_environment.dev.id}-delegate
    type: Kubernetes
EOF
}