variable "token" {
  type = string
}

data "harness_platform_organization" "default" {
  identifier = "test"
  name       = "test"
}

data "harness_platform_project" "default" {
  identifier = "test"
  name       = "test"
  org_id     = data.harness_platform_organization.default.id
}

resource "harness_platform_service" "fargate-delegate" {
  identifier = "fargatedelegate"
  name       = "fargate-delegate"
  org_id     = data.harness_platform_organization.default.id
  project_id = data.harness_platform_project.default.id
  yaml       = <<EOF
service:
  name: fargate-delegate
  identifier: fargatedelegate
  serviceDefinition:
    type: ECS
    spec:
      manifests:
        - manifest:
            identifier: task
            type: EcsTaskDefinition
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.Github
                  gitFetchType: Branch
                  paths:
                    - delegate_task.json
                  repoName: rssnyder/template
                  branch: main
        - manifest:
            identifier: service
            type: EcsServiceDefinition
            spec:
              store:
                type: Github
                spec:
                  connectorRef: account.Github
                  gitFetchType: Branch
                  paths:
                    - delegate_service.json
                  repoName: rssnyder/template
                  branch: main
      artifacts:
        primary:
          primaryArtifactRef: <+input>
          sources:
            - spec:
                connectorRef: account.dockerhub
                imagePath: rssnyder/delegate
                tag: 23.01.78101
              identifier: delegate
              type: DockerRegistry
      variables:
        - name: cpu
          type: String
          description: ""
          value: "1024"
        - name: memory
          type: String
          description: ""
          value: "2048"
        - name: delegate_name
          type: String
          description: ""
          value: ecstest
        - name: manager_host_and_port
          type: String
          description: ""
          value: https://app.harness.io/gratis
        - name: log_streaming_Service_url
          type: String
          description: ""
          value: https://app.harness.io/gratis/log-service/
        - name: role
          type: String
          description: ""
          value: arn:aws:iam::759984737373:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS
        - name: subnet
          type: String
          description: ""
          value: subnet-0974d4940eab1ea9d
        - name: security_group
          type: String
          description: ""
          value: sg-0472e18c1a90179d9
  gitOpsEnabled: false
EOF
}