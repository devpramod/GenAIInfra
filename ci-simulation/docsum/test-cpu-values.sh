#!/bin/bash
# Test script for DocSum with cpu-values (successful case)

echo "==========================================="
echo "Testing DocSum with cpu-values.yaml"
echo "This should simulate the SUCCESSFUL CI test"
echo "==========================================="

cd "$(dirname "$0")/../.."
exec ./ci-simulation/helm-chart-test.sh docsum cpu-values