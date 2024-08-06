# Repository and version information
$REPO_OWNER = "hyperspaceai"
$REPO_SLUG = "aios-cli"
$CUDA_VERSION = "12.5.1"
$CUDA_PACKAGE_VERSION = "12-5"
$CUDA_PATH_VERSION = "12.5"

$LOG_FILE = "$env:TEMP\hyperspace_install.log"
$VERBOSE = $false

param([switch]$Elevated)

function log {
    param (
        [string]$level,
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$level] $message" | Out-File -Append -FilePath $LOG_FILE
    if ($VERBOSE) {
        Write-Host "[$level] $message"
    }
}

function echo_and_log {
    param (
        [string]$level,
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$level] $message" | Out-File -Append -FilePath $LOG_FILE
    Write-Host $message
}

# Parse command line arguments
$args | ForEach-Object {
    switch ($_) {
        {$_ -in "-v", "--verbose"} { $VERBOSE = $true }
    }
}

# Function to check and request admin privileges
function Request-AdminPrivileges {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        if ($elevated) {
            echo_and_log "ERROR" "Failed to elevate privileges. Please run this script as an administrator."
            exit 1
        } else {
            echo_and_log "WARN" "This script requires administrator privileges. Attempting to elevate..."
            Start-Process powershell.exe -Verb RunAs -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" -Elevated" -f ($myinvocation.MyCommand.Definition))
        }
        exit
    }
    echo_and_log "INFO" "Running with administrator privileges."
}

function Detect-WindowsVersion {
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($osInfo.Caption -like "*Server 2022*") {
        return "Server2022"
    } elseif ([System.Environment]::OSVersion.Version.Major -eq 10) {
        if ([System.Environment]::OSVersion.Version.Build -ge 22000) {
            return "Windows11"
        } else {
            return "Windows10"
        }
    } else {
        return "Unknown"
    }
}

function Check-NvidiaGPU {
    $gpu = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
    return $null -ne $gpu
}

function Check-CUDA {
    return Test-Path "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CUDA_PATH_VERSION"
}

function Install-CUDA {
    $windowsVersion = Detect-WindowsVersion
    $cudaUrl = "https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/cuda_${CUDA_VERSION}_555.85_windows.exe"

    echo_and_log "INFO" "Downloading CUDA installer..."
    $installerPath = "$env:TEMP\cuda_installer.exe"
    Invoke-WebRequest -Uri $cudaUrl -OutFile $installerPath

    echo_and_log "INFO" "Installing CUDA..."
    Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait

    # Clean up
    Remove-Item $installerPath

    echo_and_log "INFO" "CUDA $CUDA_VERSION installation complete."

    if (-not (Check-CUDA)) {
        echo_and_log "ERROR" "CUDA installation validation failed. Please check your installation."
        return $false
    }

    # Set up environment variables
    $cudaPath = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$CUDA_PATH_VERSION"
    $env:PATH += ";$cudaPath\bin"
    $env:PATH += ";$cudaPath\libnvvp"
    [System.Environment]::SetEnvironmentVariable("PATH", $env:PATH, [System.EnvironmentVariableTarget]::Machine)

    return $true
}
function Fetch-LatestRelease {
    $url = "https://api.github.com/repos/$REPO_OWNER/$REPO_SLUG/releases/latest"
    $response = Invoke-RestMethod -Uri $url
    return $response
}

function Get-DownloadUrl {
    param (
        [bool]$hasCuda
    )
    if ($hasCuda) {
        return "https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-x86_64-pc-windows-msvc-cuda.zip"
    } else {
        return "https://github.com/$REPO_OWNER/$REPO_SLUG/releases/latest/download/aios-cli-x86_64-pc-windows-msvc.zip"
    }
}

function Download-WithRetry {
    param (
        [string]$url,
        [string]$output
    )
    $maxAttempts = 3
    $attempt = 1

    while ($attempt -le $maxAttempts) {
        try {
            Invoke-WebRequest -Uri $url -OutFile $output
            echo_and_log "INFO" "Download successful: $output"
            return $true
        } catch {
            echo_and_log "WARN" "Attempt $attempt failed. Retrying in 5 seconds..."
            Start-Sleep -Seconds 5
            $attempt++
        }
    }

    echo_and_log "ERROR" "Failed to download after $maxAttempts attempts."
    return $false
}

function Install-Binary {
    param (
        [string]$filename
    )
    $installDir = "$env:ProgramFiles\AIOS"

    echo_and_log "INFO" "Extracting $filename..."
    Expand-Archive -Path $filename -DestinationPath $env:TEMP\aios-temp

    $binaryName = "aios-cli.exe"
    $binaryPath = Get-ChildItem -Path $env:TEMP\aios-temp -Recurse -Filter $binaryName | Select-Object -First 1 -ExpandProperty FullName

    if (-not $binaryPath) {
        echo_and_log "ERROR" "Binary not found in the extracted files."
        return $false
    }

    echo_and_log "WARN" "Moving binary to $installDir"
    echo_and_log "WARN" "You may be prompted for administrator permissions to move the binary to $installDir."
    if (-not (Test-Path $installDir)) {
        New-Item -ItemType Directory -Path $installDir | Out-Null
    }
    Move-Item $binaryPath $installDir

    # Add to PATH
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$installDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$installDir", "User")
    }

    # Clean up
    Remove-Item $filename
    Remove-Item $env:TEMP\aios-temp -Recurse

    # Validate installation
    if (-not (Get-Command aios-cli -ErrorAction SilentlyContinue)) {
        echo_and_log "ERROR" "Installation validation failed. The 'aios-cli' command is not available in PATH."
        return $false
    }

    echo_and_log "INFO" "Binary installed successfully. You can now run it by typing 'aios-cli'"
    return $true
}

function Main {
    # Check for admin privileges first
    Request-AdminPrivileges

    echo_and_log "INFO" "Starting AIOS CLI installation..."

    $windowsVersion = Detect-WindowsVersion
    log "INFO" "Detected Windows version: $windowsVersion"

    if ($windowsVersion -eq "Unknown") {
        echo_and_log "ERROR" "Unsupported Windows version."
        exit 1
    }

    echo_and_log "INFO" "Fetching latest release..."
    $releaseData = Fetch-LatestRelease
    if (-not $releaseData) {
        echo_and_log "ERROR" "Failed to fetch release data."
        exit 1
    }

    $version = $releaseData.tag_name
    echo_and_log "INFO" "Latest version: $version"

    $hasCuda = $false
    if (Check-NvidiaGPU) {
        log "INFO" "NVIDIA GPU detected."
        if (-not (Check-CUDA)) {
            echo_and_log "INFO" "CUDA is not installed."
            $installCuda = Read-Host "Do you want to install CUDA drivers? (y/n)"
            if ($installCuda -eq "y") {
                if (Install-CUDA) {
                    echo_and_log "INFO" "CUDA installation completed successfully."
                    $hasCuda = $true
                } else {
                    echo_and_log "ERROR" "CUDA installation failed."
                    echo_and_log "INFO" "Proceeding with non-CUDA version."
                }
            } else {
                echo_and_log "INFO" "Proceeding without CUDA."
            }
        } else {
            log "INFO" "CUDA is already installed."
            $hasCuda = $true
        }
    } else {
        log "INFO" "No NVIDIA GPU detected. Proceeding without CUDA."
    }

    $downloadUrl = Get-DownloadUrl -hasCuda $hasCuda
    if (-not $downloadUrl) {
        echo_and_log "ERROR" "Failed to determine appropriate download URL."
        exit 1
    }

    log "INFO" "Download URL: $downloadUrl"

    $filename = Split-Path -Leaf $downloadUrl
    echo_and_log "INFO" "Downloading $filename..."

    if (-not (Download-WithRetry $downloadUrl "$env:TEMP\$filename")) {
        echo_and_log "ERROR" "Download failed. Please check your internet connection and try again."
        exit 1
    }

    echo_and_log "INFO" "Download complete"

    if (-not (Install-Binary "$env:TEMP\$filename")) {
        echo_and_log "ERROR" "Installation failed."
        exit 1
    }

    echo_and_log "SUCCESS" "Installation completed successfully."
}

# Run the main function
if (-NOT $elevated) {
    Main
}
