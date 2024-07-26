
<#
.SYNOPSIS
Gets your computer ready to develop the YouTrackAutomation module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
YouTrackAutomation module. It:

* Installs YouTrack to the current folder from an pre-configured YouTrack instance.
* Configures the YouTrack instance to use the default port of 8080 and listen on 'localhost'.
* Sets up the default user account with the username 'admin' and password 'admin'.
* Installs the YouTrackSharp and Newtonsoft.Json modules to the `$PSScriptRoot\packages`.

.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    # The source to use when installing packages.
    [String] $Source
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
$archivePath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269.zip'
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269'
if (Test-Path -Path $destinationPath)
{
    Remove-Item -Path $destinationPath -Recurse -Force
}

Expand-Archive -Path $archivePath -Force -DestinationPath $destinationPath
$batPath = Join-Path -Path $destinationPath -ChildPath 'youtrack-2024.2.37269\bin\youtrack.bat' -Resolve
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows)
{
    $batPath.Replace('.bat', '.sh')
}
& $batPath start --no-browser

$packageRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

if (-not (Test-Path -Path $packageRoot))
{
    New-Item -Path $packageRoot -ItemType Directory
}
