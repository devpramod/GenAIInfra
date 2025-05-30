# Path to kubeconfig for IBM IKS
kubeconfig_file = "~/.kube/ibm-iks-kubeconfig"

# ChatQNA Configuration
chatqna_model_dir = ""
chatqna_helm_repo = "../../../../helm-charts/chatqna"

chatqna_model_name = "ibm-granite/granite-3.1-8b-instruct"
chatqna_embedding_model_name = "BAAI/bge-base-en-v1.5"
chatqna_reranker_model_name = "BAAI/bge-reranker-base"
chatqna_llm_service_host_ip = "https://inference-on-ibm.edgecollaborate.com/granite-3.1-8b-instruct"

# Codegen Configuration
codegen_model_dir = ""
codegen_helm_repo = "../../../../helm-charts/codegen"

codegen_model_name = "meta-llama/Llama-3.1-405B-Instruct"
codegen_llm_service_host_ip = "https://inference-on-ibm.edgecollaborate.com/Llama-3.1-405B-Instruct"

# Docsum Configuration
docsum_model_dir = ""
docsum_helm_repo = "../../../../helm-charts/docsum"

docsum_model_name = "meta-llama/Llama-3.3-70B-Instruct"
docsum_llm_service_host_ip = "https://inference-on-ibm.edgecollaborate.com/Llama-3.3-70B-Instruct"

# Nginx Configuration
nginx_helm_repo = "../../../../helm-charts/common/nginx"

# UI Configuration
ui_helm_repo = "../../../../helm-charts/common/ui"


# Chathistory Configuration
chathistory_helm_repo = "../../../../helm-charts/common/chathistory-usvc"

enable_chathistory_mongodb = true

# Prompt Configuration
prompt_helm_repo = "../../../../helm-charts/common/prompt-usvc"

enable_prompt_mongodb = true

# Feature Flags - ChatQnA
enable_chatqna_vllm    = false
enable_chatqna_ui      = false
enable_chatqna_nginx = false

# Feature Flags - Codegen
enable_codegen_ui      = false
enable_codegen_tgi     = false
enable_codegen_llm-uservice   = false
enable_codegen_nginx   = false

# Feature Flags - Docsum
enable_docsum_tgi     = false
enable_docsum_vllm    = false
enable_docsum_nginx   = false
enable_docsum_ui      = false
enable_docsum_llm-uservice = false
enable_docsum_whisper = false