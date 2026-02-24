variable "keycloak_realm_id" {
  description = "Keycloak realm ID"
  type        = string
}

variable "repository_name" {
  description = "Repository name"
  type        = string
}

variable "valid_redirect_urls" {
  description = "Extra redirect URLs"
  type        = list(string)
}

variable "backchannel_logout_url" {
  description = "URL that called to inform the client about logouts"
  type        = string
  default     = ""
}

variable "pkce_code_challenge_method" {
  description = "https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/openid_client#pkce_code_challenge_method-1"
  type        = string
  default     = null
}

variable "web_origins" {
  description = "https://registry.terraform.io/providers/keycloak/keycloak/latest/docs/resources/openid_client#pkce_code_challenge_method-1"
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name"
  type        = string
}

variable "user_vimaster" {
  description = "GitHub user ID for ViMaSter"
  type        = string
}
