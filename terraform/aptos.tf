resource "harness_platform_input_set" "bundle0" {
  identifier  = "bundle0"
  name        = "bundle0"
  org_id      = data.harness_platform_organization.default.id
  project_id  = harness_platform_project.development.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: bundle0
  tags: {}
  identifier: bundle0
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  pipeline:
    identifier: aptos_demo
    variables:
      - name: dst_version
        type: String
        value: v3.10.1
      - name: nginx_version
        type: String
        value: stable
  EOT
}

resource "harness_platform_input_set" "bundle1" {
  identifier  = "bundle1"
  name        = "bundle1"
  org_id      = data.harness_platform_organization.default.id
  project_id  = harness_platform_project.development.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: bundle1
  tags: {}
  identifier: bundle1
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    variables:
      - name: dst_version
        type: String
        value: v3.11.0-beta.1
      - name: nginx_version
        type: String
        value: stable-alpine
  EOT
}

resource "harness_platform_input_set" "bundle2" {
  identifier  = "bundle2"
  name        = "bundle2"
  org_id      = data.harness_platform_organization.default.id
  project_id  = harness_platform_project.development.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: bundle2
  tags: {}
  identifier: bundle2
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    variables:
      - name: dst_version
        type: String
        value: v3.11.0-beta.2
      - name: nginx_version
        type: String
        value: stable-alpine
  EOT
}

resource "harness_platform_input_set" "customerA" {
  identifier  = "customerA"
  name        = "customerA"
  org_id      = data.harness_platform_organization.default.id
  project_id  = harness_platform_project.development.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: customerA
  tags: {}
  identifier: customerA
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    stages:
      - stage:
          identifier: dev
          type: Deployment
          spec:
            services:
              values:
                - serviceRef: dst
                  serviceInputs:
                    serviceDefinition:
                      type: Kubernetes
                      spec:
                        artifacts:
                          primary:
                            sources:
                              - identifier: ghcr
                                type: DockerRegistry
                                spec:
                                  tag: <+pipeline.variables.dst_version>
                - serviceRef: nginx
                  serviceInputs:
                    serviceDefinition:
                      type: Kubernetes
                      spec:
                        artifacts:
                          primary:
                            sources:
                              - identifier: nginx
                                type: DockerRegistry
                                spec:
                                  tag: <+pipeline.variables.nginx_version>
                            primaryArtifactRef: ""
                        variables:
                          - name: port
                            type: String
                            value: "8080"
                          - name: replicas
                            type: String
                            value: "1"
  EOT
}

resource "harness_platform_input_set" "customerB" {
  identifier  = "customerB"
  name        = "customerB"
  org_id      = data.harness_platform_organization.default.id
  project_id  = harness_platform_project.development.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: customerB
  tags: {}
  identifier: customerB
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    stages:
      - stage:
          identifier: dev
          type: Deployment
          spec:
            services:
              values:
                - serviceRef: dst
                  serviceInputs:
                    serviceDefinition:
                      type: Kubernetes
                      spec:
                        artifacts:
                          primary:
                            sources:
                              - identifier: ghcr
                                type: DockerRegistry
                                spec:
                                  tag: <+pipeline.variables.dst_version>
  EOT
}

resource "harness_platform_pipeline" "aptos_demo" {
  identifier = "aptos_demo"
  org_id     = data.harness_platform_organization.default.id
  project_id = harness_platform_project.development.id
  name       = "aptos_demo"

  yaml = <<-EOT
pipeline:
  name: aptos_demo
  identifier: aptos_demo
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${harness_platform_project.development.id}
  tags: {}
  stages:
    - stage:
        name: dev
        identifier: dev
        description: ""
        type: Deployment
        spec:
          deploymentType: Kubernetes
          services:
            values: <+input>
            metadata:
              parallel: true
          environment:
            environmentRef: dev
            deployToAll: false
            infrastructureDefinitions:
              - identifier: sagcp
          execution:
            steps:
              - step:
                  name: Rollout Deployment
                  identifier: rolloutDeployment
                  type: K8sRollingDeploy
                  timeout: 10m
                  spec:
                    skipDryRun: false
                    pruningEnabled: false
            rollbackSteps:
              - step:
                  name: Rollback Rollout Deployment
                  identifier: rollbackRolloutDeployment
                  type: K8sRollingRollback
                  timeout: 10m
                  spec:
                    pruningEnabled: false
        tags: {}
        failureStrategies:
          - onFailure:
              errors:
                - AllErrors
              action:
                type: StageRollback
  variables:
    - name: dst_version
      type: String
      description: ""
      value: <+input>
    - name: nginx_version
      type: String
      description: ""
      value: <+input>
  EOT
}