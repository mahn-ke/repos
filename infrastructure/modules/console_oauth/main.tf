terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13.0"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.9.0, < 6.0.0"
    }
  }
}

variable "keycloak_realm_id" {
  type = string
}

variable "repository_name" {
  type = string
}

locals {
  consoles = {
    "3ds"  = "3DS"
    "xbox" = "XBOX"
  }
  issuer = "https://sso.by.vincent.mahn.ke/realms/sso.by.vincent.mahn.ke"
  secrets = merge({
    OAUTH_URL = local.issuer
    }, merge([for platform, suffix in local.consoles : {
      "OAUTH_CONSOLE_${suffix}_CLIENT_ID"     = keycloak_openid_client.console[platform].client_id
      "OAUTH_CONSOLE_${suffix}_CLIENT_SECRET" = keycloak_openid_client.console[platform].client_secret
  }]...))
}

resource "keycloak_openid_client" "console" {
  for_each = local.consoles

  realm_id                     = var.keycloak_realm_id
  client_id                    = "highscores-hackertours-${each.key}"
  name                         = "Hackertours highscores (${each.value})"
  enabled                      = true
  access_type                  = "CONFIDENTIAL"
  service_accounts_enabled     = true
  standard_flow_enabled        = false
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false
  full_scope_allowed           = false
  access_token_lifespan        = "3600"
}

resource "github_actions_secret" "console" {
  for_each = toset(concat(["OAUTH_URL"], flatten([
    for suffix in values(local.consoles) : [
      "OAUTH_CONSOLE_${suffix}_CLIENT_ID", "OAUTH_CONSOLE_${suffix}_CLIENT_SECRET"
    ]
  ])))

  repository       = var.repository_name
  secret_name      = each.key
  plaintext_value  = local.secrets[each.key]
  destroy_on_drift = true
}

output "credentials" {
  description = "Per-platform client-credentials configuration for private console config.ini files."
  sensitive   = true
  value = {
    for platform, client in keycloak_openid_client.console : platform => {
      client_id     = client.client_id
      client_secret = client.client_secret
      token_url     = "${local.issuer}/protocol/openid-connect/token"
    }
  }
}
