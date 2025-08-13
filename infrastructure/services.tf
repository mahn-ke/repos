locals {
  generic = toset([
    ".github",
    "repos",
    "resources",
    "storage-management"
  ])
  subdomains = toset([
    for name in [
      "tfstate",
      "ttrss",
      "api.uptime",
      "homeassistant",
      "uptime",
      "sso",
      "cloud",
      "matrix",
      "irc"
    ] : replace("${name}.by.vincent", ".", "-")
  ])
  nodejs = toset([
    "ccc-event-tracker",
    "fah-break",
    "backup-trigger",
    "fitx-fetcher"
  ])
  all_repositories = setunion(local.generic, local.subdomains, local.nodejs)
}

data "github_user" "current" {
  username = "ViMaSter"
}

module "general" {
  for_each = local.all_repositories
  source   = "./modules/general"
  providers = {
    github = github
  }

  repository_reference = each.key
  user_vimaster        = data.github_user.current.id
}

module "subdomain" {
  for_each = local.subdomains
  source   = "./modules/subdomain"
  providers = {
    github = github
  }

  // use module reference, to implicitly wait for repository creation
  repository_name = module.general[each.key].repository_name
  user_vimaster   = data.github_user.current.id
}

module "nodejs" {
  for_each = local.nodejs
  source   = "./modules/nodejs"
  providers = {
    github = github
  }

  // use module reference, to implicitly wait for repository creation
  repository_name = module.general[each.key].repository_name
  user_vimaster   = data.github_user.current.id
}








