#!/bin/bash
# Test script for ChatQnA with cpu-values (successful case)

echo "==========================================="
echo "Testing ChatQnA with cpu-values.yaml"
echo "This should simulate the SUCCESSFUL CI test"
echo "==========================================="

cd "$(dirname "$0")/../.."
exec ./ci-simulation/helm-chart-test.sh chatqna cpu-values