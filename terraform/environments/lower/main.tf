terraform {
  backend "s3" {
    bucket         = "fly-tfstate-php-infra-poc"
    key            = "terraform/tfstate/dev"
    dynamodb_table = "php-infra-poc-state-lock"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}
