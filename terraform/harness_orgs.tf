data "harness_platform_organization" "default" {
  identifier = "default"
  name       = "default"
}

module "solution-architecture" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.2"

  name = "solution-architecture"
}