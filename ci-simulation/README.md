# CI Simulation for Helm Chart Testing

This directory contains scripts to simulate the GitHub Actions CI workflow locally for debugging chart testing issues across multiple OPEA charts.

## Problem Description

The CI is failing for the new `external-llm-values.yaml` files while passing for `cpu-values.yaml` files. The difference is:

- **cpu-values.yaml**: Uses internal services (VLLM/TGI) (✅ passing)
- **external-llm-values.yaml**: Uses external OpenAI-compatible LLM service (❌ failing)

## Supported Charts

- **ChatQnA** - Question answering with retrieval
- **CodeGen** - Code generation
- **DocSum** - Document summarization

## Directory Structure

```
ci-simulation/
├── README.md                     # This file
├── helm-chart-test.sh            # Main simulation script
├── chatqna/
│   ├── test-cpu-values.sh        # Test ChatQnA with cpu-values
│   └── test-external-llm-values.sh # Test ChatQnA with external-llm-values
├── codegen/
│   ├── test-cpu-values.sh        # Test CodeGen with cpu-values
│   └── test-external-llm-values.sh # Test CodeGen with external-llm-values
└── docsum/
    ├── test-cpu-values.sh        # Test DocSum with cpu-values
    └── test-external-llm-values.sh # Test DocSum with external-llm-values
```

## Prerequisites

1. **Kubernetes cluster** - You need access to a running Kubernetes cluster
2. **helm** - Helm 3.x installed
3. **kubectl** - Configured to connect to your cluster
4. **Docker registry access** - For pulling OPEA images

## Environment Setup

Set these environment variables to match your typical helm install format:

```bash
# Required: Hugging Face token
export HFTOKEN="your-huggingface-token"

# Required: Model directory (local path for model storage)
export MODELDIR=""

# Optional: Model name (default: meta-llama/Meta-Llama-3-8B-Instruct)
export MODELNAME="meta-llama/Meta-Llama-3-8B-Instruct"

# Optional: Docker registry prefix for OPEA images
export OPEA_IMAGE_REPO="your-registry.com/"
```

## Usage

### Quick Testing (Recommended)

```bash
# Test successful cases
./chatqna/test-cpu-values.sh
./codegen/test-cpu-values.sh
./docsum/test-cpu-values.sh

# Test failing cases
./chatqna/test-external-llm-values.sh
./codegen/test-external-llm-values.sh
./docsum/test-external-llm-values.sh
```

### Manual Testing

```bash
# Basic usage
./helm-chart-test.sh [CHART_NAME] [VALUEFILE] [DOCKERHUB] [TAG] [MODE]

# Examples:
./helm-chart-test.sh chatqna cpu-values              # Test chatqna with cpu-values
./helm-chart-test.sh chatqna external-llm-values     # Test chatqna with external-llm-values
./helm-chart-test.sh codegen cpu-values              # Test codegen with cpu-values
./helm-chart-test.sh docsum external-llm-values      # Test docsum with external-llm-values
```

## Helm Install Format

The script uses your standard helm install format:

```bash
helm install chatqna chatqna \
  --set global.HUGGINGFACEHUB_API_TOKEN=${HFTOKEN} \
  --set global.modelUseHostPath=${MODELDIR} \
  --set vllm.LLM_MODEL_ID=${MODELNAME} \
  --values helm-charts/chatqna/cpu-values.yaml
```

**Notable differences from CI:**
- ❌ Removed `GOOGLE_CSE_ID` and `GOOGLE_API_KEY` (not used)
- ✅ Added proper model configuration with `vllm.LLM_MODEL_ID`
- ✅ Uses your standard environment variables (`HFTOKEN`, `MODELDIR`, `MODELNAME`)

## Expected Behavior

### CPU Values Tests (Should Pass)
- Deploys internal LLM services (VLLM/TGI)
- All services should start successfully
- Helm tests should pass
- LLM requests are handled by internal services

### External LLM Values Tests (Currently Failing)
- Disables internal LLM services (vllm, tgi, llm-uservice)
- Configures charts to use external LLM endpoint
- **Expected failure point**: HTTP 500 errors when trying to connect to placeholder LLM endpoint
- The test pod will fail with "curl: (22) The requested URL returned error: 500"

## Understanding the CI Failures

All external-llm-values.yaml files contain placeholder values:
```yaml
externalLLM:
  enabled: true
  LLM_SERVER_HOST_IP: "http://your-llm-server"  # ← Placeholder
  LLM_MODEL: "your-model"                       # ← Placeholder  
  OPENAI_API_KEY: "your-api-key"               # ← Placeholder
  LLM_SERVER_PORT: "80"
```

In CI, these placeholders cause the services to fail when trying to connect to the non-existent LLM server.

## Debugging Steps

1. **Run a failing test locally**:
   ```bash
   ./chatqna/test-external-llm-values.sh
   ```

2. **Check pod logs** (the script will dump them automatically on failure):
   - Look for the main service pod logs (chatqna, codegen, docsum)
   - Check for HTTP connection errors
   - Verify which service is failing to connect

3. **Compare with successful test**:
   ```bash
   ./chatqna/test-cpu-values.sh
   ```

4. **Manual inspection**:
   ```bash
   # After a failed test, check the namespace (it will be printed in logs)
   kubectl get pods -n infra-<chart>-XXXXXX
   kubectl logs <failing-pod> -n infra-<chart>-XXXXXX
   ```

## Next Steps for Fixing

1. **For CI**: 
   - Provide real external LLM credentials as secrets
   - Or set up a mock OpenAI-compatible service for testing
   - Or modify tests to skip external LLM validation when credentials are placeholders

2. **For local testing**: 
   - Set up a local OpenAI-compatible LLM server (like vLLM with OpenAI API)
   - Or use real external LLM credentials

3. **Alternative**: 
   - Modify the helm tests to detect placeholder values and skip external LLM tests
   - Add conditional logic in the test pods

## Cleanup

The script automatically cleans up resources on exit, but if something goes wrong:

```bash
# List all test namespaces
kubectl get namespaces | grep infra-

# Delete specific namespace
kubectl delete namespace infra-<chart>-XXXXXX
```

## Troubleshooting

### Common Issues

1. **"kubectl is not connected to a Kubernetes cluster"**
   - Ensure your kubeconfig is properly configured
   - Test with: `kubectl cluster-info`

2. **"Charts directory not found"**
   - Run the script from the GenAIInfra root directory

3. **"HFTOKEN not set"**
   - Set the environment variable: `export HFTOKEN="your-token"`
   - This is required for model downloads

4. **Image pull errors**
   - Check if your cluster can access the OPEA registry
   - Try setting `DOCKERHUB=true` in the script call

5. **Timeout errors**
   - Increase timeout values in the script if your cluster is slow
   - Check if nodes have sufficient resources (CPU, memory)

### Getting Help

- Check the pod logs dumped by the script
- Use `kubectl describe pod <podname>` for detailed pod information
- Verify your Kubernetes cluster has sufficient resources
- Ensure model files are available in `$MODELDIR`