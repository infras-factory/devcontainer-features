# Python Version Management (pyenv)

Installs pyenv for managing multiple Python versions in your development container

## Example Usage

```json
"features": {
    "ghcr.io/infras-factory/devcontainer-features/pyenv:latest": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| | | | |

## What This Feature Does

This feature installs and configures Python Version Management (pyenv) in your development container.

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

Current version: 1.0.0

## License

See the repository's license file.
