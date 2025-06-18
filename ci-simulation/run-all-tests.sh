#!/bin/bash
# Run all CI simulation tests

echo "============================================="
echo "Running ALL CI Simulation Tests"
echo "============================================="

# Set default environment if not set
export HFTOKEN="${HFTOKEN:-placeholder}"
export MODELDIR="${MODELDIR:-/tmp/hf_models}"
export MODELNAME="${MODELNAME:-meta-llama/Meta-Llama-3-8B-Instruct}"

echo "Environment:"
echo "  HFTOKEN: ${HFTOKEN:0:10}..."
echo "  MODELDIR: $MODELDIR"
echo "  MODELNAME: $MODELNAME"
echo ""

# Test all successful cases first
echo "=== Testing SUCCESSFUL cases (cpu-values) ==="
echo ""

echo "1. Testing ChatQnA with cpu-values..."
./chatqna/test-cpu-values.sh
echo ""

echo "2. Testing CodeGen with cpu-values..."
./codegen/test-cpu-values.sh
echo ""

echo "3. Testing DocSum with cpu-values..."
./docsum/test-cpu-values.sh
echo ""

# Test all failing cases
echo "=== Testing FAILING cases (external-llm-values) ==="
echo ""

echo "4. Testing ChatQnA with external-llm-values..."
./chatqna/test-external-llm-values.sh
echo ""

echo "5. Testing CodeGen with external-llm-values..."
./codegen/test-external-llm-values.sh
echo ""

echo "6. Testing DocSum with external-llm-values..."
./docsum/test-external-llm-values.sh
echo ""

echo "============================================="
echo "All tests completed!"
echo "============================================="