resource "harness_platform_pipeline" "gke_dev" {
  identifier = "gke_dev"
  org_id     = "default"
  project_id = "development"
  name       = "gke_dev"

  yaml = <<-EOT
pipeline:
  name: gke_dev
  identifier: gke_dev
  orgIdentifier: default
  projectIdentifier: development
  tags: {}
  stages:
    - stage:
        name: dev
        identifier: dev
        template:
          templateRef: gke
          versionLabel: "1"
          templateInputs:
            type: Deployment
            spec:
              services:
                values: <+input>
  variables:
    - name: scp_service_customer
      type: String
      value: <+input>
    - name: scp_service_loyalty_memberships
      type: String
      value: <+input>
    - name: scp_service_eom_inventory_facade
      type: String
      value: <+input>
    - name: scp_service_eom_order_facade
      type: String
      value: <+input>
  EOT
}

resource "harness_platform_triggers" "gke_dev" {
  identifier = "gke_dev"
  org_id     = "default"
  project_id = "development"
  name       = "gke_dev"
  target_id  = harness_platform_pipeline.gke_dev.id
  yaml       = <<-EOT
trigger:
  name: release
  identifier: release
  enabled: true
  orgIdentifier: default
  projectIdentifier: Default_Project_1659484619331
  pipelineIdentifier: dst
  source:
    type: Webhook
    spec:
      type: Custom
      spec:
        payloadConditions:
          - key: <+trigger.payload.action>
            operator: Equals
            value: created
  inputYaml: |
    pipeline:
      identifier: dst
      properties:
        ci:
          codebase:
            build:
              type: tag
              spec:
                tag: <+eventPayload.release.tag_name>
    EOT
}