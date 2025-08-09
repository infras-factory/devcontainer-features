#!/bin/bash

set -e

# ----------------------------------------
# utils/layer-0/package-manager.sh - Package manager detection and installation utilities
# ----------------------------------------

# Cache for package manager detection
DETECTED_PACKAGE_MANAGER=""

# Function to validate package name (security)
validate_package_name() {
    local package_name="$1"

    # Only allow alphanumeric, hyphens, underscores, dots, and plus
    if [[ ! "$package_name" =~ ^[a-zA-Z0-9._+-]+$ ]]; then
        echo "ERROR: Invalid package name: $package_name" >&2
        return 1
    fi

    # Check for suspicious patterns
    if [[ "$package_name" =~ \.\.  ]] || [[ "$package_name" =~ // ]]; then
        echo "ERROR: Suspicious package name pattern: $package_name" >&2
        return 1
    fi

    return 0
}

# Function to detect the package manager with caching
detect_package_manager_cached() {
    if [[ -z "$DETECTED_PACKAGE_MANAGER" ]]; then
        DETECTED_PACKAGE_MANAGER=$(detect_package_manager)
    fi
    echo "$DETECTED_PACKAGE_MANAGER"
}

# Function to detect the package manager
detect_package_manager() {
    if command -v apk &> /dev/null; then
        echo "apk"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Function to update package manager cache
update_package_cache() {
    local pkg_manager="$1"

    case "$pkg_manager" in
        "apk")
            sudo apk update
            ;;
        "apt")
            sudo apt-get update
            ;;
        "yum")
            sudo yum makecache
            ;;
        "dnf")
            sudo dnf makecache
            ;;
        "zypper")
            sudo zypper refresh
            ;;
        "pacman")
            sudo pacman -Sy
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to install a package
install_package() {
    local package_name="$1"
    local pkg_manager="${2:-$(detect_package_manager_cached)}"

    # Validate package name for security
    if ! validate_package_name "$package_name"; then
        return 1
    fi

    case "$pkg_manager" in
        "apk")
            sudo apk add --no-cache "$package_name"
            ;;
        "apt")
            # Update package cache first for Debian/Ubuntu
            sudo apt-get update
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package_name"
            ;;
        "yum")
            sudo yum install -y "$package_name"
            ;;
        "dnf")
            sudo dnf install -y "$package_name"
            ;;
        "zypper")
            sudo zypper install -y "$package_name"
            ;;
        "pacman")
            sudo pacman -S --noconfirm "$package_name"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if a package is installed
is_package_installed() {
    local package_name="$1"
    local pkg_manager="${2:-$(detect_package_manager_cached)}"

    case "$pkg_manager" in
        "apk")
            apk info -e "$package_name" &> /dev/null
            ;;
        "apt")
            dpkg -l "$package_name" 2>/dev/null | grep -q "^ii"
            ;;
        "yum"|"dnf")
            rpm -q "$package_name" &> /dev/null
            ;;
        "zypper")
            zypper se -i "$package_name" &> /dev/null
            ;;
        "pacman")
            pacman -Q "$package_name" &> /dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to get package name based on distribution
# Usage: get_package_name "generic_name" "pkg_manager"
# Example: get_package_name "bat" "apt" returns "bat"
get_package_name() {
    local generic_name="$1"
    local pkg_manager="${2:-$(detect_package_manager_cached)}"

    # Package name mappings
    case "$generic_name" in
        "bat")
            case "$pkg_manager" in
                "apt") echo "bat" ;;  # In newer versions, it's 'bat' not 'batcat'
                *) echo "bat" ;;
            esac
            ;;
        "fd")
            case "$pkg_manager" in
                "apt") echo "fd-find" ;;
                *) echo "fd" ;;
            esac
            ;;
        *)
            echo "$generic_name"
            ;;
    esac
}

# Function to get binary name after installation
# Some packages install with different binary names
get_binary_name() {
    local package_name="$1"
    local pkg_manager="${2:-$(detect_package_manager_cached)}"

    case "$package_name" in
        "bat")
            # On older Ubuntu/Debian, bat installs as batcat
            if [ "$pkg_manager" = "apt" ] && command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
                echo "batcat"
            else
                echo "bat"
            fi
            ;;
        "fd-find")
            echo "fdfind"
            ;;
        *)
            echo "$package_name"
            ;;
    esac
}

# Function to install package with fallback options and verification
install_package_smart() {
    local generic_name="$1"
    local pkg_manager="${2:-$(detect_package_manager_cached)}"

    # Validate input
    if ! validate_package_name "$generic_name"; then
        return 1
    fi

    # Check if already installed
    local binary_name
    binary_name=$(get_binary_name "$generic_name" "$pkg_manager")
    if command -v "$binary_name" &> /dev/null; then
        return 0
    fi

    # Get the correct package name for this distribution
    local package_name
    package_name=$(get_package_name "$generic_name" "$pkg_manager")

    # Try to install
    if install_package "$package_name" "$pkg_manager"; then
        # Verify installation
        binary_name=$(get_binary_name "$package_name" "$pkg_manager")
        if command -v "$binary_name" &> /dev/null; then
            return 0
        else
            echo "WARNING: Package $package_name installed but binary not found in PATH" >&2
            return 1
        fi
    else
        # If failed, try the generic name as fallback
        if [ "$package_name" != "$generic_name" ]; then
            if install_package "$generic_name" "$pkg_manager"; then
                # Verify installation
                binary_name=$(get_binary_name "$generic_name" "$pkg_manager")
                if command -v "$binary_name" &> /dev/null; then
                    return 0
                fi
            fi
        fi
        return 1
    fi
}

# Function to install multiple packages in parallel (for performance)
install_packages_parallel() {
    local pkg_manager="${1:-$(detect_package_manager_cached)}"
    shift  # Remove first argument
    local packages=("$@")
    local pids=()
    local failed=0

    # Start parallel installations
    for package in "${packages[@]}"; do
        (
            if install_package_smart "$package" "$pkg_manager"; then
                echo "SUCCESS: $package installed" >&2
            else
                echo "FAILED: $package installation failed" >&2
                exit 1
            fi
        ) &
        pids+=($!)
    done

    # Wait for all installations to complete
    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            failed=$((failed + 1))
        fi
    done

    return $failed
}
