# ChatQnA Module
module "chatqna" {
  source = "./modules/chatqna"

  hf_token        = local.hf_token
  openai_api_key = local.openai_api_key
  model_dir       = var.chatqna_model_dir
  helm_repo = var.chatqna_helm_repo
  
  # ChatQNA specific model names
  model_name          = var.chatqna_model_name
  embedding_model_name = var.chatqna_embedding_model_name
  reranker_model_name = var.chatqna_reranker_model_name

  # Model Endpoint for ChatQnA
  llm_service_host_ip = var.chatqna_llm_service_host_ip
  
  # Feature flags
  enable_vllm            = var.enable_chatqna_vllm
  enable_ui       = var.enable_chatqna_ui
  enable_nginx = var.enable_chatqna_nginx
}

# Codegen Module
module "codegen" {
  source = "./modules/codegen"

  hf_token        = local.hf_token
  openai_api_key = local.openai_api_key
  model_dir       = var.codegen_model_dir
  helm_repo = var.codegen_helm_repo
  model_name      = var.codegen_model_name

  # Model Endpoint for CodeGen
  llm_service_host_ip = var.codegen_llm_service_host_ip

  # Feature flags
  enable_ui    = var.enable_codegen_ui
  enable_tgi   = var.enable_codegen_tgi
  enable_llm-uservice = var.enable_codegen_llm-uservice
  enable_nginx = var.enable_codegen_nginx
}

# Docsum Module
module "docsum" {
  source = "./modules/docsum"

  hf_token        = local.hf_token
  openai_api_key = local.openai_api_key
  model_dir       = var.docsum_model_dir
  helm_repo = var.docsum_helm_repo
  model_name      = var.docsum_model_name

  # Model Endpoint for DocSum
  llm_service_host_ip = var.docsum_llm_service_host_ip

  # Feature flags
  enable_tgi   = var.enable_docsum_tgi
  enable_vllm  = var.enable_docsum_vllm
  enable_nginx = var.enable_docsum_nginx
  enable_ui    = var.enable_docsum_ui
  enable_llm-uservice = var.enable_docsum_llm-uservice
  enable_whisper = var.enable_docsum_whisper
}

# Chathistory Microservice Module
module "chathistory-usvc" {
  source = "./modules/chathistory-usvc"

  helm_repo = var.chathistory_helm_repo
  mongodb_enabled = var.enable_chathistory_mongodb
}

# Prompt Microservice Module
module "prompt-usvc" {
  source = "./modules/prompt-usvc"

  helm_repo = var.prompt_helm_repo
  mongodb_enabled = var.enable_prompt_mongodb
}


# Keycloak Helm Release
resource "helm_release" "keycloak" {
  name       = "keycloak"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "keycloak"
  namespace  = "keycloak"
  create_namespace = true
  version          = "15.0.0"
  timeout          = 720

  set {
    name  = "auth.adminUser"
    value = "admin"
  }
  
  set {
    name  = "auth.adminPassword"
    value = "admin"
  }

  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.primary.persistence.enabled"
    value = "false"
  }

  # Use LoadBalancer
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "service.ports.http"
    value = "8080"
  }
}

# Data sources
data "kubernetes_service" "keycloak" {
  depends_on = [helm_release.keycloak]
  metadata {
    name      = "keycloak"
    namespace = "keycloak"
  }
}

data "kubernetes_service" "ui" {
  depends_on = [helm_release.ui]
  metadata {
    name      = "ui"
    namespace = "ui"
  }
}


# UI Helm Release
resource "helm_release" "ui" {
  name             = "ui"
  chart            = var.ui_helm_repo
  namespace        = "ui"
  create_namespace = true
  timeout          = 600
  
  # Ensure the UI is deployed before updating nginx
  # (if you're using both in the same Terraform configuration)
  # Use the ui_values.yaml file from helm_values
  values = [
    file("${path.root}/helm_values/ui_values.yaml")
  ]
  
  set {
    name  = "image.repository"
    value = "us.icr.io/ibm-opea-terraform/immersive-ui"
  }
  set {
    name  = "image.tag"
    value = "ibm"
  }
  set {
    name  = "imagePullSecrets[0].name"
    value = "regcred"
  }
  set {
    name  = "image.pullPolicy"
    value = "Always"
  }
  set {
    name  = "global.APP_KEYCLOAK_SERVICE_ENDPOINT"
    value = "http://${coalesce(
      data.kubernetes_service.keycloak.status[0].load_balancer[0].ingress[0].ip,
      data.kubernetes_service.keycloak.status[0].load_balancer[0].ingress[0].hostname
    )}:8080"
  }
  
  # Ensure the UI is deployed before updating nginx
  # (if you're using both in the same Terraform configuration)
  depends_on = [resource.helm_release.keycloak]
}

# Nginx Helm Release (Central Gateway using common nginx chart)
resource "helm_release" "nginx" {
  name             = "nginx"
  chart            = var.nginx_helm_repo
  namespace        = "nginx"
  create_namespace = true
  timeout          = 600

  # Use our custom gateway values for productivity suite
  values = [
    file("${path.root}/helm_values/nginx_gateway_values.yaml")
  ]

  # Override service type to LoadBalancer for external access
  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  # Ensure dependencies are deployed first
  depends_on = [
    helm_release.ui,
    module.chatqna,
    module.codegen,
    module.docsum,
    module.chathistory-usvc,
    module.prompt-usvc
  ]
}