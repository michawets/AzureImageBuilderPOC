$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "MICHA: Installing Acrobat"

if ($null -eq (Get-Item -Path "c:\buildArtifacts" -ErrorAction SilentlyContinue)) {
    New-Item -Path "c:\buildArtifacts" -ItemType Directory -Force
}

$WVDAcrobatUrl = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/2000920063/AcroRdrDC2000920063_en_US.exe"
$logFileLocation = "c:\buildArtifacts\AcrobatInstallation.log"

("Acrobat download URL = '{0}'" -f $WVDAcrobatUrl) | Out-File $logFileLocation -Append

$url = ("{0}" -f $WVDAcrobatUrl)
$AcrobatInstaller = "c:\buildArtifacts\AcroRdrDC2000920063_en_US.exe"

("Acrobat full download URL = '{0}'" -f $url) | Out-File $logFileLocation -Append
("Acrobat download location = '{0}'" -f $AcrobatInstaller) | Out-File $logFileLocation -Append


("Starting download...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $url -OutFile $AcrobatInstaller -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting installer...") | Out-File $logFileLocation -Append
$Acrobat_install_status = Start-Process -FilePath $AcrobatInstaller -ArgumentList @('/sAll', '/rs', '/msi', '/qn', '/norestart', 'ALLUSERS=1', 'EULA_ACCEPT=YES', 'SUPPRESS_APP_LAUNCH=YES') -Wait -Passthru 
("Installer finished with returncode '{0}'" -f $Acrobat_install_status.ExitCode) | Out-File $logFileLocation -Append


Write-Host "MICHA: Acrobat done!"