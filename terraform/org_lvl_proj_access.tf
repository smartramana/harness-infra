module "orglvl" {
  source  = "harness-community/structure/harness//modules/organizations"
  version = "0.1.2"

  name = "orglvl"
}

module "projlvl" {
  source  = "harness-community/structure/harness//modules/projects"
  version = "0.1.2"

  name            = "projlvl"
  organization_id = module.orglvl.details.id
}

module "specific_project" {
  source  = "harness-community/rbac/harness//modules/resource_groups"
  version = "0.1.0"

  harness_platform_account = "wlgELJ0TTre5aZhzpt8gVA"
  name                     = "specific_project"
  organization_id          = module.orglvl.details.id
  resource_group_scopes = [
    {
      filter          = "EXCLUDING_CHILD_SCOPES"
      organization_id = module.orglvl.details.id
      project_id      = module.projlvl.details.id
    }
  ]
}

module "project_admin" {
  source  = "harness-community/rbac/harness//modules/roles"
  version = "0.1.0"

  name            = "project_admin"
  organization_id = module.orglvl.details.id
  role_permissions = [
    "core_environment_view",
    "core_environment_edit",
    "core_environment_delete",
    "core_environment_access",
    "core_service_view",
    "core_service_edit",
    "core_service_delete",
    "core_service_access",
    "core_pipeline_view",
    "core_pipeline_edit",
    "core_pipeline_delete",
    "core_pipeline_execute",
    "core_template_view",
    "core_template_copy",
    "core_template_edit",
    "core_template_delete",
    "core_template_access",
  ]
}

resource "harness_platform_service_account" "orglvl" {
  identifier = "orglvl"
  name       = "orglvl"
  email      = "orglvl@service.harness.io"
  org_id     = module.orglvl.details.id
  account_id = "wlgELJ0TTre5aZhzpt8gVA"
}