terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "0.14.11"
    }
  }
}

provider "harness" {
  # platform_api_key = var.token
}