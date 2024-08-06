#!/bin/bash

set -e

trap 'echo_and_log "ERROR" "Script exited unexpectedly on line $LINENO. Last command: $BASH_COMMAND"' ERR

# Repository and version information
REPO_OWNER="hyperspaceai"
REPO_SLUG="aios-cli"
CUDA_VERSION="12.5.1"
CUDA_PACKAGE_VERSION="12-5"
CUDA_PATH_VERSION="12.5"

LOG_FILE="/tmp/hyperspace_install.log"
VERBOSE=false

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'


log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    if [ "$VERBOSE" = true ]; then
        echo_and_log "$level" "$message"
    fi
}

echo_and_log() {
    local level="$1"
    local message="$2"
    local color_start=""
    case $level in
        "ERROR") color_start="${RED}" ;;
        "SUCCESS") color_start="${GREEN}" ;;
        "INFO") color_start="${BLUE}" ;;
        "WARN") color_start="${YELLOW}" ;;
        *) color_start="" ;;
    esac
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Replace color tags in the message
    message="${message//\{\{ERROR\}\}/${RED}}"
    message="${message//\{\{SUCCESS\}\}/${GREEN}}"
    message="${message//\{\{INFO\}\}/${BLUE}}"
    message="${message//\{\{WARN\}\}/${YELLOW}}"
    message="${message//\{\{NC\}\}/${NC}}"

    if [ "$VERBOSE" = true ]; then
        echo -e "${color_start}[$level]${NC} ${color_start}${message}${NC}"
    else
        echo -e "${color_start}${message}${NC}"
    fi
}


# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
        *) shift ;;
    esac
done

# Detect the operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Detect Mac architecture (silicon or intel)
detect_mac_arch() {
    if [[ $(uname -m) == "arm64" ]]; then
        echo "silicon"
    else
        echo "intel"
    fi
}

# Check for NVIDIA GPU presence
check_nvidia_gpu() {
    if is_wsl; then
        if command -v nvidia-smi &> /dev/null; then
            nvidia-smi &> /dev/null
            return $?
        else
            return 1
        fi
    else
        lspci 2>/dev/null | grep -i nvidia &> /dev/null
    fi
}

# Check if CUDA is installed
check_cuda() {
    command -v nvcc &> /dev/null
}

handle_cuda_wsl() {
    log "INFO" "Checking CUDA support in WSL..."
    if check_cuda; then
        log "INFO" "CUDA is available in this WSL environment."
        log "INFO" "Using CUDA from Windows host system."
        return 0
    else
        echo_and_log "WARN" "CUDA is not detected in this WSL environment."
        echo_and_log "INFO" "To use CUDA in WSL2, please ensure:"
        echo_and_log "INFO" "1. You have installed the NVIDIA CUDA on WSL driver on your Windows host."
        echo_and_log "INFO" "2. You are using WSL2 (not WSL1)."
        echo_and_log "INFO" "3. Your Windows host has CUDA-capable NVIDIA GPU and up-to-date drivers."
        echo_and_log "INFO" "For more information, visit: https://docs.nvidia.com/cuda/wsl-user-guide/index.html"
        return 1
    fi
}

# Install CUDA on supported Linux distributions
install_cuda() {
    echo_and_log "INFO" "Installing CUDA $CUDA_VERSION..."

    if [ ! -f /etc/os-release ]; then
        echo "ERROR" "Error: Cannot determine OS version. Aborting CUDA installation."
        return 1
    fi

    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID

    # Temporary file to store downloaded .deb
    local temp_deb="cuda_installer.deb"

    case $OS in
        "ubuntu"|"pop")
            case $VER in
                "20.04"|"22.04"|"24.04")
                    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu${VER/./}/x86_64/cuda-ubuntu${VER/./}.pin
                    sudo mv cuda-ubuntu${VER/./}.pin /etc/apt/preferences.d/cuda-repository-pin-600
                    wget -O "$temp_deb" https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda-repo-ubuntu${VER/./}-${CUDA_PACKAGE_VERSION}-local_${CUDA_VERSION}-555.42.06-1_amd64.deb
                    sudo dpkg -i "$temp_deb"
                    sudo cp /var/cuda-repo-ubuntu${VER/./}-${CUDA_PACKAGE_VERSION}-local/cuda-*-keyring.gpg /usr/share/keyrings/
                    ;;
                *)
                    echo "Error: Unsupported Ubuntu version. Aborting CUDA installation."
                    return 1
                    ;;
            esac
            ;;
        "debian")
            wget -O "$temp_deb" https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda-repo-debian12-${CUDA_PACKAGE_VERSION}-local_${CUDA_VERSION}-555.42.06-1_amd64.deb
            sudo dpkg -i "$temp_deb"
            sudo cp /var/cuda-repo-debian12-${CUDA_PACKAGE_VERSION}-local/cuda-*-keyring.gpg /usr/share/keyrings/
            sudo add-apt-repository contrib
            ;;
        *)
            echo "Error: Unsupported OS for automatic CUDA installation. Please install CUDA manually."
            return 1
            ;;
    esac

    sudo apt-get update || { log "Error: Failed to update package lists."; rm "$temp_deb"; return 1; }
    sudo apt-get -y install cuda-toolkit-${CUDA_PACKAGE_VERSION} || { log "Error: Failed to install CUDA toolkit."; rm "$temp_deb"; return 1; }

    # Clean up
    rm "$temp_deb"


    # Perform post-installation actions
    echo "Performing post-installation actions..."

    # Create cuda.sh in /etc/profile.d/ to set up the environment for all users
    sudo tee /etc/profile.d/cuda.sh > /dev/null <<EOT
export PATH=/usr/local/cuda-${CUDA_PATH_VERSION}/bin\${PATH:+:\${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-${CUDA_PATH_VERSION}/lib64\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
EOT

    # Make cuda.sh executable
    sudo chmod +x /etc/profile.d/cuda.sh

    # Source cuda.sh in the current session
    source /etc/profile.d/cuda.sh

    echo "CUDA $CUDA_PATH_VERSION installation and environment setup complete."

    # Validate CUDA installation
    if ! check_cuda; then
        echo "Error: CUDA installation validation failed. Please check your installation and PATH."
        return 1
    fi

    echo_and_log "DEBUG" "CUDA installation function completed successfully."
    return 0
}

# Fetch the latest release information from GitHub
fetch_latest_release() {
    curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_SLUG/releases/latest"
}

# Get the download URL for the appropriate asset
get_download_url() {
    local os=$1
    local arch=$2

    local url=""
    case $os in
        macos)
            if [ "$arch" == "silicon" ]; then
                url="https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-aarch64-apple-darwin.tar.gz"
            else
                url="https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-x86_64-apple-darwin.tar.gz"
            fi
            ;;
        linux|ubuntu|debian|pop)
            if [ "$arch" == "cuda" ]; then
                url="https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-x86_64-unknown-linux-gnu-cuda.tar.gz"
            else
                url="https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-x86_64-unknown-linux-gnu.tar.gz"
            fi
            ;;
        *)
            echo_and_log "ERROR" "Unsupported OS: $os" >&2
            return 1
            ;;
    esac

    if [ -n "$url" ]; then
        log "DEBUG" "Download URL: $url" >&2
        echo "$url"
        return 0
    else
        echo_and_log "ERROR" "Failed to determine download URL for OS: $os, ARCH: $arch" >&2
        return 1
    fi
}

# Download file with retry mechanism
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1

    trap 'echo_and_log "ERROR" "Download interrupted. Cleaning up..."; rm -f "$output"; exit 1' INT TERM

    while [ $attempt -le $max_attempts ]; do
        if curl -L --fail -o "$output" "$url"; then
            trap - INT TERM
            return 0
        else
            echo_and_log "WARN" "Attempt $attempt failed. Retrying in 5 seconds..."
            sleep 5
            attempt=$((attempt + 1))
        fi
    done

    echo_and_log "ERROR" "Failed to download after $max_attempts attempts."
    rm -f "$output"
    trap - INT TERM
    return 1
}

install_binary() {
    local filename=$1
    local install_dir="$HOME/.aios"

    mkdir -p $install_dir
    echo_and_log "INFO" "Made aios home directory: $install_dir"

    echo_and_log "INFO" "Extracting $filename..."
    tar -xzf "$filename"

    
    local binary_name="aios-cli"

    
    local binary_path="./$binary_name"
    if [ ! -f "$binary_path" ]; then
        echo_and_log "ERROR" "Binary not found in the extracted files."
        return 1
    fi


    echo_and_log "WARN" "Moving binary to $install_dir"
    if mv "$binary_path" "$install_dir/$binary_name"; then
        echo_and_log "INFO" "Binary moved successfully, available at: $HOME/.aios/$binary_name"
    else
        echo_and_log "ERROR" "Failed to move the binary to $install_dir. Please check your permissions."
        return 1
    fi

    local shell_rc=$(get_shell_rc)
    log "INFO" "Detected shell's rc file: $shell_rc"

    if [[ -n "$AIOS_HOME" && "$PATH" == *"$AIOS_HOME"* ]]; then
        echo_and_log "INFO" "PATHs already set. Skipping..."
    else
        if [[ $shell_rc == "unknown" ]]; then
            echo_and_log "ERROR" "Couldn't detect your shell's rc file manually add this line to get it working:\n"
            echo "\nexport AIOS_HOME=$install_dir\nexport PATH=\"\$AIOS_HOME:\$PATH\""
            return 1
        else
            echo -e "\nexport AIOS_HOME=$install_dir\nexport PATH=\"\$AIOS_HOME:\$PATH\"" >> $shell_rc
            echo_and_log "INFO" "Binary added to path in your shells config at $shell_rc"
            echo_and_log "INFO" "To run $binary_name restart your shell or run \`source $shell_rc\`"
        fi
    fi



    # Clean up
    rm -f "$filename"

    return 0
}

is_wsl() {
    if grep -qi microsoft /proc/version; then
        return 0
    else
        return 1
    fi
}

get_shell_rc() {
    case $SHELL in
    */bash)
        echo ~/.bashrc
        ;;
    */zsh)
        echo ~/.zshrc
        ;;
    */fish)
        echo ~/.config/fish/config.fish
        ;;
    */tcsh)
        echo ~/.tcshrc
        ;;
    */ksh)
        echo ~/.kshrc
        ;;
    *)
        echo "unknown"
        ;;
    esac
}


# Main function to orchestrate the installation process
main() {
    local OS ARCH RELEASE_DATA VERSION DOWNLOAD_URL FILENAME

    echo_and_log "LOG" "Starting aiOs cli installation..."

    OS=$(detect_os)
    log "INFO" "Detected OS: $OS"

    if [ "$OS" == "unknown" ]; then
        echo_and_log "ERROR" "Unsupported operating system."
        exit 1
    fi


    echo_and_log "INFO" "Fetching latest release..."
    RELEASE_DATA=$(fetch_latest_release)
    if [ -z "$RELEASE_DATA" ]; then
        echo_and_log "ERROR" "Failed to fetch release data."
        exit 1
    fi

    VERSION=$(echo "$RELEASE_DATA" | grep -o '"tag_name": *"[^"]*"' | sed -E 's/"tag_name": "(.*)"/\1/')
    if [ -z "$VERSION" ]; then
        echo_and_log "ERROR" "Failed to parse version from release data."
        exit 1
    fi
    echo_and_log "LOG" "Latest version: {{INFO}}$VERSION{{NC}}"

    case $OS in
        macos)
            ARCH=$(detect_mac_arch)
            echo_and_log "INFO" "Detected Mac architecture: $ARCH"
            ;;
        linux)
            if is_wsl; then
                echo_and_log "WARN" "Running in WSL environment. Some features may be limited."
                echo_and_log "WARN" "CUDA installation may not work as expected in WSL."
                log "INFO" "WSL environment detected."
                if check_nvidia_gpu; then
                    log "INFO" "NVIDIA GPU detected in WSL."
                    if check_cuda; then
                        echo_and_log "INFO" "CUDA is available in this WSL environment."
                        ARCH="cuda"
                    else
                        echo_and_log "WARN" "CUDA is not detected in this WSL environment."
                        echo_and_log "INFO" "Proceeding with cpu version."
                        ARCH="nocuda"
                    fi
                else
                    echo_and_log "INFO" "No NVIDIA GPU detected in WSL. Proceeding with cpu version."
                    ARCH="nocuda"
                fi
            else
                if check_nvidia_gpu; then
                    log "INFO" "NVIDIA GPU detected."
                    if check_cuda; then
                        log "INFO" "CUDA is already installed."
                        ARCH="cuda"
                    else
                        echo_and_log "INFO" "CUDA is not installed."
                        read -p "Do you want to install CUDA drivers? (y/n) " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            echo_and_log "INFO" "Starting CUDA installation"
                            if install_cuda; then
                                echo_and_log "INFO" "CUDA installation completed successfully."
                                ARCH="cuda"
                            else
                                echo_and_log "ERROR" "CUDA installation failed."
                                echo_and_log "INFO" "Proceeding with non-CUDA version."
                                ARCH="nocuda"
                            fi
                        else
                            echo_and_log "INFO" "User chose not to install CUDA. Proceeding with non-CUDA version."
                            ARCH="nocuda"
                        fi
                    fi
                else
                    echo_and_log "INFO" "No NVIDIA GPU detected. Proceeding with cpu version."
                    ARCH="nocuda"
                fi
            fi
            ;;
        *)
            echo_and_log "ERROR" "Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    DOWNLOAD_URL=$(get_download_url "$OS" "$ARCH")
    if [ $? -ne 0 ] || [ -z "$DOWNLOAD_URL" ]; then
        echo_and_log "ERROR" "Failed to determine appropriate download URL."
        exit 1
    fi


    FILENAME=$(basename "$DOWNLOAD_URL")
    echo_and_log "INFO" "Downloading $FILENAME..."

    if ! download_with_retry "$DOWNLOAD_URL" "$FILENAME"; then
        echo_and_log "ERROR" "Download failed. Please check your internet connection and try again."
        exit 1
    fi

    echo_and_log "SUCCESS" "Download complete"

    if ! install_binary "$FILENAME"; then
        echo_and_log "ERROR" "Installation failed."
        exit 1
    fi

    echo_and_log "SUCCESS" "Installation completed successfully."
}

# Run the main function
main
