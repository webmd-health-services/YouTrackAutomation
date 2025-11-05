
<#
.SYNOPSIS
Gets your computer ready to develop the YouTrackAutomation module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
YouTrackAutomation module. It:

* Installs YouTrack to the current folder from a pre-configured YouTrack instance.
* Configures the YouTrack instance to use the default port of 8080 and listen on 'localhost'.
* Sets up the default user account with the username 'admin' and password 'admin'.

.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    $YouTrackVersion = '2024.2.37269',

    # Start over with a fresh installation if one already exists.
    [switch] $Force
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$outputPath = Join-Path -Path $PSScriptRoot -ChildPath '.yt'
if (-not (Test-Path -Path $outputPath))
{
    Write-Information "Creating ${outputPath} directory."
    New-Item -Path $outputPath -ItemType Directory | Out-Null
}

$archivePath = Join-Path -Path $outputPath -ChildPath 'youtrack.zip'
if ($Force -or -not (Test-Path -Path $archivePath))
{
    Write-Information 'Downloading YouTrack.'
    Invoke-WebRequest -Uri "https://download-cdn.jetbrains.com/charisma/youtrack-${YouTrackVersion}.zip" -OutFile $archivePath
}

$destinationPath = Join-Path -Path $outputPath -ChildPath 'youtrack'

if ($Force -and (Test-Path -Path $destinationPath))
{
    Remove-Item -Path $destinationPath -Recurse -Force
}

if (-not (Test-Path -Path $destinationPath))
{
    Write-Information 'Extracting YouTrack.'
    Expand-Archive -Path $archivePath -Force -DestinationPath $destinationPath
    $nestedPath = Join-Path -Path $destinationPath -ChildPath "youtrack-${YouTrackVersion}"
    Move-Item -Path (Join-Path -Path $nestedPath -ChildPath '*') -Destination $destinationPath -Force
    Remove-Item -Recurse -Force -Path $nestedPath
}

$batPath = Join-Path -Path $destinationPath -ChildPath 'bin\youtrack.bat' -Resolve
if (-not $env:OS)
{
    $batPath = Join-Path -Path $destinationPath -ChildPath 'bin\youtrack.sh' -Resolve
    $env:JAVA_TOOL_OPTIONS = $null
}

Get-Process -Name 'java*'
& $batPath status
$ytRunning = $LASTEXITCODE -eq 0
if ($ytRunning)
{
    Write-Information 'Stopping YouTrack.'
    & $batPath stop
}
Get-Process -Name 'java*'

if ((Get-Command -Name 'Test-NetConnection' -ErrorAction Ignore))
{
    if ((Test-NetConnection -ComputerName 'localhost' -Port 8080).TcpTestSucceeded)
    {
        if ((Get-Command -Name 'Get-NetTCPConnection'))
        {
            Get-NetTCPConnection -LocalPort 8080 -ErrorAction Ignore |
                Select-Object -Expand 'OwningProcess' |
                Get-Process
        }
        Write-Error -Message 'Failed to install YouTrack: something besides YouTrack is listening on port 8080.'
        exit 1
    }
}

Write-Information 'Configuring YouTrack.'
& $batPath configure --listen-port=8080 --base-url="http://localhost:8080"

# mock completion of configuration wizard or else site will not start
$wizardConfiguredPath = Join-Path -Path $destinationPath -ChildPath 'conf\internal\wizard-configured.properties'
if (-not (Test-Path -Path $wizardConfiguredPath))
{
    Write-Information "Creating config file ${wizardConfiguredPath} to disable configuration wizard."
    $configuredContent = @"
configured.product.versions=$YouTrackVersion
wizard.configuration.finished=true
"@
    New-Item -Path $wizardConfiguredPath -ItemType File -Value $configuredContent | Out-Null
}

Write-Information 'Starting YouTrack.'
& $batPath start --no-browser

Get-Process -Name 'java*'

$timer = [Diagnostics.StopWatch]::New()
$timeout = New-TimeSpan -Minutes 1
$ready = $false
Write-Information -MessageData 'Waiting for YouTrack to finish warming up.'
while ($timer.Elapsed -lt $timeout)
{
    try
    {
        Invoke-WebRequest -Uri 'http://localhost:8080/' -Method Get -UseBasicParsing | Out-Null
        $ready = $true
        break
    }
    catch
    {
        & $batPath status
        $ytRunning = $LASTEXITCODE -eq 0
        if (-not $ytRunning)
        {
            Write-Information 'YouTrack failed to start. Starting YouTrack.'
            & $batPath start --no-browser
        }
    }
}

& $batPath status
$ytRunning = $LASTEXITCODE -eq 0
if (-not $ytRunning)
{
    Write-Error -Message "YouTrack is not running after multiple attempts to start it."
    exit 1
}

if (-not $ready)
{
    $Global:Error | Select-Object -First 1 | Format-List * -Force
    Write-Warning "YouTrack started but it isn't responding to requests at http://localhost:8080. Proceed with caution."
}
else
{
    Write-Information -MessageData 'YouTrack is ready for requests at http://localhost:8080.'
}

Get-Process -Name 'java*'
