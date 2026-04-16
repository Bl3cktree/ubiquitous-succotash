# Deploy-CYB.ps1
# GitHub: https://raw.githubusercontent.com/Bl3cktree/ubiquitous-succotash/refs/heads/main/Deploy-CYB.ps1

#================================================
# TLS Fix
#================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#================================================
# OVERLAY STARTEN
#================================================
$OverlayPath = "X:\OSDCloud\Config\Scripts\CYB-DeployOverlay-WinPE.ps1"
if (Test-Path $OverlayPath) {
    . $OverlayPath
} else {
    function Update-DeployStatus { param([int]$Step, [string]$Message) Write-Host "[$Step] $Message" -ForegroundColor Cyan }
    function Close-DeployOverlay { Write-Host "Abgeschlossen." -ForegroundColor Green }
}

#================================================
# [PreOS] Update Module
#================================================
Update-DeployStatus -Step 1 -Message "[1/4] Deployment wird vorbereitet..."

if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force
Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#================================================
# [OS] Start-OSDCloud
# PostOS wird ueber USB SetupComplete ausgefuehrt
#================================================
Update-DeployStatus -Step 2 -Message "[2/4] Windows wird heruntergeladen..."

$Params = @{
    OSVersion    = "Windows 11"
    OSBuild      = "25H2"
    OSEdition    = "Pro"
    OSLanguage   = "de-de"
    OSActivation = "Volume"
    ZTI          = $true
    Firmware     = $false
}
Start-OSDCloud @Params

#================================================
# [PostOS] SetupComplete Scripts kopieren
#================================================
Update-DeployStatus -Step 3 -Message "[3/4] System wird vorbereitet..."

$SetupScriptDest = "C:\Windows\Setup\Scripts"
New-Item -Path $SetupScriptDest -ItemType Directory -Force | Out-Null

foreach ($File in @("SetupComplete.cmd", "SetupComplete.ps1")) {
    $Src = "X:\OSDCloud\Config\Scripts\SetupComplete\$File"
    if (Test-Path $Src) {
        Copy-Item $Src -Destination "$SetupScriptDest\$File" -Force
        Write-Host "      OK: $File kopiert" -ForegroundColor Green
    } else {
        Write-Host "      WARNUNG: $File nicht gefunden" -ForegroundColor Yellow
    }
}

#================================================
# Neustart
#================================================
Update-DeployStatus -Step 4 -Message "[4/4] Neustart wird eingeleitet..."
Close-DeployOverlay

Write-Host "Restarting in 10 sec..." -ForegroundColor Green
Start-Sleep -Seconds 10
wpeutil reboot
