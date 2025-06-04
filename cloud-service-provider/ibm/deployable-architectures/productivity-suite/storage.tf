# IBM Cloud Storage Configuration
# This file is configured for IBM Cloud File Storage for VPC v2.0

# Create a namespace for storage management
resource "kubernetes_namespace" "storage" {
  count = var.enable_storage_csi_driver ? 1 : 0
  metadata {
    name = "ibm-storage"
  }
  
  lifecycle {
    ignore_changes = [
      metadata[0].labels,
      metadata[0].annotations,
    ]
  }
}

# StorageClass for IBM Cloud File Storage for VPC v2.0
resource "kubernetes_storage_class" "ibm_file_storage" {
  metadata {
    name = "ibm-file-gold-rwx"
  }
  storage_provisioner = "vpc.file.csi.ibm.io"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    "csi.storage.k8s.io/fstype" = "nfs"
    "billingType"               = "hourly"
    "region"                   = var.region
    "zone"                     = var.zone
    "tier"                     = "10iops-tier"
    "tags"                     = "productivity-suite,persistent-storage"
  }
  
  allow_volume_expansion = true
  
  allowed_topologies {
    match_label_expressions {
      key = "topology.kubernetes.io/zone"
      values = [var.zone]
    }
  }
}

# PVC for ChatQnA service
resource "kubernetes_persistent_volume_claim" "chatqna_pvc" {
  metadata {
    name      = "chatqna-storage"
    namespace = "chatqna"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.chatqna_storage_size
      }
    }
    storage_class_name = kubernetes_storage_class.ibm_file_storage.metadata[0].name
  }
  
  depends_on = [module.chatqna]
}

# PVC for ChatHistory service
resource "kubernetes_persistent_volume_claim" "chathistory_pvc" {
  metadata {
    name      = "chathistory-storage"
    namespace = "chathistory"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.chathistory_storage_size
      }
    }
    storage_class_name = kubernetes_storage_class.ibm_file_storage.metadata[0].name
  }
  
  depends_on = [module.chathistory-usvc]
}

# PVC for Prompt service
resource "kubernetes_persistent_volume_claim" "prompt_pvc" {
  metadata {
    name      = "prompt-storage"
    namespace = "prompt"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.prompt_storage_size
      }
    }
    storage_class_name = kubernetes_storage_class.ibm_file_storage.metadata[0].name
  }
  
  depends_on = [module.prompt-usvc]
}

# PVC for Keycloak service
resource "kubernetes_persistent_volume_claim" "keycloak_pvc" {
  metadata {
    name      = "keycloak-storage"
    namespace = "keycloak"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = var.keycloak_storage_size
      }
    }
    storage_class_name = kubernetes_storage_class.ibm_file_storage.metadata[0].name
  }
  
  depends_on = [helm_release.keycloak]
}
