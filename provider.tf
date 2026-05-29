# Definition AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Zielregion
provider "aws" {
  region = var.aws_region
}
