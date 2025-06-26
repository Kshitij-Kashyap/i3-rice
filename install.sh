#!/bin/bash

# i3-rice Installation Script
# This script checks requirements, installs missing dependencies, and installs configuration files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory (where this script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE="$SCRIPT_DIR/.config"
HOME_CONFIG="$HOME/.config"

# Backup directory
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        i3-rice Installation          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if source directory exists
if [ ! -d "$CONFIG_SOURCE" ]; then
    print_error "Configuration source directory not found: $CONFIG_SOURCE"
    exit 1
fi

print_info "Source directory: $CONFIG_SOURCE"
print_info "Target directory: $HOME_CONFIG"

# Function to detect package manager
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Function to install packages based on package manager
install_packages() {
    local packages=("$@")
    local pkg_manager=$(detect_package_manager)
    
    if [ "$pkg_manager" = "unknown" ]; then
        print_error "No supported package manager found (pacman, apt, dnf, zypper)"
        print_info "Please install the following packages manually: ${packages[*]}"
        return 1
    fi
    
    print_info "Using package manager: $pkg_manager"
    
    case "$pkg_manager" in
        "pacman")
            sudo pacman -S --needed "${packages[@]}"
            ;;
        "apt")
            sudo apt update && sudo apt install -y "${packages[@]}"
            ;;
        "dnf")
            sudo dnf install -y "${packages[@]}"
            ;;
        "zypper")
            sudo zypper install -y "${packages[@]}"
            ;;
    esac
}

# Define dependencies and their package names for different distros
declare -A DEPS_PACMAN=(
    ["i3"]="i3-wm"
    ["polybar"]="polybar"
    ["rofi"]="rofi"
    ["picom"]="picom"
    ["kitty"]="kitty"
    ["dunst"]="dunst"
    ["fish"]="fish"
)

declare -A DEPS_APT=(
    ["i3"]="i3-wm"
    ["polybar"]="polybar"
    ["rofi"]="rofi"
    ["picom"]="picom"
    ["kitty"]="kitty"
    ["dunst"]="dunst"
    ["fish"]="fish"
)

declare -A DEPS_DNF=(
    ["i3"]="i3"
    ["polybar"]="polybar"
    ["rofi"]="rofi"
    ["picom"]="picom"
    ["kitty"]="kitty"
    ["dunst"]="dunst"
    ["fish"]="fish"
)

# Check dependencies and install if needed
check_and_install_dependencies() {
    local pkg_manager=$(detect_package_manager)
    local -n deps_ref
    
    case "$pkg_manager" in
        "pacman") deps_ref=DEPS_PACMAN ;;
        "apt") deps_ref=DEPS_APT ;;
        "dnf"|"zypper") deps_ref=DEPS_DNF ;;
        *) deps_ref=DEPS_PACMAN ;;  # fallback
    esac
    
    echo -e "\n${BLUE}Checking dependencies...${NC}"
    
    local missing_deps=()
    local missing_packages=()
    
    for dep in "${!deps_ref[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_status "$dep found"
        else
            print_warning "$dep not found"
            missing_deps+=("$dep")
            missing_packages+=("${deps_ref[$dep]}")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${BLUE}Required packages: ${missing_packages[*]}${NC}"
        
        if [ "$pkg_manager" = "unknown" ]; then
            print_error "Cannot auto-install packages: unsupported package manager"
            print_info "Please install these packages manually: ${missing_packages[*]}"
            echo -e "\n${YELLOW}Continue anyway? (y/N):${NC} "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                print_info "Installation cancelled"
                exit 1
            fi
        else
            echo -e "\n${YELLOW}Install missing dependencies automatically? (Y/n):${NC} "
            read -r response
            if [[ "$response" =~ ^[Nn]$ ]]; then
                print_warning "Skipping dependency installation"
                echo -e "${YELLOW}Continue with configuration installation anyway? (y/N):${NC} "
                read -r continue_response
                if [[ ! "$continue_response" =~ ^[Yy]$ ]]; then
                    print_info "Installation cancelled"
                    exit 1
                fi
            else
                print_info "Installing missing dependencies..."
                if install_packages "${missing_packages[@]}"; then
                    print_status "Dependencies installed successfully"
                else
                    print_error "Failed to install some dependencies"
                    echo -e "${YELLOW}Continue anyway? (y/N):${NC} "
                    read -r continue_response
                    if [[ ! "$continue_response" =~ ^[Yy]$ ]]; then
                        print_info "Installation cancelled"
                        exit 1
                    fi
                fi
            fi
        fi
    else
        print_status "All dependencies are satisfied"
    fi
}

# Run dependency check
check_and_install_dependencies

# Create backup directory
print_info "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Function to backup existing config
backup_config() {
    local config_name="$1"
    local target_path="$HOME_CONFIG/$config_name"
    
    if [ -e "$target_path" ]; then
        print_warning "Backing up existing $config_name configuration"
        cp -r "$target_path" "$BACKUP_DIR/"
        return 0
    fi
    return 1
}

# Function to install config directory
install_config() {
    local config_name="$1"
    local source_path="$CONFIG_SOURCE/$config_name"
    local target_path="$HOME_CONFIG/$config_name"
    local check_binary="$2"
    
    if [ ! -e "$source_path" ]; then
        print_warning "Skipping $config_name (not found in source)"
        return
    fi
    
    # Check if the corresponding program is installed (optional check)
    if [ -n "$check_binary" ] && ! command -v "$check_binary" >/dev/null 2>&1; then
        print_warning "Skipping $config_name (program not installed: $check_binary)"
        return
    fi
    
    # Backup existing config if it exists
    backup_config "$config_name"
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target_path")"
    
    # Copy configuration
    print_status "Installing $config_name configuration"
    cp -r "$source_path" "$target_path"
    
    # Make shell scripts executable
    find "$target_path" -name "*.sh" -type f -exec chmod +x {} \;
}

# Function to install configs only for installed programs
install_configs_smart() {
    local configs_to_install=()
    
    # Check which programs are installed and add their configs
    [ -d "$CONFIG_SOURCE/i3" ] && command -v i3 >/dev/null 2>&1 && configs_to_install+=("i3")
    [ -d "$CONFIG_SOURCE/kitty" ] && command -v kitty >/dev/null 2>&1 && configs_to_install+=("kitty")
    [ -d "$CONFIG_SOURCE/picom" ] && command -v picom >/dev/null 2>&1 && configs_to_install+=("picom")
    [ -d "$CONFIG_SOURCE/polybar" ] && command -v polybar >/dev/null 2>&1 && configs_to_install+=("polybar")
    [ -d "$CONFIG_SOURCE/fish" ] && command -v fish >/dev/null 2>&1 && configs_to_install+=("fish")
    [ -d "$CONFIG_SOURCE/rofi" ] && command -v rofi >/dev/null 2>&1 && configs_to_install+=("rofi")
    [ -d "$CONFIG_SOURCE/dunst" ] && command -v dunst >/dev/null 2>&1 && configs_to_install+=("dunst")
    
    if [ ${#configs_to_install[@]} -eq 0 ]; then
        print_warning "No configurations to install (no corresponding programs found)"
        return
    fi
    
    echo -e "\n${BLUE}Will install configurations for: ${configs_to_install[*]}${NC}"
    echo -e "${YELLOW}Install all available configurations regardless of installed programs? (y/N):${NC} "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Install all configs
        local all_configs=("i3" "kitty" "picom" "polybar" "fish" "rofi" "dunst")
        for config in "${all_configs[@]}"; do
            install_config "$config"
        done
    else
        # Install only configs for installed programs
        for config in "${configs_to_install[@]}"; do
            install_config "$config"
        done
    fi
}

echo -e "\n${BLUE}Installing configurations...${NC}"

# Install configurations intelligently
install_configs_smart

# Set executable permissions for scripts
print_info "Setting executable permissions for scripts..."
find "$HOME_CONFIG/polybar" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$HOME_CONFIG/rofi" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Summary
echo -e "\n${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Installation Complete        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"

print_status "All configurations installed successfully!"
print_info "Backup created at: $BACKUP_DIR"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Restart i3 or reload configuration: \$mod+Shift+r"
echo "2. Check polybar modules and update system-specific settings"
echo "3. Customize colors and themes in rofi configuration"
echo "4. Configure any program-specific settings as needed"

# Final verification
echo -e "\n${BLUE}Final dependency check...${NC}"
final_missing=()
for dep in i3 polybar rofi picom kitty dunst; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        final_missing+=("$dep")
    fi
done

if [ ${#final_missing[@]} -gt 0 ]; then
    print_warning "Still missing: ${final_missing[*]}"
    print_info "You may want to install these manually later"
else
    print_status "All dependencies are now satisfied!"
fi

echo -e "\n${GREEN}Installation script completed!${NC}"
