# OPEA nginx microservice

Helm chart for deploying OPEA nginx service.

## Using nginx chart

E2E charts for OPEA applications should provide ConfigMap of name `{{ .Release.Name }}-nginx-config` with the required environment variables to configure [OPEA nginx microservice](https://github.com/opea-project/GenAIComps/blob/main/comps/nginx/nginx.conf.template).

## Gateway Mode (Central Router)

The nginx chart can be configured to act as a central gateway/router for OPEA services. This mode provides:

- Service routing to multiple OPEA microservices
- Custom nginx configuration template support
- Health check endpoints
- Optional ingress and monitoring support

### Usage

To use nginx as a central gateway, deploy with the gateway values file:

```bash
helm install nginx . -f gateway-values.yaml
```

### Configuration

The `gateway-values.yaml` file contains:
- Service endpoint definitions for routing
- UI service configuration
- Custom nginx configuration template
- Optional ingress and monitoring settings

### Backward Compatibility

All existing deployments continue to work unchanged. Gateway mode is opt-in and only activated when using `gateway-values.yaml` or explicitly setting `gatewayMode.enabled: true`.
