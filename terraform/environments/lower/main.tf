terraform {
  backend "s3" {
    bucket         = "flynn-tfstate-php-infra-poc"
    key            = "terraform/tfstate/dev"
    region         = "us-east-1"
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.role_arn
  }
}
