# Oh My Zsh (ohmyzsh)

Pre-install Oh My Zsh theme and plugins for enhanced terminal experience.

## Example Usage

```json
"features": {
    "ghcr.io/YOUR_GITHUB_USERNAME/devcontainer-features/ohmyzsh:1": {}
}
```

## Options

This feature doesn't have any configurable options at the moment.

## What This Feature Does

This feature automatically:
- Installs Oh My Zsh if not already present
- Configures default theme and plugins
- Sets up Zsh as the default shell
- Runs post-create and post-start scripts for additional customization

## Prerequisites

This feature requires:
- `ghcr.io/devcontainers/features/common-utils` - For basic utilities
- `ghcr.io/devcontainers/features/git` - For Git functionality

These dependencies will be automatically installed before this feature.

## Post-Installation Scripts

- **Post-Create**: Runs `/usr/local/share/scripts/post-create.sh` after container creation
- **Post-Start**: Runs `/usr/local/share/scripts/post-start.sh` each time container starts

## OS Support

 Debian-based distributions (Debian, Ubuntu)
 Alpine Linux
 RedHat-based distributions (RHEL, CentOS, Fedora)

## Version

Current version: 1.0.0

---

_Note: This feature is part of the devcontainer-features collection._
