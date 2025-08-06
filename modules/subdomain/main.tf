terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

resource "github_repository_topics" "repos" {
  repository = var.repository_reference
  topics     = ["domain"]
}