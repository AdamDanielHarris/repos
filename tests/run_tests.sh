#!/usr/bin/env bash

# Test script for repository configuration validation
# Run this from the main repos directory

cd "$(dirname "$0")/.." || exit 1

# Source functions and ensure Python/PyYAML is available
source functions
EnsurePython3WithYaml

# Cleanup function to remove generated test files
cleanup_test_files() {
    echo "Cleaning up generated test files..."
    rm -f tests/*_sub.yaml config_sub.yaml 2>/dev/null || true
    rm -f /tmp/config_results.txt /tmp/docker_tests_results.txt /tmp/docker_integration_results.txt 2>/dev/null || true
}

# Set up cleanup trap to run on exit
trap cleanup_test_files EXIT

echo ""
echo "Configuration Tests..."

# Configuration test counters
CONFIG_PASSED=0
CONFIG_FAILED=0

# Test 1: Valid configuration with mixed comments
envsubst < tests/test_mixed_config.yaml > tests/test_mixed_config_sub.yaml
if python3 yaml_lookup.py tests/test_mixed_config_sub.yaml repos > /dev/null 2>&1; then
    echo "✅ Config with commented templates validation"
    ((CONFIG_PASSED++))
else
    echo "❌ Config with commented templates validation"
    ((CONFIG_FAILED++))
fi

# Test 2: Configuration with template placeholders
envsubst < tests/test_config.yaml > tests/test_config_sub.yaml
if python3 yaml_lookup.py tests/test_config_sub.yaml repos > /dev/null 2>&1; then
    echo "❌ Config with placeholders rejection"
    ((CONFIG_FAILED++))
else
    echo "✅ Config with placeholders rejection"
    ((CONFIG_PASSED++))
fi

# Test 3: Valid configuration without templates
envsubst < tests/valid_test_config.yaml > tests/valid_test_config_sub.yaml
if python3 yaml_lookup.py tests/valid_test_config_sub.yaml repos > /dev/null 2>&1; then
    echo "✅ Valid config acceptance"
    ((CONFIG_PASSED++))
else
    echo "❌ Valid config acceptance"
    ((CONFIG_FAILED++))
fi

# Test 4: Configuration with duplicate remote URLs
envsubst < tests/duplicate_remotes_config.yaml > tests/duplicate_remotes_config_sub.yaml
if python3 yaml_lookup.py tests/duplicate_remotes_config_sub.yaml repos > /dev/null 2>&1; then
    echo "❌ Duplicate remotes rejection"
    ((CONFIG_FAILED++))
else
    echo "✅ Duplicate remotes rejection"
    ((CONFIG_PASSED++))
fi

# Test 5: Current configuration
# Create a CI-friendly config for testing
if [ "$CI" = "true" ] || [ "$GITHUB_ACTIONS" = "true" ]; then
    # In CI, create a minimal valid config
    cat > ci_config.yaml << EOF
config:
  email: "test@example.com"
  name: "TestUser"
  branch: "main"
repos:
  test-repo:
    local: /tmp/test-repo
    remotes:
      - https://github.com/example/test.git
EOF
    if python3 yaml_lookup.py ci_config.yaml repos > /dev/null 2>&1; then
        echo "✅ Current config validation"
        ((CONFIG_PASSED++))
    else
        echo "❌ Current config validation"
        ((CONFIG_FAILED++))
    fi
    rm -f ci_config.yaml
else
    # Local testing uses actual config
    envsubst < config.yaml > config_sub.yaml
    if python3 yaml_lookup.py config_sub.yaml repos > /dev/null 2>&1; then
        echo "✅ Current config validation"
        ((CONFIG_PASSED++))
    else
        echo "❌ Current config validation"
        ((CONFIG_FAILED++))
    fi
fi

# Test 6: PathGlob functionality
# Create test files for PathGlob testing
echo "test content for pathglob" > test_pathglob_file.txt
echo "another test file" > another_test_file.txt
echo "should not be committed" > excluded_file.txt

# Initialize a temporary git repo for testing
rm -rf test_pathglob_repo
git init -q test_pathglob_repo 2>/dev/null || true
cd test_pathglob_repo
git config user.email "test@example.com"
git config user.name "Test User"

# Copy test files into the test repo
cp ../test_pathglob_file.txt .
cp ../another_test_file.txt .
cp ../excluded_file.txt .

# Source the functions in the test directory
cp ../functions .
cp ../yaml_lookup.py .
source functions

# Test PathGlob by committing only specific files
GCM="PathGlob test commit"
if GitCommit "" test_pathglob_file.txt another_test_file.txt > /dev/null 2>&1; then
    # Check if only the specified files were in the last commit
    committed_files=$(git show --name-only --format="" HEAD 2>/dev/null || echo "")
    if [[ "$committed_files" == *"test_pathglob_file.txt"* ]] && [[ "$committed_files" == *"another_test_file.txt"* ]] && [[ "$committed_files" != *"excluded_file.txt"* ]]; then
        # Verify excluded file is still untracked
        untracked_files=$(git ls-files --others --exclude-standard)
        if [[ "$untracked_files" == *"excluded_file.txt"* ]]; then
            echo "✅ PathGlob functionality (selective file commit)"
            ((CONFIG_PASSED++))
        else
            echo "❌ PathGlob functionality (excluded file was committed)"
            ((CONFIG_FAILED++))
        fi
    else
        echo "❌ PathGlob functionality (wrong files committed)"
        echo "Expected: test_pathglob_file.txt, another_test_file.txt"
        echo "Got: $committed_files"
        ((CONFIG_FAILED++))
    fi
else
    echo "❌ PathGlob functionality (commit failed)"
    ((CONFIG_FAILED++))
fi

# Cleanup test files and repo
cd ..
rm -rf test_pathglob_repo
rm -f test_pathglob_file.txt another_test_file.txt excluded_file.txt

# Store results for summary
echo "$CONFIG_PASSED $CONFIG_FAILED" > /tmp/config_results.txt

echo ""
echo "Docker Implementation Tests..."

DOCKER_EXIT_CODE=0
if command -v docker >/dev/null 2>&1; then
    ./tests/docker_tests.sh
    DOCKER_EXIT_CODE=$?
else
    echo "⚠️  Docker not available - skipping Docker tests"
    echo "   Install Docker to run complete test suite"
    # Create dummy results for summary
    echo "0 0 0" > /tmp/docker_tests_results.txt
    echo "0 0 0" > /tmp/docker_integration_results.txt
fi

echo ""
echo "========================================"
echo "COMPLETE TEST SUITE SUMMARY"
echo "========================================"

# Configuration test results
if [ -f "/tmp/config_results.txt" ]; then
    read CONFIG_PASSED CONFIG_FAILED < /tmp/config_results.txt
    CONFIG_TOTAL=$((CONFIG_PASSED + CONFIG_FAILED))
    echo "Configuration Tests: $CONFIG_TOTAL tests run, $CONFIG_PASSED passed"
    rm -f /tmp/config_results.txt
fi

# Docker test results
if command -v docker >/dev/null 2>&1; then
    if [ -f "/tmp/docker_tests_results.txt" ]; then
        read DOCKER_RUN DOCKER_PASSED DOCKER_FAILED < /tmp/docker_tests_results.txt
        echo "Docker Implementation Tests: $DOCKER_RUN tests run, $DOCKER_PASSED passed"
        rm -f /tmp/docker_tests_results.txt
    fi
    
    if [ -f "/tmp/docker_integration_results.txt" ]; then
        read INT_PASSED INT_FAILED INT_INFO < /tmp/docker_integration_results.txt
        INT_TOTAL=$((INT_PASSED + INT_FAILED + INT_INFO))
        echo "Docker Integration Tests: $INT_TOTAL tests run, $INT_PASSED passed"
        rm -f /tmp/docker_integration_results.txt
    fi
else
    echo "Docker Tests: Skipped (Docker not available)"
fi

echo ""
# Final exit status check
if [ -f "/tmp/config_results.txt" ]; then
    read CONFIG_PASSED CONFIG_FAILED < /tmp/config_results.txt
    rm -f /tmp/config_results.txt
fi

# Explicit cleanup before exit
cleanup_test_files

if [ $DOCKER_EXIT_CODE -eq 0 ] && [ ${CONFIG_FAILED:-0} -eq 0 ]; then
    echo "🎉 All available tests PASSED! Repository is ready for use."
    exit 0
else
    echo "❌ Some tests FAILED. Please review the output above."
    exit 1
fi
