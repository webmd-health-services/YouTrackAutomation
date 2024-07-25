using namespace Microsoft.Playwright
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
& $batPath start --no-browser

$packageRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

if (-not (Test-Path -Path $packageRoot))
{
    New-Item -Path $packageRoot -ItemType Directory
}

Install-Package -Name 'YouTrackSharp' -Destination $packageRoot -Force -RequiredVersion '2022.3.1' -SkipDependencies
Install-Package -Name 'Newtonsoft.Json' -Destination $packageRoot -Force -RequiredVersion '13.0.1' -SkipDependencies

$binPath = Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomation\bin'
if (-not (Test-Path -Path $binPath))
{
    New-Item -Path $binPath -ItemType Directory
}
Copy-Item -Path (Join-Path -Path $packageRoot -ChildPath 'YouTrackSharp.2022.3.1\lib\netstandard2.0\YouTrackSharp.dll') -Destination $binPath -Force
Copy-Item -Path (Join-Path -Path $packageRoot -ChildPath 'Newtonsoft.Json.13.0.1\lib\netstandard2.0\Newtonsoft.Json.dll') -Destination $binPath -Force