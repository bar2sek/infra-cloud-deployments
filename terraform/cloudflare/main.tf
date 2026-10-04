# Random secret for Cloudflare Tunnel encryption
resource "random_id" "tunnel_secret" {
  byte_length = 35
}

# 1. Cloudflare Tunnel Creation
resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab_tunnel" {
  account_id = var.cloudflare_account_id
  name       = local.tunnel_name
  secret     = random_id.tunnel_secret.b64_std
}

# 2. Cloudflare Tunnel Ingress Configuration
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "homelab_tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id

  config {
    ingress_rule {
      hostname = "tesla.${var.domain_name}"
      service  = "http://teslamate.teslamate.svc.cluster.local:4000"
    }
    ingress_rule {
      hostname = "finance.${var.domain_name}"
      service  = "http://actual-budget-service.finance.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "diet.${var.domain_name}"
      service  = "http://mealie-service.mealie.svc.cluster.local:80"
    }
    ingress_rule {
      hostname = "grafana.${var.domain_name}"
      service  = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local:443"
      origin_request {
        no_tls_verify = true
      }
    }
    ingress_rule {
      hostname = "omni.${var.domain_name}"
      service  = "https://10.10.10.5:443"
      origin_request {
        no_tls_verify = true
      }
    }
    ingress_rule {
      hostname = "ceph.${var.domain_name}"
      service  = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local:443"
      origin_request {
        no_tls_verify = true
      }
    }
    ingress_rule {
      hostname = "auth.${var.domain_name}"
      service  = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local:443"
      origin_request {
        no_tls_verify = true
      }
    }
    # Catch-all rule
    ingress_rule {
      service = "http_status:404"
    }

  }
}

# 3. CNAME DNS Records Pointing Subdomains to Tunnel
resource "cloudflare_record" "tesla_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "tesla"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "finance_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "finance"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "diet_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "diet"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "grafana_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "grafana"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "omni_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "omni"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "ceph_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "ceph"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "auth_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "auth"
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.homelab_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}


# 4. Cloudflare Zero Trust Access Applications (SSO Protection)
moved {
  from = cloudflare_zero_trust_access_application.admin_apps
  to   = cloudflare_zero_trust_access_application.apps["grafana"]
}

moved {
  from = cloudflare_zero_trust_access_policy.admin_apps_policy
  to   = cloudflare_zero_trust_access_policy.apps_policy["grafana"]
}

resource "cloudflare_zero_trust_access_application" "apps" {
  for_each         = local.access_apps
  zone_id          = var.cloudflare_zone_id
  name             = each.value.name
  domain           = "${each.value.subdomain}.${var.domain_name}"
  type             = "self_hosted"
  session_duration = each.value.session_duration
}

resource "cloudflare_zero_trust_access_policy" "apps_policy" {
  for_each       = local.access_apps
  application_id = cloudflare_zero_trust_access_application.apps[each.key].id
  zone_id        = var.cloudflare_zone_id
  name           = "Allow Authorized Homelab Admin"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [var.destination_email]
  }
}

# 5. Microsoft Entra ID (Azure AD) Identity Provider for Cloudflare Access
resource "cloudflare_zero_trust_access_identity_provider" "entra_id" {
  count      = var.entra_client_id != "" ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = "Microsoft Entra ID"
  type       = "azureAD"

  config {
    client_id      = var.entra_client_id
    client_secret  = var.entra_client_secret
    directory_id   = var.entra_tenant_id
    support_groups = true
  }
}

