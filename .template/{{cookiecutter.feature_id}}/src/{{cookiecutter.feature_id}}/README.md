# {{ cookiecutter.feature_name }}

{{ cookiecutter.feature_description }}

## Example Usage

```json
"features": {
    "ghcr.io/infras-factory/devcontainer-features/{{ cookiecutter.feature_id }}:latest": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| | | | |

## What This Feature Does

This feature installs and configures {{ cookiecutter.feature_name }} in your development container.

### Key Features:
- TODO: Add key features
- TODO: Add more features

## Prerequisites

This feature assumes you have:
- A Debian/Ubuntu-based container
- Basic development tools installed

## Post-Installation Scripts

### post-create.sh
Runs once after the container is created. This script:
- Sets up user-specific configurations
- Installs user-level tools
- Configures the environment for the user

### post-start.sh
Runs every time the container starts. This script:
- Ensures the environment is properly configured
- Starts any necessary services
- Performs quick validation checks

### post-attach.sh
Runs when attaching to the container. This script:
- Displays status information
- Provides user guidance
- Performs final setup verification

## OS Support

This feature has been tested on:
- Debian
- Ubuntu

## Version

Current version: {{ cookiecutter.feature_version }}

## License

See the repository's license file.
