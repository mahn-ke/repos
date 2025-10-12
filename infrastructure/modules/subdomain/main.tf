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

resource "github_repository_file" "readme" {
  repository          = var.repository_name
  file                = "README.MD"
  content             = replace(replace(file("${path.module}/README.MD"), "$REPOSITORY", var.repository_name), "-by-vincent", "")
  commit_message      = "Managed by Terraform${strcontains(var.repository_name, "repos") ? " [no ci]" : ""}"
  overwrite_on_create = false
}

resource "github_repository_file" "infrastructure-subdomain-tf" {
  repository = var.repository_name
  file       = "infrastructure/subdomain.tf"
  content    = file("${path.module}/infrastructure/subdomain.tf")
}