# VisualQnA

Helm chart for deploying VisualQnA service. VisualQnA depends on the following services:

- [lvm-uservice](../common/lvm-uservice/README.md)
- [vllm](../common/vllm/README.md)

## Installing the Chart

To install the chart, run the following:

```console
cd GenAIInfra/helm-charts/
scripts/update_dependency.sh
helm dependency update visualqna
export HFTOKEN="insert-your-huggingface-token-here"
export MODELDIR="/mnt/opea-models"
# To use CPU with vLLM
helm install visualqna visualqna --set global.HF_TOKEN=${HFTOKEN} --set global.modelUseHostPath=${MODELDIR}
# To use Gaudi with vLLM
# helm install visualqna visualqna --set global.HF_TOKEN=${HFTOKEN} --set global.modelUseHostPath=${MODELDIR} -f visualqna/gaudi-values.yaml

```

### IMPORTANT NOTE

1. Make sure your `MODELDIR` exists on the node where your workload is scheduled so you can cache the downloaded model for next time use. Otherwise, set `global.modelUseHostPath` to 'null' if you don't want to cache the model.

## Verify

To verify the installation, run the command `kubectl get pod` to make sure all pods are running.

Curl command and UI are the two options that can be leveraged to verify the result.

### Verify the workload through curl command

Run the command `kubectl port-forward svc/visualqna 8888:8888` to expose the service for access.

Open another terminal and run the following command to verify the service if working:

```console
curl http://localhost:8888/v1/visualqna \
    -H "Content-Type: application/json" \
    -d '{"messages": [{"role": "user", "content": [{"type": "text","text": "What is in this image?"}, {"type": "image_url", "image_url": {"url": "https://www.ilankelman.org/stopsigns/australia.jpg"}}]}], "max_tokens": 300}'

```

### Verify the workload through UI

The UI has already been installed via the Helm chart. To access it, use the external IP of one your Kubernetes node along with the NGINX port. You can find the NGINX port using the following command:

```bash
export port=$(kubectl get service visualqna-nginx --output='jsonpath={.spec.ports[0].nodePort}')
echo $port
```

Open a browser to access `http://<k8s-node-ip-address>:${port}` to play with the VisualQnA workload.

## Values

| Key               | Type   | Default                               | Description                                                                            |
| ----------------- | ------ | ------------------------------------- | -------------------------------------------------------------------------------------- |
| image.repository  | string | `"opea/visualqna"`                    |                                                                                        |
| service.port      | string | `"8888"`                              |                                                                                        |
| vllm.LLM_MODEL_ID | string | `"llava-hf/llava-v1.6-mistral-7b-hf"` | Models id from https://huggingface.co/, or predownloaded model directory               |
| global.monitoring | bool   | `false`                               | Enable usage metrics for the service components. See ../monitoring.md before enabling! |
