# Repository Management Tool

A bash-based tool for managing multiple Git repositories with multi-remote synchronization capabilities. This tool allows you to maintain local repositories that can sync with multiple remote repositories simultaneously.

**Note: This tool is currently designed specifically for GitHub repositories and requires the GitHub CLI (`gh`) for full functionality.**

## Features

- **Multi-Remote Support**: Sync one local repository with multiple remote repositories
- **YAML Configuration**: Centralized configuration for all repositories and settings
- **Configuration Validation**: Early validation with descriptive error messages for invalid configurations
- **Batch Operations**: Perform git operations across multiple repositories at once
- **Status Monitoring**: Check the status of all repositories without making changes
- **Flexible Filtering**: Process specific repositories using regex patterns
- **Automatic Repository Creation**: Create GitHub repositories if they don't exist (GitHub only)
- **Safe Directory Management**: Automatically configure git safe directories
- **Colored Output**: Easy-to-read colored terminal output with status indicators
- **Smart Python Management**: Automatic virtual environment setup and package management

## Installation

1. Clone this repository to your local machine
2. Ensure you have the following dependencies installed:
   - `bash`
   - `python3` (PyYAML will be automatically installed if needed)
   - `git`
   - `gh` (GitHub CLI) for automatic repository creation - **Required for full functionality**
   - `envsubst` (usually part of `gettext` package)

3. Set up GitHub CLI authentication:
   ```bash
   gh auth login
   ```

4. Make the main script executable:
   ```bash
   chmod +x repos
   ```

The tool will automatically set up Python virtual environments and install PyYAML when needed.

## Configuration

### Setting up config.yaml

The `config.yaml` file contains detailed documentation and examples. To set up your configuration:

1. Uncomment the template sections at the bottom of `config.yaml`
2. Replace placeholder values:
   - `<YOUR_EMAIL>` with your email address
   - `<YOUR_GIT_USERNAME>` with your Git username  
   - `<REPO_NAME>` with your repository names
   - `<YOURUSERNAME>` with your GitHub username
   - `<PRIMARY_REPO>` and `<SECONDARY_REPO>` with your repository names

The tool will validate your configuration and provide specific error messages for any template placeholders that haven't been replaced.

Example configuration:
```yaml
# Global Git Configuration
config:
  email: "your.email@example.com"
  name: "YourGitUsername"
  branch: "main"

repos:
  my-project:
    local: $HOME/git/my-project
    remotes:
      - https://github.com/yourusername/my-project.git          # GitHub URLs required
      - https://github.com/yourusername/my-project-backup.git   # Backup repository
```

### Environment Variables

The configuration supports shell variable expansion using `envsubst`. Common variables include:
- `$HOME` - User's home directory
- `$USER` - Current username  
- `$PWD` - Current working directory
- Any custom environment variables you define

Examples:
```yaml
repos:
  my-project:
    local: $HOME/git/my-project          # Expands to /home/username/git/my-project
    local: /home/$USER/projects/app      # Expands to /home/username/projects/app
    local: $PROJECT_ROOT/src             # Uses custom environment variable
```

Environment variables are expanded when the tool runs, allowing for dynamic configuration across different systems.

## Usage

### Basic Commands

```bash
# Show help and usage information
./repos --help

# Sync all repositories
./repos

# Check status of all repositories without making changes
./repos -s

# Process specific repositories using regex
./repos -r "project.*"

# Force push (use with caution)
./repos -f

# Custom commit message
./repos --gcm "Feature: Add new functionality"

# Pass specific arguments to git push/pull
./repos --push "--tags" --pull "--rebase"

# Specify path pattern for operations
./repos -p "src/*"
```

### Command Line Options

- `-f, --force`: Force push to remote repositories
- `--push <args>`: Arguments to pass to git push command  
- `--pull <args>`: Arguments to pass to git pull command
- `-r, --repos <regex>`: Specify repositories to process (regex pattern)
- `--gcm <message>`: Git commit message (default: backup-YYYY-MM-DD)
- `-p <PathGlob>`: Specify path glob pattern for git operations
- `-s`: Status only mode - show repo status without committing

### Status Indicators

The tool uses clear visual indicators:
- `Validating configuration... ✓ PASSED` - Configuration validation successful
- `Validating configuration... ✗ FAILED` - Configuration validation failed  
- `✓ package (imports as 'name') is installed` - Python package status
- Colored output for git operations (green for success, red for errors)

### Workflow Examples

**First-time setup:**
```bash
# 1. Edit config.yaml with your details
vim config.yaml

# 2. Test your configuration  
./repos -s

# 3. Run full sync
./repos
```

**Daily usage:**
```bash
# Quick status check
./repos -s

# Sync specific repositories
./repos -r "important.*"

# Force update with custom message
./repos -f --gcm "Emergency backup"
```

**Troubleshooting:**
```bash
# Test configuration only
./repos --help

# Check what would be processed
./repos -s -r "pattern.*"
```

## How It Works

1. **Python Environment Setup**: Ensures Python3 and PyYAML are available, creating virtual environments if needed
2. **Configuration Validation**: Validates [`config.yaml`](config.yaml) with descriptive error messages for any issues
3. **Configuration Loading**: Reads the validated configuration and substitutes environment variables  
4. **Repository Discovery**: Parses the YAML configuration to find all defined repositories
5. **Filtering**: Applies any regex filters specified via command line
6. **User Confirmation**: Prompts user to confirm before proceeding with operations
7. **Git Configuration**: Sets global git configuration from the YAML file
8. **Repository Processing**: For each repository:
   - Creates local directory if it doesn't exist
   - Clones from remote if local repo doesn't exist
   - Creates remote repositories if they don't exist (requires GitHub CLI)
   - Adds remotes and configures safe directories
   - Shows git status and prompts for confirmation
   - Commits, pulls, and pushes changes

## Files Overview

- [`repos`](repos) - Main executable script
- [`config.yaml`](config.yaml) - Configuration file with template and documentation
- [`functions`](functions) - Helper functions for git operations and YAML parsing
- [`yaml_lookup.py`](yaml_lookup.py) - Python script for YAML key lookup with validation
- [`yaml_parse.py`](yaml_parse.py) - Python script for complete YAML parsing and export
- [`tests/`](tests/) - Test suite for configuration validation

## Multi-Remote Use Cases

This tool is particularly useful for GitHub-based workflows:

1. **Backup Repositories**: Maintain automatic backups across different GitHub accounts or organizations
2. **Fork Synchronization**: Keep your GitHub fork in sync with an upstream repository
3. **Environment Deployment**: Deploy the same codebase to multiple GitHub repositories for different environments
4. **Mirror Repositories**: Maintain GitHub mirrors for redundancy or different access patterns

**Note**: While the tool can work with any Git remote URLs, automatic repository creation and some advanced features require GitHub repositories and the GitHub CLI.

## Safety Features

- **Configuration Validation**: Early validation with specific error messages (e.g., "Template placeholder found: ${YOUR_GITHUB_USERNAME}")
- **User Confirmation**: Prompts before performing operations
- **Status Checking**: Shows git status before committing
- **Safe Directory Configuration**: Automatically configures git safe directories
- **Error Handling**: Colored output with checkmarks (✓/✗) to highlight successful and failed operations

## Python Dependencies

The tool automatically manages Python dependencies:
- Creates temporary virtual environments if needed
- Installs `pyyaml` if not available
- Reuses existing temporary environments when possible
- **Package Mapping**: Handles cases where pip package names differ from import names:
  - `pyyaml` package → imports as `yaml`

## Testing

The project includes comprehensive automated tests for configuration validation:

```bash
# Run all validation tests
./tests/run_tests.sh

# Test individual configurations manually
cd tests
python3 ../yaml_lookup.py valid_test_config_sub.yaml repos
python3 ../yaml_lookup.py test_config_sub.yaml repos  # Should fail
```

Tests cover:
- Configuration validation with template placeholders (should fail)
- Valid configurations (should pass)
- Mixed configurations with commented templates (should pass)
- Python/PyYAML environment setup
- Descriptive error messages

See [`tests/README.md`](tests/README.md) for detailed testing documentation.

## Troubleshooting

### Common Issues

**Configuration Validation Errors:**
- **Template placeholders found**: Replace all `<PLACEHOLDER>` values in config.yaml
- **Missing required section**: Uncomment and configure the `config:` and `repos:` sections
- **Invalid YAML syntax**: Check indentation and syntax

**Python Environment Issues:**
- **PyYAML not found**: The tool automatically installs PyYAML in a virtual environment
- **Permission errors**: Ensure you have write access to `/tmp` for virtual environments

**Git Operation Issues:**
- **Authentication failed**: Ensure GitHub CLI (`gh`) is logged in: `gh auth login`
- **Repository not found**: Check GitHub repository URLs and permissions
- **Push rejected**: May need to pull first or use force option (use with caution)
- **Repository creation failed**: Ensure GitHub CLI has proper permissions and is authenticated

**GitHub-Specific Issues:**
- **Non-GitHub URLs**: Some features may not work with non-GitHub repositories
- **Organization repositories**: Ensure you have appropriate permissions for organization repos
- **Private repositories**: Check that GitHub CLI has access to private repositories

### Getting Help

- Run `./repos --help` to see all available options
- Check `./repos -s` to see repository status without making changes
- Review configuration with detailed error messages from validation

## Contributing

Feel free to submit issues and pull requests to improve this tool.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.