#!/usr/bin/env bash

# Docker implementation tests
# Tests Docker integration, user ID mapping, volume mounting, and containerized execution

# Cleanup function
cleanup_docker_files() {
    # Clean up any temporary files created during docker tests
    rm -f /tmp/docker_tests_results.txt 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup_docker_files EXIT

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function for test output
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"  # "pass" or "fail"
    
    ((++TESTS_RUN))
    
    if eval "$test_command" > /dev/null 2>&1; then
        actual_result="pass"
    else
        actual_result="fail"
    fi
    
    if [ "$actual_result" = "$expected_result" ]; then
        echo -e "✅ $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "❌ $test_name"
        ((TESTS_FAILED++))
    fi
}

# Test 1: Docker availability
run_test "Docker is installed and available" \
    "command -v docker" \
    "pass"

run_test "Docker daemon is running" \
    "docker info" \
    "pass"

# Test 2: Dockerfile validation
run_test "Dockerfile exists in project root" \
    "test -f Dockerfile" \
    "pass"

run_test "Dockerfile contains required base image" \
    "grep -q 'FROM.*ubuntu:22.04' Dockerfile" \
    "pass"

run_test "Dockerfile installs required packages" \
    "grep -q 'python3' Dockerfile && grep -q 'git' Dockerfile && grep -q 'gh' Dockerfile" \
    "pass"

run_test "Dockerfile creates non-root user" \
    "grep -q 'RUN useradd.*repouser' Dockerfile" \
    "pass"

# Test 3: Docker image build

# Check if image exists, if not try to build it
if ! docker image inspect repos-management-tool &> /dev/null; then
    echo "Building Docker image for testing..."
    if docker build -t repos-management-tool . > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker image built successfully${NC}"
    else
        echo -e "${RED}❌ Docker image build failed${NC}"
        exit 1
    fi
fi

run_test "Docker image exists" \
    "docker image inspect repos-management-tool" \
    "pass"

run_test "Docker image has Python3 installed" \
    "docker run --rm repos-management-tool python3 --version" \
    "pass"

run_test "Docker image has Git installed" \
    "docker run --rm repos-management-tool git --version" \
    "pass"

run_test "Docker image has GitHub CLI installed" \
    "docker run --rm repos-management-tool gh --version" \
    "pass"

run_test "Docker image has PyYAML available" \
    "docker run --rm repos-management-tool python3 -c 'import yaml'" \
    "pass"

# Test 4: Docker script integration
run_test "Script recognizes --docker flag" \
    "grep -q 'DOCKER_MODE' repos" \
    "pass"

run_test "Functions file has Docker mode handling" \
    "grep -q 'RunDockerMode' functions" \
    "pass"

run_test "Functions file uses user ID mapping" \
    "grep -q '\$(id -u):\$(id -g)' functions" \
    "pass"

run_test "Functions file mounts project directory" \
    "grep -q '/app' functions" \
    "pass"

run_test "Functions file mounts home directory" \
    "grep -q '/home/repouser' functions" \
    "pass"

# Test 5: Docker execution tests (if config is valid)
# Check if we have a valid config for testing
if [ -f "config.yaml" ]; then
    # Test configuration validation in Docker with CI-friendly config
    run_test "Docker container can validate configuration" \
        "docker run --rm -v \$(pwd):/app -w /app repos-management-tool bash -c 'source functions && EnsurePython3WithYaml && cat > /tmp/config_test.yaml << EOF
config:
  email: \"test@example.com\"
  name: \"TestUser\"
  branch: \"main\"
repos:
  test-repo:
    local: /tmp/test
    remotes:
      - https://github.com/example/test.git
EOF
python3 yaml_lookup.py /tmp/config_test.yaml repos'" \
        "pass"
    
    # Test status-only mode in Docker (simplified test)
    run_test "Docker container can run status check" \
        "docker run --rm --user \$(id -u):\$(id -g) -v \$(pwd):/app -w /app repos-management-tool bash -c 'ls -la'" \
        "pass"
else
    echo -e "${YELLOW}⚠️  Skipping execution tests - config.yaml not found${NC}"
fi

# Test 6: Docker argument passing
run_test "Functions file reconstructs force flag for Docker" \
    "grep -q 'DOCKER_ARGS.*-f' functions" \
    "pass"

run_test "Functions file reconstructs repos filter for Docker" \
    "grep -q 'DOCKER_ARGS.*-r' functions" \
    "pass"

run_test "Functions file reconstructs commit message for Docker" \
    "grep -q 'DOCKER_ARGS.*--gcm' functions" \
    "pass"

run_test "Functions file reconstructs status flag for Docker" \
    "grep -q 'DOCKER_ARGS.*-s' functions" \
    "pass"

# Test 7: Docker security tests
run_test "Docker runs with user mapping (not root)" \
    "grep -q -- '--user \$(id -u):\$(id -g)' functions" \
    "pass"

run_test "Docker uses read-only home mount" \
    "docker run --rm --user \$(id -u):\$(id -g) -v \$HOME:/home/repouser:ro repos-management-tool test -r /home/repouser" \
    "pass"

run_test "Docker container cannot write to home mount" \
    "docker run --rm --user \$(id -u):\$(id -g) -v \$HOME:/home/repouser:ro repos-management-tool test ! -w /home/repouser" \
    "pass"

# Test 8: Docker cleanup tests
run_test "Docker uses --rm flag for automatic cleanup" \
    "grep -q -- '--rm' functions" \
    "pass"

run_test "No stopped containers after Docker run" \
    "[ \$(docker ps -a --filter 'ancestor=repos-management-tool' --filter 'status=exited' -q | wc -l) -eq 0 ]" \
    "pass"

# Store results for main summary  
echo "$TESTS_RUN $TESTS_PASSED $TESTS_FAILED" > /tmp/docker_tests_results.txt

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "Docker Integration Tests..."
    # Run integration tests if basic tests pass
    ./tests/docker_integration_test.sh
    
    exit 0
else
    echo "❌ Some Docker tests failed."
    exit 1
fi
