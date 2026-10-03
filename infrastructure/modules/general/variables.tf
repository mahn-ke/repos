variable "repository_reference" {
  description = "Repository reference"
  type        = string
}

variable "user_vimaster" {
  description = "GitHub user ID for ViMaSter"
  type        = string
}

variable "infrastructure_review" {
  description = "Require trusted infrastructure review before merging"
  type        = bool
  default     = false
}