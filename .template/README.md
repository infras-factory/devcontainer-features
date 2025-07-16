# DevContainer Feature Cookiecutter Template

This is a cookiecutter template for quickly creating new devcontainer features with a consistent structure and best practices.

## Prerequisites

Install cookiecutter:
```bash
pip install cookiecutter
```

## Usage

1. Generate a new feature from this template:
```bash
cookiecutter template/
```

2. Answer the prompts:
   - `feature_id`: Unique identifier for your feature (e.g., `my-tool`)
   - `feature_name`: Human-readable name (e.g., `My Tool`)
   - `feature_description`: Brief description of what your feature does
   - `feature_version`: Initial version (default: `1.0.0`)
   - `documentation_url`: URL to your documentation

3. Your new feature will be created with the following structure:
```
your-feature-id/
├── src/
│   └── your-feature-id/
│       ├── devcontainer-feature.json
│       ├── install.sh
│       ├── README.md
│       ├── configs/
│       │   └── .gitkeep
│       └── scripts/
│           ├── post-create.sh
│           ├── post-start.sh
│           └── post-attach.sh
└── test/
    └── your-feature-id/
        ├── scenarios.json
        ├── test.sh
        ├── test-debian.sh
        └── test-ubuntu.sh
```

4. Move the generated feature to the appropriate location:
```bash
mv your-feature-id/src/your-feature-id src/
mv your-feature-id/test/your-feature-id test/
rm -rf your-feature-id
```

5. Implement your feature:
   - Edit `install.sh` to add installation logic
   - Update lifecycle scripts as needed
   - Add configuration files to `configs/`
   - Update tests in `test/your-feature-id/`
   - Update the README.md with specific details

## Template Structure

### Source Files (`src/`)
- **devcontainer-feature.json**: Feature metadata and configuration
- **install.sh**: Main installation script (runs as root during build)
- **README.md**: Feature documentation
- **configs/**: Configuration files to be copied to user's home
- **scripts/**: Lifecycle scripts that run at different container stages

### Test Files (`test/`)
- **scenarios.json**: Test scenarios for Debian and Ubuntu
- **test.sh**: Default test script
- **test-debian.sh**: Debian-specific tests
- **test-ubuntu.sh**: Ubuntu-specific tests

## Lifecycle Scripts

- **post-create.sh**: Runs once after container creation (user context)
- **post-start.sh**: Runs every time the container starts
- **post-attach.sh**: Runs when attaching to the container

## Best Practices

1. **Separation of Concerns**:
   - System-level operations in `install.sh`
   - User-level operations in lifecycle scripts

2. **Logging**:
   - Use color-coded logging functions
   - Include timestamps in log messages
   - Save logs to `/tmp/` for debugging

3. **Error Handling**:
   - Use `set -e` in all scripts
   - Provide informative error messages
   - Handle failures gracefully

4. **Testing**:
   - Test on both Debian and Ubuntu
   - Check both installation and functionality
   - Verify file permissions

5. **Documentation**:
   - Clear README with examples
   - Document all options
   - Include troubleshooting tips

## Example: Creating a Node.js Feature

```bash
cookiecutter template/

# Responses:
feature_id: nodejs
feature_name: Node.js
feature_description: Installs Node.js and npm with version management
feature_version: 1.0.0
documentation_url: https://github.com/infras-factory/devcontainer-features
```

This will create a fully structured Node.js feature ready for implementation.
