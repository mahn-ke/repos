terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

resource "github_repository" "repos" {
  name                        = var.repository_reference
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
  repository          = var.repository_reference
  file                = ".github/workflows/deploy.yml"
  content             = file("${path.module}/src/.github/workflows/deploy.yml")
  overwrite_on_create = true
}

resource "github_repository_environment" "production" {
  repository          = var.repository_reference
  environment         = "production"
  prevent_self_review = false
  reviewers {
    users = [var.user_vimaster]
  }
}

resource "github_repository_file" "infrastructure-main-tf" {
  repository = var.repository_reference
  file       = "infrastructure/main.tf"
  content    = replace(file("${path.module}/infrastructure/main.tf"), "$REPOSITORY", var.repository_reference)
}

resource "github_repository_file" "service-main-tf" {
  repository = var.repository_reference
  file       = "service/main.tf"
  content    = replace(file("${path.module}/service/main.tf"), "$REPOSITORY", var.repository_reference)
}