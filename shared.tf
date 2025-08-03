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
    repo_names = [
        "ttrss",
        "api-uptime",
        "homeassistant",
        "uptime",
        "sso"
    ]
}

resource "github_repository" "repos" {
    for_each          = toset(local.repo_names)
    name              = "${each.value}-by-vincent"
    visibility        = "public"
    auto_init         = false
    license_template  = "gpl-3.0"
    allow_merge_commit = false
    allow_rebase_merge = true
    allow_squash_merge = true
    has_downloads = false
    has_issues = true
    has_projects = false
    has_wiki = false
    merge_commit_title = "PR_TITLE"
    merge_commit_message = "PR_BODY"
    squash_merge_commit_title = "PR_TITLE"
    squash_merge_commit_message = "PR_BODY"
    vulnerability_alerts = true
}

data "github_user" "current" {
  username = "ViMaSter"
}

// add 'production' environment with ViMaSter as reviewer
resource "github_repository_environment" "production" {
  for_each = toset(local.repo_names)
  repository = github_repository.repos[each.key].name
  environment = "production"
  prevent_self_review = false
  reviewers {
    users = [data.github_user.current.id]
  }
}

/*
terraform import 'github_repository_environment.production["ttrss"]' ttrss-by-vincent:production
terraform import 'github_repository_environment.production["api-uptime"]' api-uptime-by-vincent:production
terraform import 'github_repository_environment.production["homeassistant"]' homeassistant-by-vincent:production
terraform import 'github_repository_environment.production["uptime"]' uptime-by-vincent:production
terraform import 'github_repository_environment.production["sso"]' sso-by-vincent:production
*/