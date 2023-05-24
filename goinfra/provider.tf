terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
  backend "s3" {
    key    = "aws/goinfra/terraform.tfstate"
    region = "us-east-1"
  }
}
