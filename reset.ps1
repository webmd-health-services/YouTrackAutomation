<#
.SYNOPSIS
Undoes the configuration changes made by the init.ps1 script.

.DESCRIPTION
The reset.ps1 script undoes the configuration changes made by the init.ps1 script. It:

* Stops all Java processes.
* Deletes Youtrack at `$PSScriptRoot/.output/YouTrack`

.EXAMPLE
.\reset.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    [Switch] $OnlyJava
)

Set-StrictMode -Version 'Latest'

Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force

if (-not $OnlyJava)
{
    Remove-Item -Recurse -Force -Path (Join-Path -Path $PSScriptRoot -ChildPath '.output\youtrack' -Resolve)
}