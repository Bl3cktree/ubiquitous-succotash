#================================================
# TLS Fix
#================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#================================================
# OVERLAY STARTEN (erstes was passiert)
#================================================
$OverlayPath = "X:\OSDCloud\Config\Scripts\DeployOverlay-WinPE.ps1"
if (Test-Path $OverlayPath) {
    . $OverlayPath
} else {
    function Update-DeployStatus {
        param([int]$Step, [string]$Message, [string]$SubMessage = "", [int]$Progress = -1)
        Write-Host "[$Step] $Message" -ForegroundColor Cyan
    }
    function Close-DeployOverlay { Write-Host "Abgeschlossen." -ForegroundColor Green }
}

#================================================
# [1/4] PreOS – Module laden
#================================================
Update-DeployStatus -Step 1 -Message "Deployment wird vorbereitet..." -Progress 5

if ((Get-MyComputerModel) -match 'Virtual') {
    Set-DisRes 1600
}

Update-DeployStatus -Step 1 -Message "OSD Modul wird aktualisiert..." -Progress 15
Install-Module OSD -Force
Import-Module OSD -Force

#================================================
# [2/4] Windows Download
#================================================
Update-DeployStatus -Step 2 -Message "Windows 11 wird heruntergeladen..." `
                             -SubMessage "Dieser Vorgang dauert einige Minuten" -Progress 25

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
# [3/4] System vorbereiten
#================================================
Update-DeployStatus -Step 3 -Message "System wird vorbereitet..." -Progress 80

$UnattendScript = "X:\OSDCloud\Config\Scripts\CYB-WriteUnattend.ps1"
if (Test-Path $UnattendScript) { & $UnattendScript }

$SetupScriptDest = "C:\Windows\Setup\Scripts"
New-Item -Path $SetupScriptDest -ItemType Directory -Force | Out-Null
foreach ($File in @("SetupComplete.cmd", "SetupComplete.ps1")) {
    $Src = "X:\OSDCloud\Config\Scripts\SetupComplete\$File"
    if (Test-Path $Src) { Copy-Item $Src -Destination "$SetupScriptDest\$File" -Force }
}

# DeployOverlay fuer Post-Install (WinGet-Task) ablegen
$CYBDir = "C:\ProgramData\CYB"
New-Item -Path $CYBDir -ItemType Directory -Force | Out-Null
$OverlaySrc = "X:\OSDCloud\Config\Scripts\DeployOverlay.ps1"
if (Test-Path $OverlaySrc) {
    Copy-Item $OverlaySrc -Destination "$CYBDir\DeployOverlay.ps1" -Force
}

#================================================
# [4/4] Neustart
#================================================
Update-DeployStatus -Step 4 -Message "Neustart wird eingeleitet..." -Progress 100
Close-DeployOverlay
Start-Sleep -Seconds 5
wpeutil reboot
