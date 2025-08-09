terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

resource "github_repository_topics" "repos" {
  repository = var.repository_name
  topics     = ["domain"]
}

resource "github_repository_file" "infrastructure-subdomain-tf" {
  repository = var.repository_name
  file       = "infrastructure/subdomain.tf"
  content    = replace(file("${path.module}/infrastructure/subdomain.tf"), "$REPOSITORY", var.repository_name)
}