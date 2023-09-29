resource "harness_platform_project" "home_lab" {
  identifier = "home_lab"
  name       = "home_lab"
  org_id     = data.harness_platform_organization.default.id
}

resource "harness_platform_environment" "development" {
  identifier = "development"
  name       = "development"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.home_lab.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: development
  identifier: development
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.home_lab.id}
  variables: []
EOF
}

resource "harness_platform_service" "harness_ccm_k8s_auto" {
  identifier = "harness ccm k8s auto"
  name       = "harness_ccm_k8s_auto"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.home_lab.id
  yaml       = <<EOF
service:
  name: harness ccm k8s auto
  identifier: harness_ccm_k8s_auto
  serviceDefinition:
    type: Kubernetes
    spec:
      manifests:
        - manifest:
            identifier: main
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.${harness_platform_connector_github.Github.id}
                  gitFetchType: Branch
                  paths:
                    - deployment.yaml
                  repoName: harness-community/harness-ccm-k8s-auto
                  branch: main
              valuesPaths:
                - values.yaml
              skipResourceVersioning: false
              enableDeclarativeRollback: false
      artifacts:
        primary:
          primaryArtifactRef: <+input>
          sources:
            - spec:
                connectorRef: account.${harness_platform_connector_docker.dockerhub.id}
                imagePath: harnesscommunity/harness-ccm-k8s-auto
                tag: <+input>
                digest: ""
              identifier: main
              type: DockerRegistry
  gitOpsEnabled: false
EOF
}

resource "harness_platform_service" "longhorn" {
  identifier = "longhorn"
  name       = "longhorn"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.home_lab.id
  yaml       = <<EOF
service:
  name: longhorn
  identifier: longhorn
  orgIdentifier: default
  projectIdentifier: Default_Project_1662659562703
  serviceDefinition:
    spec:
      manifests:
        - manifest:
            identifier: main
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.${harness_platform_connector_github.Github.id}
                  gitFetchType: Branch
                  paths:
                    - deploy/longhorn.yaml
                  repoName: longhorn/longhorn
                  branch: v1.5.x
              skipResourceVersioning: false
              enableDeclarativeRollback: false
    type: Kubernetes

EOF
}
