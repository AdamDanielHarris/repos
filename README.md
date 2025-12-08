# Repository Management Tool

## Easily commit and sync your Git repositories to GitHub

![Platform](https://img.shields.io/badge/platform-linux-blue)
![Shell](https://img.shields.io/badge/shell-bash-green)
![Python](https://img.shields.io/badge/python-3.6+-blue)
![License](https://img.shields.io/badge/license-MIT-blue)
![Docker](https://img.shields.io/badge/docker-supported-blue)
[![CI](https://github.com/AdamDanielHarris/repos/actions/workflows/ci.yml/badge.svg)](https://github.com/AdamDanielHarris/repos/actions/workflows/ci.yml)

A bash-based tool for managing multiple Git repositories with multi-remote synchronization capabilities. Designed for GitHub workflows with containerized execution support.

**Platform Support: Linux/Unix environments only. Tested on various Linux distributions.**

## Features

- **Multi-Remote Support**: Sync local repositories with multiple GitHub remotes
- **Docker Integration**: Containerized execution with automatic dependency management
- **YAML Configuration**: Centralized configuration with environment variable support
- **Configuration Validation**: Early validation with descriptive error messages
- **Batch Operations**: Process multiple repositories simultaneously
- **Status Monitoring**: Check repository status without making changes
- **Flexible Filtering**: Target specific repositories using regex patterns
- **Automatic Repository Creation**: Create GitHub repositories if they don't exist
- **Smart Commit Messages**: Repository-specific or global commit message configuration
- **User ID Mapping**: Automatic permission handling in Docker containers
- **Set GitHub Description**: Quickly update your repository's GitHub description from the command line with `--set-description`.
- **No Sync Option**: Use `--ns` or `--no-sync` to perform local operations only, without syncing to remotes.

## Installation

### Option 1: Native Installation

**Prerequisites**: Linux/Unix operating system with the following dependencies:
- `bash`
- `python3` (PyYAML will be automatically installed if needed)
- `git`
- `gh` (GitHub CLI) - **Required for repository creation**
- `envsubst` (usually part of `gettext` package)

1. Clone this repository to your local machine
2. Set up GitHub CLI authentication:
   ```bash
   gh auth login
   ```

The tool automatically handles Python virtual environments and package installation.

### Option 2: Docker Installation

Use Docker for a consistent environment with all dependencies pre-installed:

```bash
# Build Docker image locally
docker build -t repos-management-tool .

# Run with all dependencies included
./repos --docker
```

> **Note**: Pre-built Docker images will be available at `ghcr.io/adamdanielharris/repos` once the first release is published.

See [DOCKER.md](DOCKER.md) for complete Docker usage guide.

## Configuration

### Setting up config.yaml

The `config.yaml` file contains detailed documentation and examples. Setup process:

1. Uncomment the template sections at the bottom of `config.yaml`
2. Replace placeholder values:
   - `<YOUR_EMAIL>` with your email address
   - `<YOUR_GIT_USERNAME>` with your Git username  
   - `<YOURUSERNAME>` with your GitHub username
   - Repository names and paths as needed

3. Optionally configure repository-specific commit messages

The tool validates your configuration and provides specific error messages for any unresolved template placeholders.

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
    commit_message: "Development updates"     # Optional: Custom default commit message
    remotes:
      - https://github.com/yourusername/my-project.git          # GitHub URLs required
      - https://github.com/yourusername/my-project-backup.git   # Backup repository
  my-project-2:
    local: $HOME/git/my-project2
    commit_message: "New Project Updates"     # Optional: Custom default commit message
    remotes:
      - https://github.com/yourusername/my-project.git          # GitHub URLs required
      - https://github.com/yourusername/my-project-backup.git   # Backup repository
    name: YourOtherGitUsername                # Optional: local username in place of specified global config
    email: your.other.email@example.com       # Optional: local email in place of specified global config
```

### Commit Message Configuration

The tool supports multiple levels of commit message configuration:

1. **Repository-specific default** (in config.yaml):
   ```yaml
   repos:
     my-project:
       local: $HOME/git/my-project
       commit_message: "Development updates"  # Custom default for this repo
       remotes:
         - https://github.com/username/my-project.git
   ```

2. **Command line override** (highest priority):
   ```bash
   ./repos --gcm "Custom commit message for this run"
   ```

3. **Global default** (when no other message is specified):
   - Format: `backup-YYYY-MM-DD` (e.g., "backup-2025-06-10")

**Priority order**: Command line (`--gcm`) > Repository default (`commit_message`) > Global default (`backup-YYYY-MM-DD`)

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
    remotes:
      - https://github.com/username/my-project.git
  
  user-app:
    local: /home/$USER/projects/app      # Expands to /home/username/projects/app
    remotes:
      - https://github.com/username/user-app.git
      
  custom-project:
    local: $PROJECT_ROOT/src             # Uses custom environment variable
    remotes:
      - https://github.com/username/custom-project.git
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

# Custom commit message (overrides repository defaults)
./repos --gcm "Feature: Add new functionality"

# Pass specific arguments to git push/pull
./repos --push "--tags" --pull "--rebase"

# Specify path pattern for operations
./repos -p "src/*"

# Run in Docker container (all dependencies included)
./repos --docker
```

### Docker Commands

```bash
# Run all operations in Docker
./repos --docker

# Status check in Docker
./repos --docker -s

# Docker with custom commit message
./repos --docker --gcm "Docker deployment update"

# Docker with specific repository pattern
./repos --docker -r "web.*"

```

### Command Line Options

- `-f, --force`: Force push to remote repositories
- `--push <args>`: Arguments to pass to git push command  
- `--pull <args>`: Arguments to pass to git pull command
- `-r, --repos <regex>`: Specify repositories to process (regex pattern)
- `--gcm <message>`: Git commit message (overrides repository defaults and global default)
- `-p <PathGlob>`: Specify path glob pattern for git operations
- `-s`: Status only mode - show repo status without committing
- `--docker`: Run in Docker container with all dependencies pre-installed
- `--set-description <description>`: Set the GitHub repository description and exit.
- `--ns`, `--no-sync`: Do not sync to remote repositories (local operations only).

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

## Detailed Operations

When you run the `repos` script, it performs the following operations on each configured repository:

### Repository Setup Phase
1. **Directory Creation**: Creates local repository directory if it doesn't exist
2. **Repository Initialization**: 
   - If `.git` doesn't exist and directory is empty: Clones from first remote
   - If `.git` doesn't exist and directory has files: Initializes git repository with main branch
3. **GitHub Repository Creation**: Creates remote GitHub repositories if they don't exist (requires `gh` CLI)
4. **Safe Directory Configuration**: Adds repository to git safe directories

### Synchronization Phase (for each repository)
1. **File Staging**: Executes `git add .` to stage all changes
   - **All modified files** are automatically staged
   - **All new files** are automatically staged  
   - **Deleted files** are automatically staged
   
2. **Status Display**: Shows `git status` output for review

3. **User Confirmation**: Prompts "Do you want to continue? (y/n)" before proceeding

4. **Remote Setup**: Adds remote repositories if not already configured

5. **Commit Operation**: 
   - Commits all staged changes using the configured commit message
   - Uses `git commit -am "message"` (commits all tracked file changes)
   - Message priority: CLI override > repo default > `backup-YYYY-MM-DD`

6. **Pull Operation** (unless force mode):
   - Executes `git pull <remote> main` to sync with remote changes
   - Uses any additional pull arguments specified with `--pull`

7. **Push Operation**:
   - Executes `git push <remote> main` to upload local changes
   - In force mode: Uses `git push -f <remote> main`
   - Uses any additional push arguments specified with `--push`

### Status-Only Mode (`-s` flag)
When using status-only mode, the tool:
- **Skips all write operations** (no commits, pulls, or pushes)
- **Shows repository status** for each configured repository
- **Lists repositories with no changes**
- **Highlights repositories with uncommitted changes**

### Important Notes
- **All files are committed**: The tool uses `git add .` and `git commit -am`, meaning ALL changes in the repository are staged and committed
- **Path pattern support**: Use `-p <PathGlob>` to target specific files or directories, though all matching files are still processed together
- **Automatic operations**: Once confirmed, all git operations (add, commit, pull, push) happen automatically
- **Multi-remote support**: Each repository can push to multiple remote repositories sequentially

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

Feel free to submit issues and pull requests to improve the tool.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.