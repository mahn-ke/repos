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
  topics     = ["nodejs"]
}

resource "github_repository_file" "dockerfile" {
  repository          = var.repository_name
  file                = "app/Dockerfile"
  content             = file("${path.module}/src/Dockerfile")
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_file" "docker_compose" {
  repository          = var.repository_name
  file                = "docker-compose.yml"
  content             = replace(replace(file("${path.module}/src/docker-compose.yml"), "$REPOSITORY", var.repository_name), "$PORT", var.port)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_file" "package" {
  repository          = var.repository_name
  file                = "app/package.json"
  content             = replace(file("${path.module}/src/package.json"), "$REPOSITORY", var.repository_name)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_file" "package_lock" {
  repository          = var.repository_name
  file                = "app/package-lock.json"
  content             = replace(file("${path.module}/src/package-lock.json"), "$REPOSITORY", var.repository_name)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}

resource "github_repository_file" "main" {
  repository          = var.repository_name
  file                = "app/main.js"
  content             = replace(file("${path.module}/src/main.js"), "$REPOSITORY", var.repository_name)
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}


resource "github_repository_file" "gitignore" {
  repository          = var.repository_name
  file                = "app/.gitignore"
  content             = file("${path.module}/src/.gitignore")
  overwrite_on_create = false
  lifecycle {
    ignore_changes = [content]
  }
}
