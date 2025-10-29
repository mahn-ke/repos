locals {
  generic = {
    ".github"            = ".github"
    "repos"              = "repos"
    "resources"          = "resources"
    "storage-management" = "storage-management"
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
      "umap",
      "fitness",
      "office"
    ] : replace("${name}.by.vincent", ".", "-") => replace("${name}.by.vincent", ".", "-")
  }
  oauth_clients = {
    for key, value in {
      "ttrss" = {
        display_name = "Tiny Tiny RSS"
      }
      "containers" = {
        display_name = "Portainer"
      }
      "paperless" = {
        display_name = "Paperless"
      }
      "umap" = {
        display_name = "umap"
      }
      "photos" = {
        display_name = "Immich"
        valid_redirect_urls = [
          "app.immich:///oauth-callback"
        ]
      }
    } : "${replace(key, ".", "-")}-by-vincent" => value
  }
  nodejs = {
    "gamereleases-by-vincent" = 3000
    "availability-by-vincent" = 3001
    "fah-break"               = 3003
    "backup-trigger"          = 3004
    "fitx-fetcher"            = 3005
    "myfitnesspal-fetcher"    = 3006
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
