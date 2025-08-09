# Check if command exists
function Command-Exists($cmd) {
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

# Install Chocolatey if missing
if (-not (Command-Exists choco)) {
    Write-Host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install Python if missing
if (-not (Command-Exists python)) {
    Write-Host "Installing Python..."
    choco install python --pre -y
} else {
    Write-Host "Python already installed."
}

# Upgrade pip and install websockify if missing
Write-Host "Installing/Upgrading websockify..."
python -m pip install --upgrade pip
python -m pip show websockify > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    python -m pip install websockify
} else {
    Write-Host "websockify already installed."
}

# TightVNC install path and installer URL
$tightvncPath = "C:\Program Files\TightVNC\tvnserver.exe"
$tightvncInstallerUrl = "https://www.tightvnc.com/download/2.8.81/tightvnc-2.8.81-gpl-setup-64bit.msi"
$tightvncInstallerPath = "$env:TEMP\tightvnc.msi"

# Download and install TightVNC if missing
if (-not (Test-Path $tightvncPath)) {
    Write-Host "Downloading TightVNC installer..."
    Invoke-WebRequest -Uri $tightvncInstallerUrl -OutFile $tightvncInstallerPath
    Write-Host "Installing TightVNC silently..."
    Start-Process msiexec.exe -ArgumentList "/i `"$tightvncInstallerPath`" /quiet" -Wait
} else {
    Write-Host "TightVNC already installed."
}

# Set TightVNC password and config in registry
$regPath = "HKCU:\Software\TightVNC\Server"
If (-not (Test-Path $regPath)) {
    Write-Host "TightVNC registry keys not found. Please run TightVNC once manually and rerun this script."
    exit
}
Write-Host "Setting TightVNC password and config..."
Set-ItemProperty -Path $regPath -Name "Password" -Value ([byte[]](0x31,0x32,0x33,0x34,0x35,0x36,0x00))  # "123456"
Set-ItemProperty -Path $regPath -Name "AlwaysShared" -Value 1

# Start TightVNC server if not running
if (-not (Get-Process -Name tvnserver -ErrorAction SilentlyContinue)) {
    Write-Host "Starting TightVNC server..."
    Start-Process -FilePath $tightvncPath
    Start-Sleep -Seconds 5
} else {
    Write-Host "TightVNC server already running."
}

# Start noVNC (websockify) on port 6080 forwarding to localhost:5900
Write-Host "Starting noVNC server (websockify)..."
Start-Process -NoNewWindow -FilePath python -ArgumentList '-m websockify 6080 localhost:5900'

Start-Sleep -Seconds 5

# Start Serveo SSH tunnel with subdomain myrdp
Write-Host "Starting Serveo SSH tunnel (Ctrl+C to stop)..."
ssh -R myrdp:80:localhost:6080 serveo.net
