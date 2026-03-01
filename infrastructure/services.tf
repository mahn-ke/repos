locals {
  generic = {
    ".github"            = ".github"
    "repos"              = "repos"
    "resources"          = "resources"
    "storage-management" = "storage-management"
    "hetzner-robot"      = "hetzner-robot"
  }
  subdomains = {
    for key, value in {
      "tfstate" = {
        skip_uptime_check = true
      }
      "uptime" = {}
      "cloud"  = {}
      "matrix" = {
        uptime_path = "/_matrix/static/"
      }
      "irc" = {}
      "sso" = {}
      "rustdesk" = {
        skip_uptime_check = true
      }
      "notifications" = {}
      "logging"       = {}
      "gamereleases" = {
        uptime_path = "/releases.ics"
      }
      "paperless"    = {}
      "photos"       = {}
      "availability" = {}
      "fitness"      = {}
      "pretix"       = {}
      "errors"       = {}
      "slides"       = {}
      "invoices"     = {}
      "wallpapers" = {
        skip_uptime_check = true
      }
      "kiosk.39c3"     = {}
      "cccbib"         = {}
      "mancala-client" = {}
    } : replace("${key}.by.vincent", ".", "-") => value
  }
  oauth_clients = {
    for key, value in {
      "ttrss" = {
        display_name               = "Tiny Tiny RSS"
        pkce_code_challenge_method = ""
        web_origins = [
          "https://ttrss.by.vincent.mahn.ke"
        ]
      }
      "cloud" = {
        display_name = "Nextcloud"
      }
      "errors" = {
        display_name               = "GlitchTip"
        pkce_code_challenge_method = ""
      }
      "containers" = {
        display_name               = "Portainer"
        pkce_code_challenge_method = ""
      }
      "paperless" = {
        display_name = "Paperless"
      }
      "jellyfin" = {
        display_name = "Jellyfin"
        valid_redirect_urls = [
          "http://jellyfin.vincent.mahn.ke/*"
        ]
      }
      "photos" = {
        display_name = "Immich"
        valid_redirect_urls = [
          "app.immich:///oauth-callback"
        ]
      }
      "matrix" = {
        display_name = "Matrix"
        valid_redirect_urls = [
          "https://matrix.by.vincent.mahn.ke/_synapse/client/oidc/callback"
        ]
        backchannel_logout_url = "https://matrix.by.vincent.mahn.ke/_synapse/client/oidc/backchannel_logout"
      }
    } : "${replace(key, ".", "-")}-by-vincent" => value
  }
  nodejs = {
    "gamereleases-by-vincent"   = 3000
    "availability-by-vincent"   = 3001
    "fah-break"                 = 3003
    "backup-trigger"            = 3004
    "fitx-fetcher"              = 3005
    "myfitnesspal-fetcher"      = 3006
    "slides-by-vincent"         = 3009
    "wallpapers-by-vincent"     = 3010
    "kiosk-39c3-by-vincent"     = 3011
    "mancala-client-by-vincent" = 3012
  }
}

data "github_user" "current" {
  username = "ViMaSter"
}

module "general" {
  for_each = merge(local.generic, local.subdomains, local.oauth_clients, local.nodejs)
  source   = "./modules/general"
  providers = {
    github = github
  }

  repository_reference = each.key
  user_vimaster        = data.github_user.current.id
}

module "subdomain" {
  for_each = merge(local.subdomains, local.oauth_clients)
  source   = "./modules/subdomain"
  providers = {
    github = github
  }

  repository_name = module.general[each.key].repository_name
  user_vimaster   = data.github_user.current.id
}

module "oauth_client" {
  for_each = local.oauth_clients
  source   = "./modules/oauth_client"
  providers = {
    github   = github
    keycloak = keycloak
  }

  keycloak_realm_id          = data.keycloak_realm.sso_by_vincent_mahn_ke.id
  repository_name            = module.general[each.key].repository_name
  valid_redirect_urls        = lookup(each.value, "valid_redirect_urls", [])
  backchannel_logout_url     = lookup(each.value, "backchannel_logout_url", "")
  pkce_code_challenge_method = lookup(each.value, "pkce_code_challenge_method", "S256")
  web_origins                = lookup(each.value, "web_origins", [])
  display_name               = each.value.display_name
  user_vimaster              = data.github_user.current.id
}

module "nodejs" {
  for_each = local.nodejs
  source   = "./modules/nodejs"
  providers = {
    github = github
  }

  repository_name = module.general[each.key].repository_name
  port            = each.value
  user_vimaster   = data.github_user.current.id
}

locals {
  repo_topics = {
    for repo_key in distinct(concat(
      keys(merge(local.subdomains, local.oauth_clients)),
      keys(local.nodejs)
    )) :
    repo_key => distinct(concat(
      contains(keys(merge(local.subdomains, local.oauth_clients)), repo_key) ? module.subdomain[repo_key].topics : [],
      contains(keys(local.nodejs), repo_key) ? module.nodejs[repo_key].topics : [],
    ))
  }
}

resource "github_repository_topics" "repo_topics" {
  for_each   = local.repo_topics
  repository = module.general[each.key].repository_name
  topics     = each.value
}

resource "uptimekuma_monitor_http" "http_monitor" {
  for_each = {
    for key, value in local.subdomains : replace(key, "-", ".") => value
    if lookup(value, "skip_uptime_check", false) == false
  }
  name             = "${each.key}.mahn.ke - HTTPS [TF]"
  url              = "https://${each.key}.mahn.ke${lookup(each.value, "uptime_path", "")}"
  interval         = 30
  max_retries      = 5
  retry_interval   = 30
  timeout          = 24
  notification_ids = [1]
}
