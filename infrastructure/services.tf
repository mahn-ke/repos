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
      "api.uptime",
      "homeassistant",
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
      "availability"
    ] : replace("${name}.by.vincent", ".", "-") => replace("${name}.by.vincent", ".", "-")
  }
  oauth_clients = {
    for key, value in {
      "ttrss"      = "Tiny Tiny RSS"
      "containers" = "Portainer"
      "paperless"  = "Paperless"
      "photos"     = "Immich"
    } : "${replace(key, ".", "-")}-by-vincent" => value
  }
  nodejs = {
    "ccc-event-tracker"       = "ccc-event-tracker"
    "fah-break"               = "fah-break"
    "backup-trigger"          = "backup-trigger"
    "fitx-fetcher"            = "fitx-fetcher"
    "myfitnesspal-fetcher"    = "myfitnesspal-fetcher"
    "gamereleases-by-vincent" = "gamereleases-by-vincent"
    "availability-by-vincent" = "availability-by-vincent"
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

  keycloak_realm_id = data.keycloak_realm.sso_by_vincent_mahn_ke.id
  repository_name   = module.general[each.key].repository_name
  display_name      = each.value
  user_vimaster     = data.github_user.current.id
}

module "nodejs" {
  for_each = local.nodejs
  source   = "./modules/nodejs"
  providers = {
    github = github
  }

  repository_name = module.general[each.key].repository_name
  user_vimaster   = data.github_user.current.id
}
