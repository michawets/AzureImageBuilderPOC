$ErrorActionPreference = "Stop"
$stopWatch = [System.Diagnostics.Stopwatch]::new()
$stopWatch.Reset()
$stopWatch.Start()
$WVD7zipUrl = "https://www.7-zip.org/a/7z1900-x64.exe"
$logFileLocation = $env:TEMP + "\7zipInstallation.log"

("7zip download URL = '{0}'" -f $WVD7zipUrl) | Out-File $logFileLocation -Append

$ScriptPath = (Get-Item .).FullName

$url = ("{0}" -f $WVD7zipUrl)
$7zipInstaller = [System.IO.Path]::Combine($ScriptPath, "7z1900-x64.exe")

("7zip full download URL = '{0}'" -f $url) | Out-File $logFileLocation -Append
("7zip download location = '{0}'" -f $7zipInstaller) | Out-File $logFileLocation -Append


("Starting download...") | Out-File $logFileLocation -Append
Invoke-WebRequest -Uri $url -OutFile $7zipInstaller -UseBasicParsing
("Download finished.") | Out-File $logFileLocation -Append

("Starting installer...") | Out-File $logFileLocation -Append
$7zip_install_status = Start-Process -FilePath $7zipInstaller -ArgumentList @('/S') -Wait -Passthru
("Installer finished with returncode '{0}'" -f $7zip_install_status.ExitCode) | Out-File $logFileLocation -Append


$stopWatch.Stop()
("Install finished in '{0}' ms" -f $stopWatch.ElapsedMilliseconds) | Out-File $logFileLocation -Append