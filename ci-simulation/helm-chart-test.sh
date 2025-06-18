#!/bin/bash
# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Local CI Simulation Script for Helm Chart Testing
# This script simulates the CI workflow for helm chart testing across multiple charts

set -e

# Configuration
CHARTS_DIR="helm-charts"

# Default values
CHART_NAME="${1:-chatqna}"  # chatqna, codegen, or docsum
VALUEFILE="${2:-cpu-values}"  # Default to cpu-values, can be overridden
DOCKERHUB="${3:-false}"
TAG="${4:-latest}"
TEST_MODE="${5:-local}"  # local or ci-simulation

# Chart folder
CHART_FOLDER="${CHARTS_DIR}/${CHART_NAME}"

# Generate unique identifiers like CI does
RELEASE_NAME="${CHART_NAME}$(date +%d%H%M%S)"
NAMESPACE="infra-${CHART_NAME}-$(head -c 4 /dev/urandom | xxd -p)"

# Timeouts
ROLLOUT_TIMEOUT_SECONDS="1800s"
TEST_TIMEOUT_SECONDS="900s"
KUBECTL_TIMEOUT_SECONDS="300s"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

function warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

function error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

function info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

function cleanup() {
    log "Starting cleanup..."
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log "Uninstalling helm release: $RELEASE_NAME"
        helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" || true
        
        log "Deleting namespace: $NAMESPACE"
        if ! kubectl delete ns "$NAMESPACE" --timeout="$KUBECTL_TIMEOUT_SECONDS"; then
            warn "Normal namespace deletion failed, forcing deletion..."
            kubectl delete pods --namespace "$NAMESPACE" --force --grace-period=0 --all || true
            kubectl delete ns "$NAMESPACE" --force --grace-period=0 --timeout="$KUBECTL_TIMEOUT_SECONDS" || true
        fi
    fi
}

function check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -d "$CHARTS_DIR" ]]; then
        error "Charts directory '$CHARTS_DIR' not found. Please run this script from the GenAIInfra root directory."
        exit 1
    fi
    
    # Check if chart exists
    if [[ ! -d "$CHART_FOLDER" ]]; then
        error "Chart folder '$CHART_FOLDER' not found."
        exit 1
    fi
    
    # Check if values file exists
    if [[ ! -f "$CHART_FOLDER/${VALUEFILE}.yaml" ]]; then
        error "Values file '$CHART_FOLDER/${VALUEFILE}.yaml' not found."
        exit 1
    fi
    
    # Check required tools
    for tool in helm kubectl; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check if kubectl is connected to a cluster
    if ! kubectl cluster-info &>/dev/null; then
        error "kubectl is not connected to a Kubernetes cluster"
        exit 1
    fi
    
    log "Prerequisites check passed ✓"
}

function prepare_charts() {
    log "Preparing charts for testing..."
    
    pushd "$CHARTS_DIR" > /dev/null
    
    if [[ "$DOCKERHUB" == "true" ]]; then
        log "Using released docker images from DockerHub"
    else
        log "Using internal docker registry (simulating CI environment)"
        if [[ -n "${OPEA_IMAGE_REPO:-}" ]]; then
            log "Updating image repositories with prefix: $OPEA_IMAGE_REPO"
            find . -name '*values.yaml' -type f -exec sed -i.bak "s#repository: opea/#repository: ${OPEA_IMAGE_REPO}opea/#g" {} \;
        else
            warn "OPEA_IMAGE_REPO not set, using default opea/ prefix"
        fi
    fi
    
    # Set OPEA image tag
    log "Setting image tag to: $TAG"
    find . -name '*values.yaml' -type f -exec sed -i.bak "s#tag: \"latest\"#tag: \"$TAG\"#g" {} \;
    
    popd > /dev/null
}

function update_dependencies() {
    log "Updating chart dependencies..."
    
    # Update dependencies using the same script as CI
    if [[ -f "helm-charts/scripts/update_dependency.sh" ]]; then
        bash helm-charts/scripts/update_dependency.sh
    else
        warn "update_dependency.sh not found, skipping dependency updates"
    fi
    
    helm dependency update "$CHART_FOLDER"
}

function install_chart() {
    log "Installing chart: $CHART_NAME with values: ${VALUEFILE}.yaml"
    log "Release name: $RELEASE_NAME"
    log "Namespace: $NAMESPACE"
    
    # Prepare helm install command similar to user's format
    local helm_cmd="helm install $RELEASE_NAME $CHART_FOLDER --create-namespace --namespace $NAMESPACE --wait --timeout $ROLLOUT_TIMEOUT_SECONDS"
    
    # Core settings that user specified
    if [[ -n "${HFTOKEN:-}" ]]; then
        helm_cmd="$helm_cmd --set global.HUGGINGFACEHUB_API_TOKEN=$HFTOKEN"
    else
        warn "HFTOKEN not set, using placeholder"
        helm_cmd="$helm_cmd --set global.HUGGINGFACEHUB_API_TOKEN=placeholder"
    fi
    
    # Set OpenAI API key for external LLM configurations
    if [[ -n "${OPENAI_API_KEY:-}" ]]; then
        helm_cmd="$helm_cmd --set externalLLM.OPENAI_API_KEY=$OPENAI_API_KEY"
    fi
    
    # Set model mount path
    local model_dir="${MODELDIR}"
    if [[ -n "$model_dir" ]]; then
        helm_cmd="$helm_cmd --set global.modelUseHostPath=$model_dir"
    fi
    
    # Set model name based on chart and configuration
    local model_name="${MODELNAME:-meta-llama/Meta-Llama-3-8B-Instruct}"
    if [[ "$VALUEFILE" == "cpu-values" ]] || [[ "$VALUEFILE" == *"cpu"* ]]; then
        case "$CHART_NAME" in
            "chatqna")
                helm_cmd="$helm_cmd --set vllm.LLM_MODEL_ID=$model_name"
                ;;
            "codegen")
                helm_cmd="$helm_cmd --set vllm.LLM_MODEL_ID=$model_name"
                ;;
            "docsum")
                helm_cmd="$helm_cmd --set vllm.LLM_MODEL_ID=$model_name"
                ;;
        esac
    fi
    
    # Add values file
    helm_cmd="$helm_cmd --values $CHART_FOLDER/${VALUEFILE}.yaml"
    
    info "Executing: $helm_cmd"
    
    if ! eval "$helm_cmd"; then
        error "Failed to install chart $CHART_NAME"
        dump_pods_status
        return 1
    fi
    
    log "Chart installation completed successfully ✓"
}

function run_tests() {
    log "Running helm tests..."
    
    if ! helm test -n "$NAMESPACE" "$RELEASE_NAME" --logs --timeout "$TEST_TIMEOUT_SECONDS"; then
        error "Chart $CHART_NAME test failed"
        dump_all_pod_logs
        return 1
    fi
    
    log "Chart $CHART_NAME test succeeded ✓"
}

function dump_pods_status() {
    log "Dumping pod status for namespace: $NAMESPACE"
    if [[ -f ".github/workflows/scripts/e2e/chart_test.sh" ]]; then
        bash .github/workflows/scripts/e2e/chart_test.sh dump_pods_status "$NAMESPACE"
    else
        kubectl get pods -n "$NAMESPACE" -o wide
    fi
}

function dump_all_pod_logs() {
    log "Dumping all pod logs for namespace: $NAMESPACE"
    if [[ -f ".github/workflows/scripts/e2e/chart_test.sh" ]]; then
        bash .github/workflows/scripts/e2e/chart_test.sh dump_all_pod_logs "$NAMESPACE"
    else
        kubectl get pods -n "$NAMESPACE" -o wide
        pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
        for pod_name in $pods; do
            echo "=== Pod: $pod_name ==="
            kubectl describe pod "$pod_name" -n "$NAMESPACE"
            echo "=== Logs: $pod_name ==="
            kubectl logs "$pod_name" -n "$NAMESPACE" --all-containers --prefix=true || true
        done
    fi
}

function main() {
    log "Starting local CI simulation for chart: $CHART_NAME"
    log "Values file: ${VALUEFILE}.yaml"
    log "Mode: $TEST_MODE"
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run the simulation
    check_prerequisites
    prepare_charts
    update_dependencies
    install_chart
    run_tests
    
    log "Local CI simulation completed successfully! ✅"
}

function usage() {
    echo "Usage: $0 [CHART_NAME] [VALUEFILE] [DOCKERHUB] [TAG] [MODE]"
    echo ""
    echo "Arguments:"
    echo "  CHART_NAME  Chart to test: chatqna, codegen, or docsum (default: chatqna)"
    echo "  VALUEFILE   Values file to use (default: cpu-values)"
    echo "  DOCKERHUB   Use DockerHub images (default: false)"
    echo "  TAG         Image tag to use (default: latest)"
    echo "  MODE        Test mode (default: local)"
    echo ""
    echo "Examples:"
    echo "  $0 chatqna                           # Test chatqna with cpu-values.yaml"
    echo "  $0 chatqna external-llm-values       # Test chatqna with external-llm-values.yaml"
    echo "  $0 codegen cpu-values                # Test codegen with cpu-values.yaml"
    echo "  $0 docsum external-llm-values        # Test docsum with external-llm-values.yaml"
    echo ""
    echo "Environment variables:"
    echo "  OPEA_IMAGE_REPO    Docker registry prefix (e.g., 'registry.local/')"
    echo "  HFTOKEN            Hugging Face token (required)"
    echo "  MODELDIR           Local path for model storage (empty = ephemeral storage)"
    echo "  MODELNAME          Model name (default: meta-llama/Meta-Llama-3-8B-Instruct)"
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

# Run main function
main