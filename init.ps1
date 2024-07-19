using namespace Microsoft.Playwright
<#
.SYNOPSIS
Gets your computer ready to develop the YouTrackAutomation module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
YouTrackAutomation module. It:

* Installs YouTrack to the current folder.
* Configures the YouTrack instance to use the default port of 8080 and listen on 'localhost'.
* Sets up the default user account with the username 'admin' and password 'admin'.
* Gets a YouTrack API key for the default user account and saves it to '$PSScriptRoot\youtrackkey'.


.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    # Determines if the browser should be headless.
    [switch] $Headless
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269'

Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
$archivePath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269.zip'
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269'
if (-not (Test-Path -Path $archivePath))
{
    Invoke-WebRequest 'https://download-cdn.jetbrains.com/charisma/youtrack-2024.2.37269.zip' -OutFile $archivePath
}
if (Test-Path -Path $destinationPath)
{
    Remove-Item -Path $destinationPath -Recurse -Force
}
Expand-Archive -Path $archivePath -Force -DestinationPath $destinationPath
$batPath = Join-Path -Path $destinationPath -ChildPath 'youtrack-2024.2.37269\bin\youtrack.bat' -Resolve
& $batPath configure --listen-port=8080 --base-url='http://localhost:8080'
& $batPath start --no-browser

Get-Process | Where-Object { $_.Name -like 'chrome*' } | Stop-Process -Force

# pip3 install --upgrade pip --user
pip3 install playwright --user
python3 -m playwright install
$wizardToken = Get-Content -Raw (Join-Path -Path $destinationPath -ChildPath '\youtrack-2024.2.37269\conf\internal\services\configurationWizard\wizard_token.txt')
python3 (Join-Path -Path $PSScriptRoot -ChildPath 'setup_youtrack.py') $wizardToken