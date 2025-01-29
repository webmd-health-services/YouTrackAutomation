# Overview

The "YouTrackAutomation" module is a PowerShell module built to interface with the YouTrack REST API.

# System Requirements

* Windows PowerShell 5.1 and .NET 4.6.1+
* PowerShell Core 6+

# Installing

To install globally:

```powershell
Install-Module -Name 'YouTrackAutomation'
Import-Module -Name 'YouTrackAutomation'
```

To install privately:

```powershell
Save-Module -Name 'YouTrackAutomation' -Path '.'
Import-Module -Name '.\YouTrackAutomation'
```

# Commands

## Creating a new session

All commands require a session object in order to call them. Create a new session object using the `New-YTSession`
command.

## Interacting With API

* `Get-YTIssue`
* `Get-YTProject`
* `Invoke-YTRestMethod`
* `New-YTIssue`
* `New-YTProject`
* `New-YTSession`
