import yaml
import argparse

def advanced_yaml_parse(file_path, prefix=""):
    """
    This function parses a YAML file and handles nested keys and value pairs within key value pairs.
    It uses recursion to handle the nested structures.
    """
    with open(file_path, 'r') as stream:
        try:
            yaml_content = yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            print(exc)

    def process_dict(dictionary, prefix=""):
        """
        This function processes a dictionary and handles nested keys and value pairs within key value pairs.
        It uses recursion to handle the nested structures.
        """
        for key, value in dictionary.items():
            new_key = f"{prefix}_{key}" if prefix else key
            new_key = new_key.replace('-', '_')  # replace dashes with underscores
            if isinstance(value, dict):
                process_dict(value, new_key)
            elif isinstance(value, list):
                print(f'{new_key}="{ " ".join(map(str, value)) }"')  # join list elements with spaces
            else:
                print(f'{new_key}="{value}"')

    process_dict(yaml_content)

def main():
    parser = argparse.ArgumentParser(description='Process a YAML file.')
    parser.add_argument('file_path', type=str, help='The path to the YAML file to process.')

    args = parser.parse_args()

    advanced_yaml_parse(args.file_path)

if __name__ == "__main__":
    main()