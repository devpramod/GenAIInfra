# Determine if helm_repo is a local path or remote URI
locals {
  is_remote = can(regex("^([a-zA-Z0-9.-]+)/([a-zA-Z0-9-]+)/([a-zA-Z0-9-]+)$", var.helm_repo))
  repo_parts = local.is_remote ? regex("^([a-zA-Z0-9.-]+)/([a-zA-Z0-9-]+)/([a-zA-Z0-9-]+)$", var.helm_repo) : []
}

resource "helm_release" "chathistory-usvc" {
  name             = "chathistory-usvc"
  chart      = local.is_remote ? local.repo_parts[3] : var.helm_repo
  repository = local.is_remote ? "oci://${local.repo_parts[1]}/${local.repo_parts[2]}" : null
  namespace        = "chathistory"
  create_namespace = true
  timeout          = 600
  
  values = [
    file("${var.helm_repo}/values.yaml")
  ]

  # Chathistory Backend Server
  set {
    name  = "image.repository"
    value = "opea/chathistory-mongo-server"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }

  # MongoDB dependency configuration
  set {
    name  = "mongodb.enabled"
    value = var.mongodb_enabled
  }

  # Global storage class configuration
  set {
    name  = "global.modelStorageClass"
    value = "standard"
  }
}
