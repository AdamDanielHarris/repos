# Docker Usage Guide

This repository includes Docker support for containerized execution with all dependencies pre-installed.

## Quick Start

### Recommended: Built-in Docker flag
```bash
# Run with Docker (automatically builds image if needed)
./repos --docker

# Run specific operations in Docker
./repos --docker -s                    # Status check
./repos --docker --gcm "My message"    # Custom commit message
./repos --docker -r "project.*"        # Specific repositories
```

### Manual Docker commands (Advanced)
```bash
# Build the image manually
docker build -t repos-management-tool .

# Run with proper user mapping
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -v $(pwd):/app \
  -v $HOME:/home/repouser \
  -w /app \
  repos-management-tool ./repos -s
```

## Technical Implementation

### Automatic User ID Mapping
The `--docker` flag automatically maps your host user ID and group ID to the container:
- Uses `$(id -u):$(id -g)` to match host permissions
- Prevents permission issues with created files
- Ensures proper ownership of git operations

### Volume Mounting Strategy
- **Project Directory**: `$(pwd):/app` - Full read/write access to project files
- **Home Directory**: `$HOME:/home/repouser` - Access to all user configurations
- **Working Directory**: `/app` - Container starts in project directory

### Configuration Access
The container automatically has access to:
- GitHub CLI authentication (`~/.config/gh/`)
- Git global configuration (`~/.gitconfig`)
- SSH keys (`~/.ssh/`) for git authentication
- All environment variables needed for proper operation

## Troubleshooting

### GitHub Authentication Issues

If you see authentication prompts, ensure GitHub CLI is properly set up on your host:

```bash
# Check if GitHub CLI is authenticated on your host system
gh auth status

# If not authenticated, login first:
gh auth login
```

### Permission Issues
- The container automatically uses your host UID/GID (`$(id -u):$(id -g)`)
- No manual permission configuration needed
- Files created in container will have correct ownership

### Build Issues
```bash
# Clean build if needed
docker build --no-cache -t repos-management-tool .

# Verify Docker installation
docker --version && docker info
```

### Configuration Issues
```bash
# Ensure config.yaml exists in current directory
ls -la config.yaml

# Verify git repositories location
ls -la ~/git/
```

## Advantages of Docker Mode

1. **Zero Configuration**: No local dependencies needed
2. **Consistent Environment**: Same behavior across multiple machines  
3. **Automatic Permissions**: User ID mapping handles file ownership
4. **Isolated Execution**: No impact on host system
5. **Authentication Inheritance**: Seamlessly uses host GitHub/git credentials

## Performance Notes

- First run builds Docker image (may take a few minutes)
- Subsequent runs start immediately (cached image)
- Git operations perform at native speed
- User ID mapping prevents permission issues
