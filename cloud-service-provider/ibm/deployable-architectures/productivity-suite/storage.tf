# IBM Cloud Storage Configuration
# This file is configured for IBM Cloud File Storage for VPC v2.0
# It will be expanded in Phase 2 for PVC implementation

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

# Each service (keycloak, chatqna, codegen, docsum) will create its own PVC
# in its own namespace using the IBM Cloud File Storage for VPC v2.0
# This basic configuration will be expanded in Phase 2
