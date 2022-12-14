# provider "harness" {
#   endpoint = "https://app.harness.io/gateway"
# }

# resource "harness_application" "something" {
#   name        = "something"
#   description = "This is something"

#   tags = [
#     "mytag:myvalue",
#     "team:development"
#   ]x
# }

# resource "harness_service_kubernetes" "something" {
#   app_id       = harness_application.something.id
#   name         = "k8s"
#   helm_version = "V3"
#   description  = "Service for deploying Kubernetes manifests"

#   variable {
#     name  = "test"
#     value = "test_value"
#     type  = "TEXT"
#   }

#   variable {
#     name  = "test2"
#     value = "test_value2"
#     type  = "TEXT"
#   }
# }

# resource "harness_environment" "dev" {
#   app_id = harness_application.something.id
#   name   = "dev"
#   type   = "NON_PROD"
# }

# resource "harness_environment" "qa" {
#   app_id = harness_application.something.id
#   name   = "qa"
#   type   = "NON_PROD"
# }

# resource "harness_environment" "prod" {
#   app_id = harness_application.something.id
#   name   = "prod"
#   type   = "PROD"
# }
