variable "helm_repo" {
  description = "Path to the Prompt Helm chart"
  type        = string
}

variable "mongodb_enabled" {
  description = "Enable MongoDB dependency"
  type        = bool
  default     = true
}
