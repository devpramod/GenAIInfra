# productivity-suite-tf-module
Terraform modules for launching Productivity Suite on IBM cloud as a Deployable Architecture


Steps to run:

```
# create a .env file and add variable 'HF_TOKEN' and 'OPENAI_API_KEY' as shown in
# .env.example

# update helm chart dependencies
cd submodules/GenAIInfra/helm-charts 
./update_dependency.sh
helm dependency update chatqna
helm dependency update codegen
helm dependency update docsum

# Apply patch to helm charts to enable remote LLM endpoint connection

# ChatQnA
patch submodules/GenAIInfra/helm-charts/chatqna/values.yaml < patch/chatqna/values.patch
patch submodules/GenAIInfra/helm-charts/chatqna/templates/deployment.yaml < patch/chatqna/deployment.patch
patch submodules/GenAIInfra/helm-charts/chatqna/Chart.yaml < patch/chatqna/chart.patch
rm submodules/GenAIInfra/helm-charts/chatqna/templates/nginx.yaml


# CodeGen
patch submodules/GenAIInfra/helm-charts/codegen/values.yaml < patch/codegen/values.patch
patch submodules/GenAIInfra/helm-charts/codegen/templates/deployment.yaml < patch/codegen/deployment.patch
patch submodules/GenAIInfra/helm-charts/codegen/Chart.yaml < patch/codegen/chart.patch
rm submodules/GenAIInfra/helm-charts/codegen/templates/nginx.yaml

#DocSum
patch submodules/GenAIInfra/helm-charts/docsum/values.yaml < patch/docsum/values.patch
patch submodules/GenAIInfra/helm-charts/docsum/templates/deployment.yaml < patch/docsum/deployment.patch
patch submodules/GenAIInfra/helm-charts/docsum/Chart.yaml < patch/docsum/chart.patch

# Setting up UI

# Build the UI image
cd submodules/immersive-rag-ui
docker build -t immersive-ui:latest .

# Load your local image into Minikube's Docker daemon
minikube image load immersive-ui:latest

# After installing terraform
terraform init
terraform plan
terraform apply

# Run the following in a different terminal to test pods' status
kubectl get pods -A
```