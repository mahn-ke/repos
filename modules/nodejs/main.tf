terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }
}

resource "github_repository_file" "dockerfile" {
  repository          = var.repository_reference
  file                = "app/Dockerfile"
  content             = file("${path.module}/src/Dockerfile")
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}
resource "github_repository_file" "docker_compose" {
  repository          = var.repository_reference
  file                = "docker-compose.yml"
  content             = file("${path.module}/src/docker-compose.yml")
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}
resource "github_repository_file" "package" {
  repository          = var.repository_reference
  file                = "app/package.json"
  content             = replace(file("${path.module}/src/package.json"), "$REPOSITORY", var.repository_reference)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}
resource "github_repository_file" "package_lock" {
  repository          = var.repository_reference
  file                = "app/package-lock.json"
  content             = replace(file("${path.module}/src/package-lock.json"), "$REPOSITORY", var.repository_reference)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_file" "main" {
  repository          = var.repository_reference
  file                = "app/main.js"
  content             = "console.log('Hello, World!');\n"
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}