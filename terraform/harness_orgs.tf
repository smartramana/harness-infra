module "solution-architecture" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.2"
  # source = "../../terraform-harness-structure/modules/organizations"

  name = "solution-architecture"
}

module "test" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.2"
  # source = "../../terraform-harness-structure/modules/organizations"

  name = "test"
}

data "harness_platform_organization" "default" {
  identifier = "default"
  name       = "default"
}