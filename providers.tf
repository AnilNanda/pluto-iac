terraform {
  backend "remote" {
    organization = "anilnanda"
    hostname     = "app.terraform.io"
    workspaces {
      name = "Projectpluto"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}