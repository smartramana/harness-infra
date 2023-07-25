terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    harness = {
      source = "harness/harness"
      # version = "~> 0.0.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
  default_tags {
    tags = {
      owner = "riley.snyder@harness.io"
      ttl   = "-1"
    }
  }
}

provider "azurerm" {
  features {}
}

