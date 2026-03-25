#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force

Write-Host -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force

#=======================================================================
#   [OS] Start-OSDCloud
#   PostOS wird ueber USB SetupComplete ausgefuehrt
#=======================================================================
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
