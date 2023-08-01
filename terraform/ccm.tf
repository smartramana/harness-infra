resource "harness_platform_connector_azure_cloud_cost" "azure-sales-ccm" {
  identifier = "azuresalesccm"
  name       = "azure-sales-ccm"

  features_enabled = ["BILLING", "VISIBILITY", "OPTIMIZATION"]
  tenant_id        = "b229b2bb-5f33-4d22-bce0-730f6474e906"
  subscription_id  = "e8389fc5-0cb8-44ab-947b-c6cf62552be0"
  billing_export_spec {
    storage_account_name = "rileysnyderharnessio"
    container_name       = "ccm"
    directory_name       = "export"
    report_name          = "rileysnyderharnessccm"
    subscription_id      = "e8389fc5-0cb8-44ab-947b-c6cf62552be0"
  }
}

resource "harness_platform_connector_azure_cloud_cost" "azure-sales-ccm-broken" {
  identifier = "azuresalesccmbroken"
  name       = "azure-sales-ccm-broken"

  features_enabled = ["VISIBILITY", "OPTIMIZATION"]
  tenant_id        = "b229b2bb-5f33-4d22-bce0-730f6474e906"
  subscription_id  = "e8389fc5-0cb8-44ab-947b-c6cf62552be1"
}

resource "harness_platform_connector_awscc" "rileyharnessccm" {
  identifier = "rileyharnessccm"
  name       = "riley-harness-ccm"

  account_id  = "759984737373"
  report_name = "riley-harness-ccm"
  s3_bucket   = "riley-harness-ccm"
  features_enabled = [
    "OPTIMIZATION",
    "VISIBILITY",
    "BILLING",
  ]
  cross_account_access {
    role_arn    = "arn:aws:iam::759984737373:role/riley-HarnessCERole"
    external_id = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
  }
}

# resource "harness_platform_connector_awscc" "rileyharnessccmbroken" {
#   identifier = "rileyharnessccmbroken"
#   name       = "riley-harness-ccm-broken"

#   account_id = "759984737374"
#   features_enabled = [
#     "OPTIMIZATION",
#     "VISIBILITY",
#   ]
#   cross_account_access {
#     role_arn    = "arn:aws:iam::759984737374:role/riley-HarnessCERole"
#     external_id = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
#   }
# }

resource "harness_platform_connector_gcp_cloud_cost" "gcpccm" {
  identifier = "gcpccm"
  name       = "gcp-ccm"

  features_enabled      = ["BILLING", "VISIBILITY", "OPTIMIZATION"]
  gcp_project_id        = "example-proj-234"
  service_account_email = "harness-ce-wlgel-78524@ce-prod-274307.iam.gserviceaccount.com"
  billing_export_spec {
    data_set_id = "data_set_id"
    table_id    = "table_id"
  }
}

resource "harness_platform_connector_gcp_cloud_cost" "gcpccmbroken" {
  identifier = "gcpccmbroken"
  name       = "gcp-ccm-broken"

  features_enabled      = ["VISIBILITY", "OPTIMIZATION"]
  gcp_project_id        = "example-proj-234"
  service_account_email = "harness-ce-wlgel-78524@ce-prod-274307.iam.gserviceaccount.com"
}