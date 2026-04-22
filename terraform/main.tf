terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
}

data "aws_ssm_parameter" "cloudflare_api_token" {
  name = var.cloudflare_api_token_ssm_path
  with_decryption = true
}

provider "cloudflare" {
  api_token = data.aws_ssm_parameter.cloudflare_api_token.value
}

module "acm" {
  count  = var.domain_name != "" ? 1 : 0
  source = "./modules/acm"
  
  providers = {
    aws        = aws.us_east_1  # ACM in us-east-1
    cloudflare = cloudflare
  }
  
  domain_name        = var.domain_name
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "frontend" {
  source = "./modules/frontend"
  
  bucket_name = var.bucket_name
  domain_name = var.domain_name
  acm_certificate_arn = var.domain_name != "" ? module.acm[0].certificate_arn : ""

  depends_on = [module.acm]
}

module "dns" {
  count  = var.domain_name != "" ? 1 : 0
  source = "./modules/dns"
  
  cloudflare_zone_id      = var.cloudflare_zone_id
  record_name             = var.dns_record_name
  cloudfront_domain_name  = module.frontend.cloudfront_domain_name
  cloudflare_proxied      = var.cloudflare_proxied
}

module "iam" {
  source = "./modules/iam"
  
  s3_bucket_arn    = module.frontend.bucket_arn
  cloudfront_distribution_arn   = module.frontend.cloudfront_distribution_arn
  github_repo_name = var.github_repo_name
}