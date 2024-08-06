# Uninstallation script for AIOS CLI

$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

$INSTALL_DIR = "$env:ProgramFiles\AIOS"
$LOG_FILE = "$env:TEMP\aios_uninstall.log"

function Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Tee-Object -Append -FilePath $LOG_FILE
}

function Remove-FromPath {
    $path = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = ($path.Split(';') | Where-Object { $_ -ne $INSTALL_DIR }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Log "Removed AIOS directory from PATH"
}

function Remove-InstallDirectory {
    if (Test-Path $INSTALL_DIR) {
        Remove-Item -Path $INSTALL_DIR -Recurse -Force
        Log "Removed installation directory: $INSTALL_DIR"
    } else {
        Log "Installation directory not found: $INSTALL_DIR"
    }
}

function Remove-RelatedEnvVars {
    $envVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*AIOS*" -or $_.Name -like "*CUDA*" }
    foreach ($var in $envVars) {
        [Environment]::SetEnvironmentVariable($var.Name, $null, "User")
        [Environment]::SetEnvironmentVariable($var.Name, $null, "Machine")
        Log "Removed environment variable: $($var.Name)"
    }
}

function Main {
    Log "Starting AIOS CLI uninstallation"

    try {
        Remove-FromPath
        Remove-InstallDirectory
        Remove-RelatedEnvVars

        Log "AIOS CLI uninstallation completed successfully"
        Write-Host "AIOS CLI has been uninstalled. Please restart your terminal or system for changes to take effect."
    } catch {
        Log "Error during uninstallation: $_"
        Write-Host "An error occurred during uninstallation. Please check the log file: $LOG_FILE"
    }
}

# Run the main function
Main
