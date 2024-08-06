#!/bin/bash

set -e


# Function to remove the binary
remove_binary() {
    local binary_name="aios-cli"
    local install_dir="/usr/local/bin"
    local full_path="$install_dir/$binary_name"

    if [ -f "$full_path" ]; then
        echo "Removing $binary_name..."
        if sudo rm "$full_path"; then
            echo "$binary_name removed successfully."
        else
            echo "Error: Failed to remove $binary_name. Please check your permissions."
            return 1
        fi
    else
        echo "Warning: $binary_name not found in $install_dir. It may have already been uninstalled or installed elsewhere."
    fi

    return 0
}

# Main uninstall function
main() {
    echo "Starting aiOs cli uninstallation..."

    if remove_binary; then
        echo "AIOS CLI binary uninstalled successfully."
    else
        echo "Error: Failed to uninstall AIOS CLI binary."
        exit 1
    fi

    echo "Uninstallation completed. AIOS CLI has been removed from your system."
}

# Run the main function
main
