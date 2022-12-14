resource "azurerm_resource_group" "rileysnyderharnessio" {
  name     = "rileysnyderharnessio"
  location = "South Central US"

  tags = {
    owner = "riley.snyder@harness.io"
    ttl   = "-1"
  }
}

# module "network" {
#   source = "Azure/network/azurerm"

#   vnet_name           = "sa-lab"
#   resource_group_name = azurerm_resource_group.rileysnyderharnessio.name
#   address_spaces      = ["10.0.0.0/16"]
#   subnet_prefixes     = ["10.0.1.0/24"]
#   subnet_names        = ["subnet0"]

#   use_for_each = true
#   tags = {
#     owner = "riley.snyder@harness.io"
#     ttl   = "-1"
#   }
# }

# resource "azurerm_container_group" "delegate" {
#   name                = "aci"
#   location            = azurerm_resource_group.rileysnyderharnessio.location
#   resource_group_name = azurerm_resource_group.rileysnyderharnessio.name
#   ip_address_type     = "Private"
#   #   dns_name_label      = "harness-delegate"
#   os_type    = "Linux"
#   subnet_ids = module.network.vnet_subnets

#   container {
#     name   = "harness-delegate"
#     image  = "harness/delegate:latest"
#     cpu    = "1"
#     memory = "1.5"
#     environment_variables = {
#       ACCOUNT_ID                = "wlgELJ0TTre5aZhzpt8gVA"
#       DELEGATE_TOKEN            = "6b3f9392f5a8037372c86c906dd13ce9"
#       MANAGER_HOST_AND_PORT     = "https://app.harness.io/gratis"
#       LOG_STREAMING_SERVICE_URL = "https://app.harness.io/gratis/log-service/"
#       DEPLOY_MODE               = "KUBERNETES"
#       DELEGATE_NAME             = "aci"
#       NEXT_GEN                  = "true"
#       DELEGATE_TYPE             = "DOCKER"
#       DELEGATE_TAGS             = ""
#       INIT_SCRIPT               = "echo 'Docker delegate init script executed.'"
#     }
#   }
# }