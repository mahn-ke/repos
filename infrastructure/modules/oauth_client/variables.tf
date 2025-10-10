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
  type        = list
}

variable "display_name" {
  description = "Display name"
  type        = string
}

variable "user_vimaster" {
  description = "GitHub user ID for ViMaSter"
  type        = string
}
