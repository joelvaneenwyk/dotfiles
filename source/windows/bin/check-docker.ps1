<#
.SYNOPSIS
    Docker troubleshooting script for Windows.

.DESCRIPTION
    This script provides tools to diagnose and fix common Docker issues on Windows.
    It includes functions to check Docker running status, verify WSL integration, and repair common problems.

.NOTES
    File Name      : check-docker.ps1
    Author         : Joel Van Eenwyk
    Prerequisite   : PowerShell 5.0 or later

    WARNING: This script is not well tested and should not be used in production environments.
    Use at your own risk and only in development environments.

.EXAMPLE
    .\check-docker.ps1
#>

# Test if Docker is running
function Test-DockerRunning {
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        Write-Host "Docker Desktop process is running" -ForegroundColor Green
    }
    else {
        Write-Host "Docker Desktop process is NOT running" -ForegroundColor Red
    }

    # Check Docker service
    $dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    if ($dockerService -and $dockerService.Status -eq "Running") {
        Write-Host "Docker service is running" -ForegroundColor Green
    }
    else {
        Write-Host "Docker service is NOT running" -ForegroundColor Red
    }
}

function Test-DockerLinuxEngineConnection {
    Write-Host "===== Docker WSL 2 Integration Troubleshooter =====" -ForegroundColor Cyan

    # Check if Docker Desktop is running
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        Write-Host "Docker Desktop process: RUNNING" -ForegroundColor Green
    }
    else {
        Write-Host "Docker Desktop process: NOT RUNNING" -ForegroundColor Red
        Write-Host "  Fix: Start Docker Desktop first" -ForegroundColor Yellow
        return
    }

    # Check WSL status
    try {
        $wslStatus = wsl --status
        Write-Host "WSL is installed and configured:" -ForegroundColor Green
        Write-Host $wslStatus -ForegroundColor Cyan

        # Check WSL version
        $wslVersion = wsl --version
        Write-Host "WSL version information:" -ForegroundColor Green
        Write-Host $wslVersion -ForegroundColor Cyan
    }
    catch {
        Write-Host "WSL is not properly installed or configured:" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host "  Fix: Install or update WSL with 'wsl --install' as administrator" -ForegroundColor Yellow
        return
    }

    # Check running WSL distros
    try {
        $runningDistros = wsl --list --running
        Write-Host "Running WSL distributions:" -ForegroundColor Green
        Write-Host $runningDistros -ForegroundColor Cyan

        if ($runningDistros -notmatch "docker-desktop") {
            Write-Host "Docker Desktop WSL distro is NOT running" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error checking WSL distributions:" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }

    # Check Docker Desktop settings
    $settingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            if ($settings.wslEngineEnabled) {
                Write-Host "Docker Desktop WSL 2 engine: ENABLED" -ForegroundColor Green
            }
            else {
                Write-Host "Docker Desktop WSL 2 engine: DISABLED" -ForegroundColor Yellow
                Write-Host "  Note: Docker is configured to use Hyper-V backend, not WSL 2" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error reading Docker settings:" -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Docker settings file not found" -ForegroundColor Red
    }

    # Check for Linux engine pipe
    if (Test-Path -Path "\\.\pipe\dockerDesktopLinuxEngine") {
        Write-Host "Docker Linux engine pipe exists: YES" -ForegroundColor Green
    }
    else {
        Write-Host "Docker Linux engine pipe exists: NO" -ForegroundColor Red
        Write-Host "  Fix: WSL integration is not working properly" -ForegroundColor Yellow
    }

    # Check for Windows engine pipe
    if (Test-Path -Path "\\.\pipe\docker_engine") {
        Write-Host "Docker Windows engine pipe exists: YES" -ForegroundColor Green
    }
    else {
        Write-Host "Docker Windows engine pipe exists: NO" -ForegroundColor Red
    }
}


# Add Docker to Windows Defender Firewall exceptions
function Add-DockerFirewallException {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "This function requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }

    try {
        $dockerPath = "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"
        if (Test-Path $dockerPath) {
            New-NetFirewallRule -DisplayName "Docker Engine" -Direction Inbound -Program $dockerPath -Action Allow
            Write-Host "Added Docker to Windows Firewall exceptions" -ForegroundColor Green
        } else {
            Write-Host "Docker executable not found at expected location" -ForegroundColor Red
        }
    } catch {
        Write-Host "Error adding firewall exception: $_" -ForegroundColor Red
    }
}

function Repair-DockerWSLIntegration {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "This function requires administrator privileges. Please run PowerShell as Administrator." -ForegroundColor Red
        return
    }

    Write-Host "===== Repairing Docker WSL Integration =====" -ForegroundColor Cyan

    # Step 1: Shutdown WSL
    Write-Host "Step 1: Shutting down WSL..." -ForegroundColor Yellow
    wsl --shutdown
    Start-Sleep -Seconds 5

    # Step 2: Restart Docker Desktop
    Write-Host "Step 2: Restarting Docker Desktop..." -ForegroundColor Yellow
    Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 5

    # Step 3: Check Docker settings
    $settingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

            # Backup settings
            Copy-Item -Path $settingsPath -Destination "$settingsPath.bak" -Force
            Write-Host "Created backup of Docker settings at $settingsPath.bak" -ForegroundColor Green

            # Ensure WSL integration is enabled
            if (-not $settings.wslEngineEnabled) {
                Write-Host "Enabling WSL 2 engine in Docker settings..." -ForegroundColor Yellow
                $settings.wslEngineEnabled = $true
                $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
            }
            else {
                Write-Host "WSL 2 engine already enabled in settings" -ForegroundColor Green
            }

            # Ensure WSL integration is enabled for distros
            if ($settings.wslIntegration.enabled -eq $false) {
                Write-Host "Enabling WSL integration for distros..." -ForegroundColor Yellow
                $settings.wslIntegration.enabled = $true
                $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
            }
            else {
                Write-Host "WSL integration for distros already enabled" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error modifying Docker settings:" -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Red
        }
    }

    # Step 4: Start Docker Desktop
    Write-Host "Step 4: Starting Docker Desktop..." -ForegroundColor Yellow
    Start-Process "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    Write-Host "Waiting for Docker to initialize (45 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 45

    # Step 5: Check if repair was successful
    Write-Host "Step 5: Checking if repair was successful..." -ForegroundColor Yellow
    Test-DockerLinuxEngineConnection

    # Step 6: Additional troubleshooting if needed
    if (-not (Test-Path -Path "\\.\pipe\dockerDesktopLinuxEngine")) {
        Write-Host "`nAdditional troubleshooting steps:" -ForegroundColor Cyan
        Write-Host "1. Open Docker Desktop settings" -ForegroundColor Yellow
        Write-Host "2. Go to 'Resources > WSL Integration'" -ForegroundColor Yellow
        Write-Host "3. Make sure 'Enable integration with my default WSL distro' is checked" -ForegroundColor Yellow
        Write-Host "4. Check the boxes for any Linux distros you want to use with Docker" -ForegroundColor Yellow
        Write-Host "5. Click 'Apply & Restart'" -ForegroundColor Yellow

        Write-Host "`nIf issues persist, try:" -ForegroundColor Cyan
        Write-Host "1. Uninstall and reinstall WSL: 'wsl --unregister docker-desktop'" -ForegroundColor Yellow
        Write-Host "2. Reset Docker Desktop to factory defaults (from Troubleshoot menu)" -ForegroundColor Yellow
    }
}

# Fix Docker not running
function Start-DockerDesktop {
    $dockerPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Host "Starting Docker Desktop..." -ForegroundColor Yellow
        Start-Process $dockerPath
        Write-Host "Waiting for Docker to initialize (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        Test-DockerRunning
    }
    else {
        Write-Host "Docker Desktop not found at expected location. Is it installed?" -ForegroundColor Red
    }
}

function Test-DockerTroubleshooter {
    Write-Host "===== Docker Troubleshooter =====" -ForegroundColor Cyan

    Add-DockerFirewallException
    Repair-DockerWSLIntegration

    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host "Running with administrator privileges: YES" -ForegroundColor Green
    } else {
        Write-Host "Running with administrator privileges: NO (some fixes may not work)" -ForegroundColor Yellow
    }

    # Test Docker process
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        Write-Host "Docker Desktop process: RUNNING" -ForegroundColor Green
    } else {
        Write-Host "Docker Desktop process: NOT RUNNING" -ForegroundColor Red
        Write-Host "  Fix: Start Docker Desktop manually or run Start-DockerDesktop function" -ForegroundColor Yellow
        Start-DockerDesktop
    }

    # Test Docker service
    $dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    if ($dockerService -and $dockerService.Status -eq "Running") {
        Write-Host "Docker service: RUNNING" -ForegroundColor Green
    } else {
        Write-Host "Docker service: NOT RUNNING" -ForegroundColor Red
        Write-Host "  Fix: Run Restart-DockerService function as administrator" -ForegroundColor Yellow
    }

    # Test user permissions
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $dockerGroup = Get-LocalGroupMember -Group "docker-users" -ErrorAction SilentlyContinue
    if ($dockerGroup -match [regex]::Escape($currentUser)) {
        Write-Host "User in docker-users group: YES" -ForegroundColor Green
    } else {
        Write-Host "User in docker-users group: NO" -ForegroundColor Red
        Write-Host "  Fix: Run Add-UserToDockerGroup function as administrator" -ForegroundColor Yellow
    }

    # Test named pipe
    if (Test-Path -Path "\\.\pipe\docker_engine") {
        Write-Host "Docker named pipe exists: YES" -ForegroundColor Green
    } else {
        Write-Host "Docker named pipe exists: NO" -ForegroundColor Red
        Write-Host "  Fix: Restart Docker Desktop or run as administrator" -ForegroundColor Yellow
    }

    # Test Docker command
    try {
        $dockerResult = docker version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker command works: YES" -ForegroundColor Green
            Write-Host "  Version Info: $($dockerResult -join "`n  ")" -ForegroundColor Green
        } else {
            Write-Host "Docker command works: PARTIAL (with errors)" -ForegroundColor Yellow
            Write-Host "  Warning: $($dockerResult -join "`n  ")" -ForegroundColor Yellow

            # Run the diagnostic function first
            Test-DockerLinuxEngineConnection

            # Uncomment the line below to run the repair function (must be run as Administrator)
            # Repair-DockerWSLIntegration
        }
    } catch {
        Write-Host "Docker command works: NO" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }

    Write-Host "`nTo fix issues, run the appropriate function for your specific problem." -ForegroundColor Cyan
}

Test-DockerTroubleshooter
