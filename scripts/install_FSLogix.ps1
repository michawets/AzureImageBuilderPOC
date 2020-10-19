$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "MICHA: Installing FSLogix"

if ($null -eq (Get-Item -Path "c:\buildArtifacts" -ErrorAction SilentlyContinue)) {
    New-Item -Path "c:\buildArtifacts" -Force
}

$WVDFSLogixUrl = "https://aka.ms/fslogix_download"
$logFileLocation = "c:\buildArtifacts\FSLogixInstallation.log"
$FSLogixInstallerZip = "c:\buildArtifacts\FSLogix_Apps.zip"

("Check if FSLogix is already running...") | Out-File $logFileLocation -Append
if ($null -ne (Get-Process "frxsvc" -ErrorAction SilentlyContinue)) {
    ("FSLogix is already running! No need for installation") | Out-File $logFileLocation -Append
    return
}
("FSLogix is not running. Installing...") | Out-File $logFileLocation -Append
("FSLogix full download URL = '{0}'" -f $WVDFSLogixUrl) | Out-File $logFileLocation -Append
("FSLogix download location = '{0}'" -f $FSLogixInstallerZip) | Out-File $logFileLocation -Append

("Starting download...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $WVDFSLogixUrl -OutFile $FSLogixInstallerZip -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting extraction...") | Out-File $logFileLocation -Append
Expand-Archive -Path $FSLogixInstallerZip -DestinationPath "c:\buildArtifacts\"
("Extraction finished.") | Out-File $logFileLocation -Append

$FSLogixInstaller = "c:\buildArtifacts\x64\Release\FSLogixAppsSetup.exe"

("Starting installer...") | Out-File $logFileLocation -Append
$fsLogix_install_status = Start-Process -FilePath $FSLogixInstaller -ArgumentList @('/install', '/quiet', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $fsLogix_install_status.ExitCode) | Out-File $logFileLocation -Append

Write-Host "MICHA: FSLogix done!"