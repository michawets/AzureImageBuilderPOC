$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "MICHA: Installing Teams"

if ($null -eq (Get-Item -Path "c:\buildArtifacts" -ErrorAction SilentlyContinue)) {
    New-Item -Path "c:\buildArtifacts" -Force
}

$WVDMSTeamsUrl = "https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi"
$WVDWebRTCurl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6"
$VisualCRedisx64Url = "https://aka.ms/vs/16/release/vc_redist.x64.exe"
$VisualCRedisx86Url = "https://aka.ms/vs/16/release/vc_redist.x86.exe"

$logFileLocation = "c:\buildArtifacts\MSTeamsInstallation.log"

("MSTeams download URL = '{0}'" -f $WVDMSTeamsUrl) | Out-File $logFileLocation -Append

$MSTeamsInstaller = "c:\buildArtifacts\Teams_windows_x64.msi"
$WebRTCInstaller = "c:\buildArtifacts\MsRdcWebRTCSvc_HostSetup_0.11.0_x64.msi"
$VisualCRedisx64Installer = "c:\buildArtifacts\vc_redist.x64.exe"
$VisualCRedisx86Installer = "c:\buildArtifacts\vc_redist.x86.exe"

("MSTeams full download URL = '{0}'" -f $WVDMSTeamsUrl) | Out-File $logFileLocation -Append
("MSTeams download location = '{0}'" -f $MSTeamsInstaller) | Out-File $logFileLocation -Append
("WebRTC download location = '{0}'" -f $WebRTCInstaller) | Out-File $logFileLocation -Append
("Microsoft Visual C++ Redistributable x64 download location = '{0}'" -f $VisualCRedisx64Installer) | Out-File $logFileLocation -Append
("Microsoft Visual C++ Redistributable x86 download location = '{0}'" -f $VisualCRedisx86Installer) | Out-File $logFileLocation -Append


("Starting download MSTeams...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $WVDMSTeamsUrl -OutFile $MSTeamsInstaller -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting download WebRTC...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $WVDWebRTCurl -OutFile $WebRTCInstaller -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting download Microsoft Visual C++ Redistributable x64...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $VisualCRedisx64Url -OutFile $VisualCRedisx64Installer -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting download Microsoft Visual C++ Redistributable x86...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $VisualCRedisx86Url -OutFile $VisualCRedisx86Installer -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Setting VDI registry key ") | Out-File $logFileLocation -Append
if ($null -eq (Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -ErrorAction SilentlyContinue)) {
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name "IsWVDEnvironment" -Value 1 -Type DWord -Force
("Finished.") | Out-File $logFileLocation -Append

("Starting Microsoft Visual C++ Redistributable x64 installer...") | Out-File $logFileLocation -Append
$VisualCRedisx64_install_status = Start-Process -FilePath $VisualCRedisx64Installer -ArgumentList @('/install', '/quiet', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $VisualCRedisx64_install_status.ExitCode) | Out-File $logFileLocation -Append

("Starting Microsoft Visual C++ Redistributable x86 installer...") | Out-File $logFileLocation -Append
$VisualCRedisx86_install_status = Start-Process -FilePath $VisualCRedisx86Installer -ArgumentList @('/install', '/quiet', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $VisualCRedisx86_install_status.ExitCode) | Out-File $logFileLocation -Append

("Starting WebRTC installer...") | Out-File $logFileLocation -Append
$WVDWebRTC_install_status = Start-Process -FilePath $WebRTCInstaller -ArgumentList @('/quiet', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $WVDWebRTC_install_status.ExitCode) | Out-File $logFileLocation -Append

("Starting MSTeams installer...") | Out-File $logFileLocation -Append
$MSTeams_install_status = Start-Process -FilePath $MSTeamsInstaller -ArgumentList @('ALLUSERS=1', 'ALLUSER=1', '/qn', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $MSTeams_install_status.ExitCode) | Out-File $logFileLocation -Append


Write-Host "MICHA: Teams done!"