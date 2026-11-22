# OAuth2 client of wger's own OIDC provider (allauth.idp.oidc), so another service can read a
# user's wger data after a one-click login (wger itself logs in through Keycloak).
#
# There is no wger Terraform provider and wger has no API for its OIDC clients, so Terraform only
# creates and distributes the credentials:
#   - the provider's signing key (wger keeps the provider switched off without one) and the client
#     definition go to the wger repository, whose deploy registers the client idempotently;
#   - the client id/secret go to the consuming repository.

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
  }
}

variable "wger_repository_name" {
  description = "Repository deploying wger; receives IDP_OIDC_PRIVATE_KEY and WGER_OIDC_CLIENTS."
  type        = string
}

variable "client_repository_name" {
  description = "Repository of the OAuth client; receives WGER_OAUTH_CLIENT_ID and WGER_OAUTH_CLIENT_SECRET."
  type        = string
}

variable "client_id" {
  description = "Readable, stable client id."
  type        = string
}

variable "client_name" {
  description = "Name shown on wger's consent screen."
  type        = string
}

variable "redirect_uris" {
  description = "Exact callback URLs (wger does not allow wildcards here)."
  type        = list(string)
}

variable "scopes" {
  description = "Scopes the client may request."
  type        = list(string)
  default     = ["api:read"]
}

resource "tls_private_key" "idp_signing" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "random_password" "client_secret" {
  length  = 48
  special = false
}

locals {
  wger_secrets = {
    # wger reads "\n" in the environment as newlines (env.str(..., multiline=True)).
    IDP_OIDC_PRIVATE_KEY = replace(trimspace(tls_private_key.idp_signing.private_key_pem_pkcs8), "\n", "\\n")
    WGER_OIDC_CLIENTS = jsonencode([{
      id            = var.client_id
      name          = var.client_name
      secret        = random_password.client_secret.result
      redirect_uris = var.redirect_uris
      scopes        = var.scopes
    }])
  }
  client_secrets = {
    WGER_OAUTH_CLIENT_ID     = var.client_id
    WGER_OAUTH_CLIENT_SECRET = random_password.client_secret.result
  }
}

resource "github_actions_secret" "wger" {
  for_each = toset(["IDP_OIDC_PRIVATE_KEY", "WGER_OIDC_CLIENTS"])

  repository      = var.wger_repository_name
  secret_name     = each.key
  plaintext_value = local.wger_secrets[each.key]
}

resource "github_actions_secret" "client" {
  for_each = toset(["WGER_OAUTH_CLIENT_ID", "WGER_OAUTH_CLIENT_SECRET"])

  repository      = var.client_repository_name
  secret_name     = each.key
  plaintext_value = local.client_secrets[each.key]
}

output "client_credentials" {
  description = "For local development (.envrc); never publish."
  sensitive   = true
  value = {
    client_id     = var.client_id
    client_secret = random_password.client_secret.result
  }
}
