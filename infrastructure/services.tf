locals {
  generic = {
    ".github"            = ".github"
    "repos"              = "repos"
    "resources"          = "resources"
    "storage-management" = "storage-management"
    "hetzner-robot"      = "hetzner-robot"
  }
  subdomains = {
    for name in [
      "tfstate",
      "uptime",
      "cloud",
      "matrix",
      "irc",
      "sso",
      "rustdesk",
      "notifications",
      "logging",
      "gamereleases",
      "paperless",
      "photos",
      "availability",
      "fitness",
      "pretix",
      "rcon",
      "errors",
      "slides",
      "invoices",
      "wallpapers",
      "kiosk.39c3",
      "cccbib",
      "mancala-client"
    ] : replace("${name}.by.vincent", ".", "-") => replace("${name}.by.vincent", ".", "-")
  }
  oauth_clients = {
    for key, value in {
      "ttrss" = {
        display_name               = "Tiny Tiny RSS"
        pkce_code_challenge_method = ""
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
    "rcon-by-vincent"           = 3007
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

  keycloak_realm_id   = data.keycloak_realm.sso_by_vincent_mahn_ke.id
  repository_name     = module.general[each.key].repository_name
  display_name        = each.value.display_name
  valid_redirect_urls = lookup(each.value, "valid_redirect_urls", [])
  user_vimaster       = data.github_user.current.id
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
