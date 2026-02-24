terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.4.0"
    }
  }
}

locals {
  subdomain_label = replace(replace(basename(var.repository_name), "-by-vincent", ""), "-", ".")
}

resource "random_uuid" "uuid" {
}

resource "keycloak_openid_client" "openid_client" {
  realm_id  = var.keycloak_realm_id
  client_id = "${local.subdomain_label}-${random_uuid.uuid.result}"

  name    = var.display_name
  enabled = true

  access_type = "CONFIDENTIAL"
  valid_redirect_uris = concat(
    ["https://${local.subdomain_label}.by.vincent.mahn.ke/*"],
    var.valid_redirect_urls
  )
  always_display_in_console  = true
  root_url                   = "https://${local.subdomain_label}.by.vincent.mahn.ke"
  base_url                   = "https://${local.subdomain_label}.by.vincent.mahn.ke"
  use_refresh_tokens         = false
  standard_flow_enabled      = true
  backchannel_logout_url     = var.backchannel_logout_url
  pkce_code_challenge_method = var.pkce_code_challenge_method
  web_origins                = var.web_origins
}


resource "github_actions_secret" "oauth_name" {
  repository      = var.repository_name
  secret_name     = "OAUTH_NAME"
  plaintext_value = "Keycloak"
}

resource "github_codespaces_secret" "oauth_name" {
  repository      = var.repository_name
  secret_name     = "OAUTH_NAME"
  plaintext_value = "Keycloak"
}

resource "github_dependabot_secret" "oauth_name" {
  repository      = var.repository_name
  secret_name     = "OAUTH_NAME"
  plaintext_value = "Keycloak"
}

resource "github_actions_secret" "oauth_url" {
  repository      = var.repository_name
  secret_name     = "OAUTH_URL"
  plaintext_value = "https://sso.by.vincent.mahn.ke/realms/sso.by.vincent.mahn.ke"
}

resource "github_codespaces_secret" "oauth_url" {
  repository      = var.repository_name
  secret_name     = "OAUTH_URL"
  plaintext_value = "https://sso.by.vincent.mahn.ke/realms/sso.by.vincent.mahn.ke"
}

resource "github_dependabot_secret" "oauth_url" {
  repository      = var.repository_name
  secret_name     = "OAUTH_URL"
  plaintext_value = "https://sso.by.vincent.mahn.ke/realms/sso.by.vincent.mahn.ke"
}

resource "github_actions_secret" "oauth_client_id" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_ID"
  plaintext_value = keycloak_openid_client.openid_client.client_id
}

resource "github_codespaces_secret" "oauth_client_id" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_ID"
  plaintext_value = keycloak_openid_client.openid_client.client_id
}

resource "github_dependabot_secret" "oauth_client_id" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_ID"
  plaintext_value = keycloak_openid_client.openid_client.client_id
}

resource "github_actions_secret" "oauth_client_secret" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_SECRET"
  plaintext_value = keycloak_openid_client.openid_client.client_secret
}

resource "github_codespaces_secret" "oauth_client_secret" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_SECRET"
  plaintext_value = keycloak_openid_client.openid_client.client_secret
}

resource "github_dependabot_secret" "oauth_client_secret" {
  repository      = var.repository_name
  secret_name     = "OAUTH_CLIENT_SECRET"
  plaintext_value = keycloak_openid_client.openid_client.client_secret
}
