
# Python Version Management (pyenv)

Installs pyenv for managing multiple Python versions in your development container.

## Example Usage

```jsonc
"features": {
    "ghcr.io/infras-factory/devcontainer-features/pyenv:latest": {}
}
```

With custom Python version:
```jsonc
"features": {
    "ghcr.io/infras-factory/devcontainer-features/pyenv:latest": {
        "defaultPythonVersion": "3.11.5"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|------------|-------------|------|---------------|
| `defaultPythonVersion` | Specify Python version to install (e.g., '3.11.5'). Priority: .python-version file → defaultPythonVersion option → latest LTS version. | string | "" |

## What This Feature Does

This feature installs and configures Python Version Management (pyenv) in your development container.

### Key Features
- Installs all required system dependencies for building Python from source
- Installs pyenv per-user in the post-create lifecycle script for proper permissions
- Copies lifecycle scripts and configuration files for container events
- Cleans up package manager caches for smaller image size
- Provides user guidance and status information on attach

## Prerequisites

- Debian/Ubuntu-based container
- Basic development tools installed


## Lifecycle Scripts and Logic

This feature includes several lifecycle scripts located in `src/pyenv/scripts/`, which are automatically executed at specific container events:

### post-create.sh
Executed once after the container is created. Main actions:
- Loads feature configuration from install script
- Installs pyenv for the current user, ensuring user-level installation and configuration
- Determines Python version using priority order: `.python-version` file → `defaultPythonVersion` option → latest LTS version
- Installs the determined Python version using pyenv and sets it as the global default
- Installs pyenv plugins (pyenv-virtualenv, pyenv-doctor, pyenv-update)
- Updates shell profile files to initialize pyenv automatically for the user
- Provides detailed status messages and error handling for each step

### post-start.sh
Executed every time the container starts. Main actions:
- Ensures pyenv is initialized in the shell environment.
- Validates that the expected Python version is available and set as global.
- Performs quick checks to verify pyenv and Python setup.
- Optionally starts background services or performs environment health checks.

### post-attach.sh
Executed when a user attaches to the container. Main actions:
- Displays current pyenv and Python status, including the active version.
- Provides user guidance and tips for using pyenv in the container.
- Performs final verification of the environment and notifies the user of any issues.

All scripts use color-coded logging for clear status and error messages. Scripts are copied to `/usr/local/share/pyenv/scripts/` during installation and are invoked automatically by the devcontainer feature lifecycle.


## Installation Details

The feature installs system dependencies and build tools required for compiling Python. pyenv itself is installed per-user in the post-create script to ensure proper permissions and configuration. Scripts and configuration files are copied to `/usr/local/share/pyenv/`.

## OS Support

This feature has been tested on:
- Debian
- Ubuntu

## Version

Current version: 1.0.0

## License

See the repository's license file.
