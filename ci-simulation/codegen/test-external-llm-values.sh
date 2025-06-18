#!/bin/bash
# Test script for CodeGen with external-llm-values (failing case)

echo "==========================================="
echo "Testing CodeGen with external-llm-values.yaml"
echo "This should simulate the FAILING CI test"
echo "==========================================="

echo "NOTE: This test expects external LLM configuration:"
echo "  LLM_SERVER_HOST_IP: http://your-llm-server"
echo "  LLM_MODEL: your-model"
echo "  OPENAI_API_KEY: your-api-key"
echo "  LLM_SERVER_PORT: 80"
echo ""
echo "Since these are placeholder values, the test should fail"
echo "with HTTP 500 errors when trying to connect to the external LLM."
echo ""

cd "$(dirname "$0")/../.."
exec ./ci-simulation/helm-chart-test.sh codegen external-llm-values