terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

data "cloudflare_zone" "this" {
  zone_id = var.cloudflare_zone_id
}

# DNS records for CloudFront
resource "cloudflare_record" "website" {
  zone_id = var.cloudflare_zone_id
  name    = var.record_name
  content   = var.cloudfront_domain_name
  type    = "CNAME"
  proxied = var.cloudflare_proxied
  ttl     = var.cloudflare_proxied ? 1 : 3600  # Auto TTL when proxied, otherwise 1 hour

  comment = "Main website"
}

# Apex domain A record (for redirection to www)
resource "cloudflare_record" "apex" { 
  zone_id = var.cloudflare_zone_id
  name    = "@"  
  content = "192.0.2.1"  # Dummy IP
  type    = "A"
  proxied = true  
  ttl     = 1
  comment = "Apex domain for redirect"
}

# Redirect Rule: apex to www 
resource "cloudflare_ruleset" "apex_redirect" { 
  zone_id     = var.cloudflare_zone_id
  name        = "Redirect apex to www"
  description = "Redirect example.com to www.example.com"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules {
    action      = "redirect"
    description = "301 redirect from apex to www subdomain"
    enabled     = true
    
    # Match ONLY the apex domain (example.com)
    expression = "(http.host eq \"${data.cloudflare_zone.this.name}\")"
    
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          expression = "concat(\"https://www.${data.cloudflare_zone.this.name}\", http.request.uri.path)"
        }
        preserve_query_string = true
      }
    }
  }
}