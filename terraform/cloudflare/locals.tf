locals {
  # Pattern: tunnel-<platform>-homelab-<env>-<region-code>-<iteration>
  tunnel_name = "tunnel-${var.platform}-homelab-${var.env}-${var.region_code}-${var.iteration}"

  # Applications protected by Cloudflare Zero Trust Access
  access_apps = {
    tesla = {
      name             = "TeslaMate"
      subdomain        = "tesla"
      session_duration = "24h"
    }
    grafana = {
      name             = "Grafana"
      subdomain        = "grafana"
      session_duration = "24h"
    }
    omni = {
      name             = "Sidero Omni"
      subdomain        = "omni"
      session_duration = "12h"
    }
    ceph = {
      name             = "Ceph Dashboard"
      subdomain        = "ceph"
      session_duration = "12h"
    }
    finance = {
      name             = "Actual Budget"
      subdomain        = "finance"
      session_duration = "168h" # 7 days
    }
    diet = {
      name             = "Mealie"
      subdomain        = "diet"
      session_duration = "720h" # 30 days
    }
    # The identity provider itself. Its only human user is the homelab admin,
    # so a public login page and admin API add attack surface without benefit.
    auth = {
      name             = "Authentik"
      subdomain        = "auth"
      session_duration = "24h"
    }
  }

  # Authentik OIDC back-channel endpoints that must stay reachable without an
  # Access session. Grafana's SERVER (not a browser) calls them, so it cannot
  # carry an Access cookie. They are not anonymous: the token endpoint requires
  # the OAuth client secret, and userinfo requires a bearer access token.
  # Cloudflare evaluates the most specific path first, so only these paths
  # bypass the `auth` application above.
  authentik_backchannel_paths = {
    "application/o/token"    = "Authentik OIDC token endpoint (back-channel)"
    "application/o/userinfo" = "Authentik OIDC userinfo endpoint (back-channel)"
  }
}
