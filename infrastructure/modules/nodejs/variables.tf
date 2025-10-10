variable "repository_name" {
  description = "Repository name"
  type        = string
}

variable "port" {
  description = "Host-facing port of service"
  type        = number
}

variable "user_vimaster" {
  description = "GitHub user ID for ViMaSter"
  type        = string
}
