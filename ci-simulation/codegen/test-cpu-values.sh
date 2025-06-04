#!/bin/bash
# Test script for CodeGen with cpu-values (successful case)

echo "==========================================="
echo "Testing CodeGen with cpu-values.yaml"
echo "This should simulate the SUCCESSFUL CI test"
echo "==========================================="

cd "$(dirname "$0")/../.."
exec ./ci-simulation/helm-chart-test.sh codegen cpu-values