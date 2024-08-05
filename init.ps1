
<#
.SYNOPSIS
Gets your computer ready to develop the YouTrackAutomation module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
YouTrackAutomation module. It:

* Installs YouTrack to the current folder from an pre-configured YouTrack instance.
* Configures the YouTrack instance to use the default port of 8080 and listen on 'localhost'.
* Sets up the default user account with the username 'admin' and password 'admin'.

.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    $YouTrackVersion = '2024.2.37269'
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
$outputPath = Join-Path -Path $PSScriptRoot -ChildPath '.output'
$archivePath = Join-Path -Path $outputPath -ChildPath 'youtrack.zip'
if (-not (Test-Path -Path $archivePath))
{
    Invoke-WebRequest -Uri "https://download-cdn.jetbrains.com/charisma/youtrack-${YouTrackVersion}.zip" -OutFile $archivePath
}

$dataArchivePath = Join-Path -Path $PSScriptRoot -ChildPath 'ytconfig.zip'
$destinationPath = Join-Path -Path $outputPath -ChildPath 'youtrack'

if (Test-Path -Path $destinationPath)
{
    Remove-Item -Path $destinationPath -Recurse -Force
}

Expand-Archive -Path $archivePath -Force -DestinationPath $destinationPath
$nestedPath = Join-Path -Path $destinationPath -ChildPath "youtrack-${YouTrackVersion}"
Move-Item -Path (Join-Path -Path $nestedPath -ChildPath '*') -Destination $destinationPath -Force
Remove-Item -Recurse -Force -Path $nestedPath

$dataArchiveExtractPath = Join-Path -Path $outputPath -ChildPath 'ytconfig'
if (-not (Test-Path -Path $dataArchiveExtractPath))
{
    Expand-Archive -Path $dataArchivePath -Force -DestinationPath $dataArchiveExtractPath
}
Copy-Item -Path (Join-Path -Path $dataArchiveExtractPath -ChildPath '*') -Destination $destinationPath -Recurse -Force


$batPath = Join-Path -Path $destinationPath -ChildPath 'bin\youtrack.bat' -Resolve
if (-not $env:OS)
{
    $batPath = Join-Path -Path $destinationPath -ChildPath 'bin\youtrack.sh' -Resolve
    $env:JAVA_TOOL_OPTIONS = ''
}
& $batPath start --no-browser

Write-Information -MessageData 'Waiting for YouTrack to finish warming up.'
while ($true)
{
    try
    {
        Invoke-WebRequest -Uri 'http://localhost:8080/' -Method Get -UseBasicParsing | Out-Null
        break
    }
    catch
    {
        Start-Sleep -Seconds 5
    }
}
Write-Information -MessageData 'YouTrack is ready for requests.'