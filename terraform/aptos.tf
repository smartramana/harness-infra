locals {
  # the manifest of the bundles that a customer has subscribed to
  customerAdev = jsondecode(file("${path.module}/customerAdev.json"))
  # the manifest of all aptos one bundles
  eos_163_1 = jsondecode(file("${path.module}/REL-EndOfSprint-163.1.json"))
  # extract a master list of all services and versions
  eos_163_1_services = flatten([
    for bundles in local.eos_163_1.bundles : [
      for service in bundles.services : {
        name           = replace(service.name, "-", "_")
        version        = service.version
        bundle         = bundles.name
        bundle_version = local.eos_163_1.version
      }
    ]
  ])
}

data "harness_platform_organization" "default" {
  identifier = "default"
  name       = "default"
}

data "harness_platform_project" "aptos_one" {
  identifier = "aptos_one"
  name       = "aptos_one"
  org_id     = data.harness_platform_organization.default.id
}

# create the input set that holds all the services a customer has subscribed to
# based on the bundles defined in their customer json
resource "harness_platform_input_set" "customerA" {
  identifier  = "customerA"
  name        = "customerA"
  org_id      = data.harness_platform_organization.default.id
  project_id  = data.harness_platform_project.aptos_one.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: customerA
  tags: {}
  identifier: customerA
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    stages:
      - stage:
          identifier: dev
          type: Deployment
          spec:
            services:
              values:
              %{for target_bundle in local.customerAdev.deployments.dev-ao-omni-shared.deploy_bundles}
                %{for bundle in local.eos_163_1.bundles}
                  %{if bundle.name == target_bundle}
                    %{for service in bundle.services}
                      - serviceRef: ${replace(service.name, "-", "_")}
                        serviceInputs:
                          serviceDefinition:
                            type: Kubernetes
                            spec:
                              variables:
                                - name: version
                                  type: String
                                  value: "<+pipeline.variables.${replace(service.name, "-", "_")}>"
                    %{endfor}
                  %{endif}
                %{endfor}
              %{endfor}
              %{for service in local.customerAdev.deployments.dev-ao-omni-shared.deploy_services}
                      - serviceRef: ${service}
                        serviceInputs:
                          serviceDefinition:
                            type: Kubernetes
                            spec:
                              variables:
                                - name: version
                                  type: String
                                  value: "<+pipeline.variables.${service}>"
              %{endfor}
              %{for service in keys(local.customerAdev.deployments.dev-ao-omni-shared.deploy_custom_services)}
                      - serviceRef: ${replace(service, "-", "_")}
                        serviceInputs:
                          serviceDefinition:
                            type: Kubernetes
                            spec:
                              variables:
                                - name: version
                                  type: String
                                  value: "${local.customerAdev.deployments.dev-ao-omni-shared.deploy_custom_services[service]}"
              %{endfor}
  EOT
}

# next we compile all of the possible service versions into an input set
# one of these will be created for every  end-of-sprint manifest
resource "harness_platform_input_set" "eos_163_1" {
  identifier  = "eos_163_1"
  name        = "eos_163_1"
  org_id      = data.harness_platform_organization.default.id
  project_id  = data.harness_platform_project.aptos_one.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: eos_163_1
  tags:
    sprint: 163_1
  identifier: eos_163_1
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  pipeline:
    identifier: aptos_demo
    variables:
    %{for service in local.eos_163_1_services}
      - name: ${service.name}
        type: String
        value: ${service.version}
    %{endfor}
  EOT
}

# finally we create a service definition for every service listed in the bundles file
resource "harness_platform_service" "aptosone" {
  for_each   = { for service in local.eos_163_1_services : service.name => service }
  identifier = each.value.name
  name       = each.value.name
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.aptos_one.id
  yaml       = <<EOF
service:
  name: ${each.value.name}
  identifier: ${each.value.name}
  tags:
    bundle: ${each.value.bundle}
  serviceDefinition:
    type: Kubernetes
    spec:
      manifests:
        - manifest:
            identifier: template
            type: K8sManifest
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.Github
                  gitFetchType: Branch
                  paths:
                    - deployment.yaml
                  repoName: rssnyder/template
                  branch: main
              valuesPaths:
                - values.yaml
              skipResourceVersioning: false
      artifacts:
        primary:
          primaryArtifactRef: ${each.value.name}
          sources:
            - spec:
                connectorRef: account.dockerhub
                imagePath: library/${each.value.name}
                tag: <+serviceVariables.version>
              identifier: ${each.value.name}
              type: DockerRegistry
      variables:
        - name: version
          type: String
          description: ""
          value: "<+input>"
          default: "0.0.0"
EOF
}

# lastly we build a pipeline that has inputs for each service's version
resource "harness_platform_pipeline" "aptos_demo" {
  identifier = "aptos_demo"
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.aptos_one.id
  name       = "aptos_demo"
  yaml       = <<-EOT
pipeline:
  name: aptos_demo
  identifier: aptos_demo
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
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
  %{for service in local.eos_163_1_services}
    - name: ${service.name}
      type: String
      value: <+input>
  %{endfor}
  EOT
}
