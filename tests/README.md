# Tests Directory

This directory contains test files and scripts for validating the repository management tool, including configuration validation and Docker implementation testing.

## Test Files

### Configuration Tests
- `test_config.yaml` - Configuration with template placeholders (should fail validation)
- `valid_test_config.yaml` - Valid configuration without placeholders (should pass validation)  
- `test_mixed_config.yaml` - Valid configuration with commented templates (should pass validation)
- `duplicate_remotes_config.yaml` - Configuration with duplicate remote URLs (should fail validation)
- `*_sub.yaml` - Generated files with environment variables substituted (created by `envsubst`)

### Docker Tests
- `docker_test_config.yaml` - Simple valid configuration for Docker testing
- `docker_tests.sh` - Comprehensive Docker implementation tests (27 tests)
- `docker_integration_test.sh` - Integration tests for `--docker` flag functionality (6 tests)

### Test Runners
- `run_tests.sh` - Main automated test script that runs all tests
- `README.md` - This documentation file

## Test Types

### Configuration Validation Tests (5 tests)
Tests configuration file validation:
1. **Valid config with commented templates** - Ensures comments don't break parsing
2. **Config with placeholders rejection** - Validates rejection of unsubstituted variables
3. **Valid config acceptance** - Confirms proper configurations are accepted
4. **Duplicate remotes rejection** - Validates duplicate remote URL detection
5. **Current config validation** - Tests the actual project configuration

### Docker Implementation Tests (27 tests)
Comprehensive Docker functionality validation:
1. **Environment** (7 tests) - Docker availability, daemon status, Dockerfile validation
2. **Image** (4 tests) - Image building, Python3, Git, GitHub CLI, PyYAML availability
3. **Integration** (16 tests) - Docker flag handling, user mapping, volume mounts, argument passing

### Docker Integration Tests (6 tests)
End-to-end Docker functionality:
1. **Flag parsing** - Docker flag recognition
2. **Mode activation** - Docker mode switching
3. **Image availability** - Docker image detection
4. **Configuration validation** - Config validation in container
5. **User ID preservation** - UID/GID mapping verification
6. **Argument passing** - Parameter forwarding to container

## Test Output Format

All tests use a clean, concise output format:
- ✅ Test name - for passing tests
- ❌ Test name - for failing tests
- ⚠️ Warning message - for informational notices

The complete test suite runs 38 tests total with a comprehensive summary showing results by category.

## Running Tests

### Run All Tests
```bash
# Run complete test suite (configuration + Docker)
./tests/run_tests.sh
```

### Run Specific Test Types
```bash
# Configuration validation tests only
cd tests && ./run_tests.sh

# Docker implementation tests only
./tests/docker_tests.sh

# Docker integration tests only  
./tests/docker_integration_test.sh
```

### Manual Testing
```bash
# Test specific configuration manually
cd tests
envsubst < test_config.yaml > test_config_sub.yaml
python3 ../yaml_lookup.py test_config_sub.yaml repos

# Test Docker functionality manually
./repos --docker --help
```bash
./tests/run_tests.sh
```

The test script automatically:
- Sets up Python/PyYAML dependencies
- Tests all configuration scenarios
- Provides clear pass/fail results with ✅/❌ indicators

## Manual Testing

Test individual configurations:
```bash
# Test valid config
envsubst < tests/valid_test_config.yaml > tests/valid_test_config_sub.yaml
python3 yaml_lookup.py tests/valid_test_config_sub.yaml repos

# Test config with placeholders (should fail)
envsubst < tests/test_config.yaml > tests/test_config_sub.yaml  
python3 yaml_lookup.py tests/test_config_sub.yaml repos

# Test mixed config (commented templates + valid config)
envsubst < tests/test_mixed_config.yaml > tests/test_mixed_config_sub.yaml
python3 yaml_lookup.py tests/test_mixed_config_sub.yaml repos
```

## Test Coverage

The tests validate:
- ✅ Rejection of configs with template placeholders in active configuration with specific error messages
- ✅ Acceptance of valid configurations
- ✅ Acceptance of configs with commented template sections alongside valid sections
- ✅ Proper descriptive error messages for invalid configurations (e.g., "Template placeholder found: ${YOUR_GITHUB_USERNAME}")
- ✅ Environment variable substitution
- ✅ Python/PyYAML dependency setup with package mapping support
- ✅ Current configuration validity

## Test Output

Successful test run example:
```
Running configuration validation tests...
========================================
PyYAML not found in active Python environment
✓ pyyaml (imports as 'yaml') is installed

Test 1: Valid configuration with mixed comments
-----------------------------------------------
✅ PASS: Valid config with commented templates accepted

Test 2: Configuration with template placeholders
-----------------------------------------------
✅ PASS: Config with placeholders correctly rejected

Test 3: Valid configuration without templates
--------------------------------------------
✅ PASS: Valid config accepted

Test 4: Current configuration
----------------------------
✅ PASS: Current config is valid

Tests completed!
```

### Error Message Example

When validation fails due to template placeholders, the error message is comprehensive:
```
ERROR: Invalid configuration:
  - Template placeholders found in active configuration that need replacement: <REPO_NAME>, <YOUR_EMAIL>, <SECONDARY_REPO>, <YOURUSERNAME>, YOUR_GIT_USERNAME, <YOUR_GIT_USERNAME>, <PRIMARY_REPO>
============================================================
CONFIGURATION REQUIRED
============================================================
Your config.yaml file needs to be configured with your information.
Steps to configure:
1. Uncomment the 'config:' and 'repos:' sections in config.yaml
2. Replace all <PLACEHOLDER> values with your actual information
3. Update repository names and paths as needed
4. Ensure all GitHub URLs point to your actual repositories
...
```

## Test Results Summary

### Configuration Tests
- ✅ Template placeholder validation 
- ✅ Valid configuration acceptance
- ✅ Mixed configuration with comments
- ✅ Duplicate remote URL detection
- ✅ Current configuration validation

### Docker Tests  
- ✅ Docker environment validation (27/27 tests passing)
- ✅ Dockerfile structure and content validation
- ✅ Docker image building and dependency verification
- ✅ Script integration with Docker flags
- ✅ User ID mapping and security validation
- ✅ Volume mounting and permissions
- ✅ Argument passing to containers
- ✅ Container cleanup verification

### Integration Tests
- ✅ Docker mode activation
- ✅ User ID preservation  
- ✅ Argument passing verification
- ⚠️ Some integration tests are informational due to output format variations

## Expected Test Output

When running `./tests/run_tests.sh`, you should see:
- Configuration validation tests (5 tests)
- Docker implementation tests (27 tests) 
- Docker integration tests (7 tests)
- All critical functionality should show ✅ PASS

The complete test suite validates both configuration handling and Docker containerization, ensuring the tool works correctly in both native and containerized environments.
