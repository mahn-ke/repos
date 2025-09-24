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
  valid_redirect_uris = [
    "https://${local.subdomain_label}.by.vincent.mahn.ke/*"
  ]
  root_url              = "https://${local.subdomain_label}.by.vincent.mahn.ke"
  use_refresh_tokens    = false
  standard_flow_enabled = true
}