$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "MICHA: Installing VSCode"

if ($null -eq (Get-Item -Path "c:\buildArtifacts" -ErrorAction SilentlyContinue)) {
    New-Item -Path "c:\buildArtifacts" -ItemType Directory -Force
}

$WVDvscodeUrl = "https://go.microsoft.com/fwlink/?Linkid=852157"
$logFileLocation = "c:\buildArtifacts\vscodeInstallation.log"
$vscodeInstaller = "c:\buildArtifacts\VSCodeSetup-x64.exe"

("vscode full download URL = '{0}'" -f $WVDvscodeUrl) | Out-File $logFileLocation -Append
("vscode download location = '{0}'" -f $vscodeInstaller) | Out-File $logFileLocation -Append


("Starting download...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $WVDvscodeUrl -OutFile $vscodeInstaller -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting installer...") | Out-File $logFileLocation -Append
$vscode_install_status = Start-Process -FilePath $vscodeInstaller -ArgumentList @('/VERYSILENT' , '/ALLUSERS', '/mergetasks=!runcode') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $vscode_install_status.ExitCode) | Out-File $logFileLocation -Append

Write-Host "MICHA: VSCode done!"