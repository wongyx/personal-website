terraform {
  backend "s3" {
    bucket         = "wyx-website-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}