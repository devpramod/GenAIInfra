# tgi

Helm chart for deploying Hugging Face Text Generation Inference service.

## Installing the Chart

To install the chart, run the following:

```console
cd GenAIInfra/helm-charts/common/tgi
export MODELDIR=/mnt/opea-models
export MODELNAME="Intel/neural-chat-7b-v3-3"
export HFTOKEN="insert-your-huggingface-token-here"
helm dependency update
helm install tgi . --set global.modelUseHostPath=${MODELDIR} --set LLM_MODEL_ID=${MODELNAME} --set global.HF_TOKEN=${HFTOKEN}
# To deploy on Gaudi enabled kubernetes cluster
# helm install tgi . --set global.modelUseHostPath=${MODELDIR} --set LLM_MODEL_ID=${MODELNAME} --set global.HF_TOKEN=${HFTOKEN} --values gaudi-values.yaml
```

By default, the tgi service will downloading the "Intel/neural-chat-7b-v3-3" which is about 54GB.

If you already cached the model locally, you can pass it to container like this example:

MODELDIR=/mnt/opea-models

MODELNAME="/data/models--Intel--neural-chat-7b-v3-3"

## Verify

To verify the installation, run the command `kubectl get pod` to make sure all pods are runinng.

Then run the command `kubectl port-forward svc/tgi 2080:80` to expose the tgi service for access.

Open another terminal and run the following command to verify the service if working:

```console
curl http://localhost:2080/generate \
    -X POST \
    -d '{"inputs":"What is Deep Learning?","parameters":{"max_new_tokens":17, "do_sample": true}}' \
    -H 'Content-Type: application/json'
```

## Values

| Key                     | Type   | Default                              | Description                                                                                                                                                                                                           |
| ----------------------- | ------ | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| LLM_MODEL_ID            | string | `"Intel/neural-chat-7b-v3-3"`        | Models id from https://huggingface.co/, or predownloaded model directory                                                                                                                                              |
| global.HF_TOKEN         | string | `insert-your-huggingface-token-here` | Hugging Face API token                                                                                                                                                                                                |
| global.modelUseHostPath | string | `""`                                 | Cached models directory, tgi will not download if the model is cached here. The host path "modelUseHostPath" will be mounted to container as /data directory. Set this to null/empty will force it to download model. |
| autoscaling.enabled     | bool   | `false`                              | Enable HPA autoscaling for the service deployment based on metrics it provides. See [HPA instructions](../../HPA.md) before enabling!                                                                                 |
| global.monitoring       | bool   | `false`                              | Enable usage metrics for the service. Required for HPA. See [monitoring instructions](../../monitoring.md) before enabling!                                                                                           |
