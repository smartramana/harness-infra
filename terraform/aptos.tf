locals {
  # pull in all customer bundles and bundle manifests
  customer_bundle_files = fileset(path.module, "customer*.json")
  bundle_manifest_files = fileset(path.module, "REL-EndOfSprint-*.json")

  # we need one bundle manifest to serve as the source for all service definitions
  # here we attempt to pull in the latest bundle manifest by picking the last one (acending ordered list)
  all_bundles = jsondecode(file(element(tolist(local.bundle_manifest_files), length(local.bundle_manifest_files) - 1)))

  # extract a master list of all services and versions
  all_bundles_services = flatten([
    for bundles in local.all_bundles.bundles : [
      for service in bundles.services : replace(service.name, "-", "_")
    ]
  ])

  # test = flatten([
  #   for customer in local.customer_bundle_files : [
  #     for deployment in keys(jsondecode(file(customer)).deployments) : merge({
  #       customer = split(".", customer)[0]
  #       name     = deployment
  #     }, jsondecode(file(customer)).deployments[deployment])
  #   ]
  # ])
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

# we need an environment defined
resource "harness_platform_environment" "test" {
  identifier = "test"
  name       = "test"
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.aptos_one.id
  type       = "PreProduction"
  yaml       = <<EOF
environment:
  name: test
  identifier: test
  description: ""
  tags: {}
  type: PreProduction
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  variables: []
EOF
}

# and an infrastructure (cluster) to deploy to
resource "harness_platform_infrastructure" "test_k8s" {
  identifier      = "test_k8s"
  name            = "test_k8s"
  org_id          = data.harness_platform_organization.default.id
  project_id      = data.harness_platform_project.aptos_one.id
  env_id          = harness_platform_environment.test.id
  type            = "KubernetesDirect"
  deployment_type = "Kubernetes"
  yaml            = <<EOF
infrastructureDefinition:
  name: "test_k8s"
  identifier: "test_k8s"
  description: ""
  tags: {}
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  environmentRef: ${harness_platform_environment.test.id}
  deploymentType: Kubernetes
  type: KubernetesDirect
  spec:
    connectorRef: account.${harness_platform_connector_kubernetes.sagcp.id}
    namespace: riley
    releaseName: release-<+INFRA_KEY>
  allowSimultaneousDeployments: false
EOF
}

# create the input set that holds all the services a customer has subscribed to
# based on the bundles defined in their customer json
# assumes customer files are named customerSOMEIDENTIFIER.json
# todo: hard coded to pull out dev-ao-omni-shared cluster
resource "harness_platform_input_set" "customer" {
  for_each = local.customer_bundle_files

  identifier  = lower(replace(split(".", each.value)[0], "-", "_"))
  name        = lower(replace(split(".", each.value)[0], "-", "_"))
  org_id      = data.harness_platform_organization.default.id
  project_id  = data.harness_platform_project.aptos_one.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml        = <<-EOT
inputSet:
  name: ${lower(replace(split(".", each.value)[0], "-", "_"))}
  tags: {}
  identifier: ${lower(replace(split(".", each.value)[0], "-", "_"))}
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  pipeline:
    identifier: ${harness_platform_pipeline.aptos_demo.id}
    stages:
      - stage:
          identifier: test
          type: Deployment
          spec:
            services:
              values:
              %{for target_bundle in jsondecode(file("${path.module}/${each.value}")).deployments.dev-ao-omni-shared.deploy_bundles}
                %{for bundle in local.all_bundles.bundles}
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
              %{for service in jsondecode(file("${path.module}/${each.value}")).deployments.dev-ao-omni-shared.deploy_services}
                - serviceRef: ${replace(service, "-", "_")}
                  serviceInputs:
                    serviceDefinition:
                      type: Kubernetes
                      spec:
                        variables:
                          - name: version
                            type: String
                            value: "<+pipeline.variables.${replace(service, "-", "_")}>"
              %{endfor}
              %{for service in keys(jsondecode(file("${path.module}/${each.value}")).deployments.dev-ao-omni-shared.deploy_custom_services)}
                - serviceRef: ${replace(service, "-", "_")}
                  serviceInputs:
                    serviceDefinition:
                      type: Kubernetes
                      spec:
                        variables:
                          - name: version
                            type: String
                            value: "${jsondecode(file("${path.module}/${each.value}")).deployments.dev-ao-omni-shared.deploy_custom_services[service]}"
              %{endfor}
  EOT
}

# next we compile all of the possible service versions into an input set
# one of these will be created for every  end-of-sprint manifest
# assumes customer files are named REL-EndOfSprint-SOMEIDENTIFIER.json
resource "harness_platform_input_set" "eos" {
  for_each = local.bundle_manifest_files

  identifier  = lower(replace(split(".", each.value)[0], "-", "_"))
  name        = lower(replace(split(".", each.value)[0], "-", "_"))
  org_id      = data.harness_platform_organization.default.id
  project_id  = data.harness_platform_project.aptos_one.id
  pipeline_id = harness_platform_pipeline.aptos_demo.id
  yaml = <<-EOT
inputSet:
  name: ${lower(replace(split(".", each.value)[0], "-", "_"))}
  identifier: ${lower(replace(split(".", each.value)[0], "-", "_"))}
  orgIdentifier: ${data.harness_platform_organization.default.id}
  projectIdentifier: ${data.harness_platform_project.aptos_one.id}
  tags: {}
  pipeline:
    identifier: aptos_demo
    variables:
    %{for service in flatten([for bundles in jsondecode(file("${path.module}/${each.value}")).bundles : [for service in bundles.services : {
  name    = replace(service.name, "-", "_")
  version = service.version
}]])}
      - name: ${service.name}
        type: String
        value: ${service.version}
    %{endfor}
  EOT
}

# finally we create a service definition for every service listed in the bundles file
resource "harness_platform_service" "aptosone" {
  for_each   = toset(local.all_bundles_services)
  identifier = each.key
  name       = each.key
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.aptos_one.id
  yaml       = <<EOF
service:
  name: ${each.key}
  identifier: ${each.key}
  tags: {}
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
          primaryArtifactRef: ${each.key}
          sources:
            - spec:
                connectorRef: account.dockerhub
                imagePath: library/${each.key}
                tag: <+serviceVariables.version>
              identifier: ${each.key}
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
        name: ${harness_platform_environment.test.id}
        identifier: ${harness_platform_environment.test.id}
        description: ""
        type: Deployment
        spec:
          deploymentType: Kubernetes
          services:
            values: <+input>
            metadata:
              parallel: true
          environment:
            environmentRef: ${harness_platform_environment.test.id}
            deployToAll: false
            infrastructureDefinitions:
              - identifier: ${harness_platform_infrastructure.test_k8s.id}
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
  %{for service in local.all_bundles_services}
    - name: ${service}
      type: String
      value: <+input>
  %{endfor}
  EOT
}
