#!/usr/bin/env bash

# Test script for repository configuration validation
# Run this from the main repos directory

echo "Running configuration validation tests..."
echo "========================================"

cd "$(dirname "$0")/.." || exit 1

# Source functions and ensure Python/PyYAML is available
source functions
EnsurePython3WithYaml

echo ""
echo "Test 1: Valid configuration with mixed comments"
echo "-----------------------------------------------"
envsubst < tests/test_mixed_config.yaml > tests/test_mixed_config_sub.yaml
if python3 yaml_lookup.py tests/test_mixed_config_sub.yaml repos > /dev/null 2>&1; then
    echo "✅ PASS: Valid config with commented templates accepted"
else
    echo "❌ FAIL: Valid config with commented templates rejected"
fi

echo ""
echo "Test 2: Configuration with template placeholders"
echo "-----------------------------------------------"
envsubst < tests/test_config.yaml > tests/test_config_sub.yaml
if python3 yaml_lookup.py tests/test_config_sub.yaml repos > /dev/null 2>&1; then
    echo "❌ FAIL: Config with placeholders incorrectly accepted"
else
    echo "✅ PASS: Config with placeholders correctly rejected"
fi

echo ""
echo "Test 3: Valid configuration without templates"
echo "--------------------------------------------"
envsubst < tests/valid_test_config.yaml > tests/valid_test_config_sub.yaml
if python3 yaml_lookup.py tests/valid_test_config_sub.yaml repos > /dev/null 2>&1; then
    echo "✅ PASS: Valid config accepted"
else
    echo "❌ FAIL: Valid config rejected"
fi

echo ""
echo "Test 4: Current configuration"
echo "----------------------------"
envsubst < config.yaml > config_sub.yaml
if python3 yaml_lookup.py config_sub.yaml repos > /dev/null 2>&1; then
    echo "✅ PASS: Current config is valid"
else
    echo "❌ FAIL: Current config is invalid"
fi

echo ""
echo "Tests completed!"
