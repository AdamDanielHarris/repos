# Tests Directory

This directory contains test files and scripts for validating the repository management tool.

## Test Files

- `test_config.yaml` - Configuration with template placeholders (should fail validation)
- `valid_test_config.yaml` - Valid configuration without placeholders (should pass validation)  
- `test_mixed_config.yaml` - Valid configuration with commented templates (should pass validation)
- `*_sub.yaml` - Generated files with environment variables substituted (created by `envsubst`)
- `run_tests.sh` - Automated test script that runs all validation tests
- `README.md` - This documentation file

## Test Structure

Each test follows this pattern:
1. **Setup**: Ensure Python/PyYAML environment is ready
2. **Substitution**: Run `envsubst` to expand environment variables
3. **Validation**: Run `yaml_lookup.py` with the configuration
4. **Assessment**: Check exit code and provide pass/fail status

The tests are designed to be:
- **Automated**: Run without user intervention
- **Comprehensive**: Cover all major validation scenarios  
- **Clear**: Provide obvious pass/fail indicators
- **Fast**: Complete in seconds

## Running Tests

Run all validation tests:
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
