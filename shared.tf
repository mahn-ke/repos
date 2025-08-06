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

provider "github" {
  owner = "mahn-ke"
  token = var.GITHUB_PAT
}

locals {
  subdomains = [
    "ttrss",
    "api.uptime",
    "homeassistant",
    "uptime",
    "sso"
  ]
  repos = [
    ".github",
    "repos",
    "tfstate",
    "resources",
    "ccc-event-tracker",
    "fah-break"
  ]
  repositories = merge(
    { for r in local.repos : r => { tags = [] } },
    { for s in local.subdomains : "${replace(s, ".", "-")}-by-vincent" => { tags = ["domain"] } }
  )
}

resource "github_repository" "repos" {
  for_each                    = local.repositories
  name                        = each.key
  visibility                  = "public"
  auto_init                   = false
  license_template            = "gpl-3.0"
  allow_merge_commit          = false
  allow_rebase_merge          = true
  allow_squash_merge          = true
  has_downloads               = false
  has_issues                  = true
  has_projects                = false
  has_wiki                    = false
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "PR_BODY"
  vulnerability_alerts        = true
}

resource "github_repository_file" "workflow_deploy" {
  for_each                    = local.repositories
  repository = github_repository.repos[each.key].name
  file       = ".github/workflows/deploy.yml"
  content    = file("${path.module}/repository_template/.github/workflows/deploy.yml")
  overwrite_on_create = true
}

resource "github_repository_topics" "repos" {
  for_each   = local.repositories
  repository = github_repository.repos[each.key].name
  topics     = each.value.tags
}

data "github_user" "current" {
  username = "ViMaSter"
}

resource "github_repository_environment" "production" {
  for_each            = local.repositories
  repository          = github_repository.repos[each.key].name
  environment         = "production"
  prevent_self_review = false
  reviewers {
    users = [data.github_user.current.id]
  }
}
