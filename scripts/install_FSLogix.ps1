$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$stopWatch = [System.Diagnostics.Stopwatch]::new()
$stopWatch.Reset()
$stopWatch.Start()
$WVDFSLogixUrl = "https://aka.ms/fslogix_download"
$logFileLocation = $env:TEMP + "\FSLogixInstallation.log"

("Check if FSLogix is already running...") | Out-File $logFileLocation -Append
if ($null -ne (Get-Process "frxsvc" -ErrorAction SilentlyContinue)) {
    ("FSLogix is already running! No need for installation") | Out-File $logFileLocation -Append
    return
}
("FSLogix is not running. Installing...") | Out-File $logFileLocation -Append

("FSLogix download URL = '{0}'" -f $WVDFSLogixUrl) | Out-File $logFileLocation -Append

$ScriptPath = (Get-Item .).FullName

$url = ("{0}" -f $WVDFSLogixUrl)
$FSLogixInstallerZip = [System.IO.Path]::Combine($ScriptPath, "FSLogix_Apps.zip")

("FSLogix full download URL = '{0}'" -f $url) | Out-File $logFileLocation -Append
("FSLogix download location = '{0}'" -f $FSLogixInstallerZip) | Out-File $logFileLocation -Append


("Starting download...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $url -OutFile $FSLogixInstallerZip -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting extraction...") | Out-File $logFileLocation -Append
Expand-Archive -Path $FSLogixInstallerZip -DestinationPath $ScriptPath
("Extraction finished.") | Out-File $logFileLocation -Append

$FSLogixInstaller = $ScriptPath + "\x64\Release\FSLogixAppsSetup.exe"

("Starting installer...") | Out-File $logFileLocation -Append
$fsLogix_install_status = Start-Process -FilePath $FSLogixInstaller -ArgumentList @('/install', '/quiet', '/norestart') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $fsLogix_install_status.ExitCode) | Out-File $logFileLocation -Append


$stopWatch.Stop()
("Install finished in '{0}' ms" -f $stopWatch.ElapsedMilliseconds) | Out-File $logFileLocation -Append