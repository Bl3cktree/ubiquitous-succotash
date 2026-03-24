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

#================================================
#  [PreOS] unattend.xml schreiben
#  MUSS vor Start-OSDCloud stehen
#================================================
Write-Host -ForegroundColor Green "Create C:\Windows\Panther\unattend.xml"
If (!(Test-Path "C:\Windows\Panther")) {
    New-Item "C:\Windows\Panther" -ItemType Directory -Force | Out-Null
}

$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <InputLocale>de-DE</InputLocale>
      <SystemLocale>de-DE</SystemLocale>
      <UILanguage>de-DE</UILanguage>
      <UILanguageFallback>en-US</UILanguageFallback>
      <UserLocale>de-DE</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Name>admincy</Name>
            <DisplayName>admincy</DisplayName>
            <Group>Administrators</Group>
            <Password>
              <Value>Cyberdyne2024!</Value>
              <PlainText>true</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>admincy</Username>
        <Password>
          <Value>Cyberdyne2024!</Value>
          <PlainText>true</PlainText>
        </Password>
        <LogonCount>1</LogonCount>
      </AutoLogon>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
</unattend>
'@
$UnattendXml | Out-File -FilePath 'C:\Windows\Panther\unattend.xml' -Encoding utf8 -Width 2000 -Force
Write-Host -ForegroundColor Green "unattend.xml: OK"

#================================================
#  [PreOS] CYB SetupComplete schreiben
#  MUSS vor Start-OSDCloud stehen
#  OSDCloud ruft C:\OSDCloud\Scripts\SetupComplete\SetupComplete.cmd automatisch auf
#================================================
Write-Host -ForegroundColor Green "Create C:\OSDCloud\Scripts\SetupComplete\"
If (!(Test-Path "C:\OSDCloud\Scripts\SetupComplete")) {
    New-Item "C:\OSDCloud\Scripts\SetupComplete" -ItemType Directory -Force | Out-Null
}

$CYBSetupCMD = 'powershell.exe -ExecutionPolicy Bypass -File C:\OSDCloud\Scripts\SetupComplete\CYB-PostInstall.ps1'
$CYBSetupCMD | Out-File -FilePath 'C:\OSDCloud\Scripts\SetupComplete\SetupComplete.cmd' -Encoding ascii -Force
Write-Host -ForegroundColor Green "SetupComplete.cmd: OK"

$CYBSetupPS1 = @"
`$LogPath = "C:\Windows\Logs\Cyberdyne-PostInstall.log"
New-Item -Path (Split-Path `$LogPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
Start-Transcript -Path `$LogPath -Append
Write-Host "=== Cyberdyne Post-Install ===" -ForegroundColor Cyan
Write-Host (Get-Date -Format 'dd.MM.yyyy HH:mm:ss') -ForegroundColor Cyan

# 1. Zeitzone
Set-TimeZone -Id "W. Europe Standard Time"
Write-Host "Zeitzone: OK" -ForegroundColor Green

# 2. Computername
`$Serial = (Get-WmiObject Win32_BIOS).SerialNumber.Trim()
`$NewName = ("CYB-`$Serial" -replace '[^a-zA-Z0-9\-]', '')
`$NewName = `$NewName.Substring(0, [Math]::Min(15, `$NewName.Length))
Rename-Computer -NewName `$NewName -Force -ErrorAction SilentlyContinue
Write-Host "Computername: `$NewName" -ForegroundColor Green

# 3. Datto RMM Agent
`$RMMUrl  = "https://pinotage.rmm.datto.com/download-agent/windows/258b4c6e-b750-4acc-b7cf-b25c4e843d1c"
`$RMMDest = "C:\Windows\Temp\DattoRMM.exe"
try {
    Invoke-WebRequest -Uri `$RMMUrl -OutFile `$RMMDest -UseBasicParsing
    Start-Process -FilePath `$RMMDest -ArgumentList "/S" -Wait
    Write-Host "Datto RMM: OK" -ForegroundColor Green
} catch {
    Write-Host "Datto RMM FEHLER: `$_" -ForegroundColor Red
}

# 4. WinGet Task registrieren
`$WGScript = 'foreach (`$App in @("7zip.7zip","VideoLAN.VLC","Notepad++.Notepad++","Adobe.Acrobat.Reader.64-bit")) { winget install --id `$App --silent --accept-package-agreements --accept-source-agreements --source=winget }; Unregister-ScheduledTask -TaskName "CYB-WinGetApps" -Confirm:`$false'
`$WGScript | Out-File "C:\Windows\Temp\CYB-WinGetApps.ps1" -Encoding utf8 -Force
`$Action    = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\CYB-WinGetApps.ps1"
`$Trigger   = New-ScheduledTaskTrigger -AtLogOn
`$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "CYB-WinGetApps" -Action `$Action -Trigger `$Trigger -Principal `$Principal -Force
Write-Host "WinGet-Task: OK" -ForegroundColor Green

Write-Host "=== Post-Install abgeschlossen ===" -ForegroundColor Cyan
Stop-Transcript
"@
$CYBSetupPS1 | Out-File -FilePath 'C:\OSDCloud\Scripts\SetupComplete\CYB-PostInstall.ps1' -Encoding utf8 -Force
Write-Host -ForegroundColor Green "CYB-PostInstall.ps1: OK"

#=======================================================================
#   [OS] Params and Start-OSDCloud
#   MUSS zuletzt stehen — rebootet automatisch
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
