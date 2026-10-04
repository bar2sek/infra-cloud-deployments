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
  }
}
