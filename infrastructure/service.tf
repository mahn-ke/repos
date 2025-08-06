terraform {
  backend "pg" {
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

variable "GITHUB_PAT" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

locals {
  generic = toset([
    ".github",
    "repos",
    "tfstate",
    "resources"
  ])
  subdomains = toset([
    for name in [
      "ttrss",
      "api.uptime",
      "homeassistant",
      "uptime",
      "sso"
    ] : replace("${name}.by.vincent", ".", "-")
  ])
  nodejs = toset([
    "ccc-event-tracker",
    "fah-break"
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

  repository_reference = each.key
  user_vimaster        = data.github_user.current.id
}

module "nodejs" {
  for_each = local.nodejs
  source   = "./modules/nodejs"
  providers = {
    github = github
  }

  repository_reference = each.key
  user_vimaster        = data.github_user.current.id
}








