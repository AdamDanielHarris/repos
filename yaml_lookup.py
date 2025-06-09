import yaml
import argparse
import fnmatch
import sys
import re

def validate_yaml_structure(yaml_content, file_path_original):
    """
    Validates that the YAML structure contains required fields and no template placeholders.
    Returns tuple (is_valid, error_messages)
    """
    errors = []
    
    # Read the raw file content to check for placeholders and commented sections
    try:
        with open(file_path_original, 'r') as f:
            raw_content = f.read()
    except FileNotFoundError:
        errors.append(f"Configuration file '{file_path_original}' not found")
        return False, errors
    
    # Check if YAML content is None or empty (only comments)
    if not yaml_content:
        # Check if there are commented config sections
        if '# config:' in raw_content or '#config:' in raw_content:
            errors.append("Configuration sections are commented out - please uncomment 'config:' and 'repos:' sections")
        else:
            errors.append("Configuration file contains only comments or is empty - please add configuration sections")
        return False, errors
    
    # Check for template placeholders only in the actual YAML content (not comments)
    # Convert yaml_content back to string to check for placeholders in actual config
    yaml_string = ""
    if yaml_content:
        yaml_string = str(yaml_content)
    
    template_patterns = [
        r'<[A-Z_]+>',
        r'<[a-zA-Z_]+>',
        r'YOURUSERNAME',
        r'YOUR_EMAIL',
        r'YOUR_GIT_USERNAME'
    ]
    
    placeholders_found = []
    for pattern in template_patterns:
        matches = re.findall(pattern, yaml_string)
        placeholders_found.extend(matches)
    
    if placeholders_found:
        errors.append(f"Template placeholders found in active configuration that need replacement: {', '.join(set(placeholders_found))}")
    
    # Required top-level keys
    required_keys = ['config', 'repos']
    for key in required_keys:
        if key not in yaml_content:
            errors.append(f"Missing required section: '{key}'")
    
    # If we don't have the basic structure, return early
    if errors:
        return False, errors
    
    # Validate config section
    config = yaml_content.get('config', {})
    required_config_keys = ['email', 'name', 'branch']
    
    for key in required_config_keys:
        if key not in config:
            errors.append(f"Missing required config field: '{key}'")
        elif not config[key] or str(config[key]).strip() == "":
            errors.append(f"Config field '{key}' is empty")
    
    # Validate repos section
    repos = yaml_content.get('repos', {})
    if not repos:
        errors.append("No repositories defined in 'repos' section")
        return False, errors
    
    # Check each repository
    for repo_name, repo_config in repos.items():
        if not isinstance(repo_config, dict):
            errors.append(f"Repository '{repo_name}' configuration must be a dictionary")
            continue
            
        # Check for required repo fields
        if 'local' not in repo_config:
            errors.append(f"Repository '{repo_name}' missing 'local' path")
        elif not repo_config['local'] or str(repo_config['local']).strip() == "":
            errors.append(f"Repository '{repo_name}' has empty 'local' path")
            
        if 'remotes' not in repo_config:
            errors.append(f"Repository '{repo_name}' missing 'remotes' list")
        elif not isinstance(repo_config['remotes'], list) or len(repo_config['remotes']) == 0:
            errors.append(f"Repository '{repo_name}' 'remotes' must be a non-empty list")
    
    return len(errors) == 0, errors

def print_configuration_help():
    """Print helpful instructions for configuring the YAML file."""
    print("\n" + "="*60)
    print("CONFIGURATION REQUIRED")
    print("="*60)
    print("\nYour config.yaml file needs to be configured with your information.")
    print("\nSteps to configure:")
    print("1. Uncomment the 'config:' and 'repos:' sections in config.yaml")
    print("2. Replace all <PLACEHOLDER> values with your actual information")
    print("3. Update repository names and paths as needed")
    print("4. Ensure all GitHub URLs point to your actual repositories")
    print("\nExample configuration:")
    print("\nconfig:")
    print("  email: \"your.email@example.com\"")
    print("  name: \"YourGitUsername\"") 
    print("  branch: \"main\"")
    print("\nrepos:")
    print("  my-project:")
    print("    local: $HOME/git/my-project")
    print("    remotes:")
    print("      - https://github.com/yourusername/my-project.git")
    print("      - https://github.com/yourusername/my-project-backup.git")
    print("\n" + "="*60)

def advanced_yaml_parse(file_path, lookup_key, prefix=""):
    """
    This function parses a YAML file and handles nested keys and value pairs within key value pairs.
    It uses recursion to handle the nested structures and validates configuration.
    """
    try:
        with open(file_path, 'r') as stream:
            yaml_content = yaml.safe_load(stream)
    except FileNotFoundError:
        print(f"ERROR: Configuration file '{file_path}' not found.")
        sys.exit(1)
    except yaml.YAMLError as exc:
        print(f"ERROR: Invalid YAML syntax in '{file_path}':")
        print(exc)
        sys.exit(1)

    file_path_original = file_path.replace('_sub', '')

    # Always validate configuration on first access (any lookup triggers validation)
    is_valid, validation_errors = validate_yaml_structure(yaml_content, file_path_original)
    
    if not is_valid:
        print("ERROR: Invalid configuration:")
        for error in validation_errors:
            print(f"  - {error}")
        print_configuration_help()
        sys.exit(1)

    def process_dict(dictionary, lookup_key, prefix=""):
        """
        This function processes a dictionary and handles nested keys and value pairs within key value pairs.
        It uses recursion to handle the nested structures.
        """       
        for key, value in dictionary.items():
            new_key = f"{prefix}_{key}" if prefix else key
            new_key = new_key.replace('-', '_')  # replace dashes with underscores
            if fnmatch.fnmatch(new_key, lookup_key):
                yield (new_key, value)
            if isinstance(value, dict):
                yield from process_dict(value, lookup_key, new_key)

    return process_dict(yaml_content, lookup_key)

def main():
    parser = argparse.ArgumentParser(description='Process and validate a YAML configuration file.')
    parser.add_argument('file_path', type=str, help='The path to the YAML file to process.')
    parser.add_argument('lookup_key', type=str, help='The key to look up in the YAML file.')

    args = parser.parse_args()
    args.lookup_key = args.lookup_key.replace('-', '_')  # replace dashes with underscores in lookup key

    results = advanced_yaml_parse(args.file_path, args.lookup_key)
    
    # Cleanup the output to make it parsable by bash
    for result in results:
        if result is not None:
            key_name, value = result
            if isinstance(value, dict):
                for key in value.keys():
                    print(key)
            else:
                def cleanup_value(value):
                    if isinstance(value, list):
                        return ' '.join(map(str, value))
                    return str(value)

                print(cleanup_value(value))

if __name__ == "__main__":
    main()