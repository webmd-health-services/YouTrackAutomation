# Overview

YouTrackAutomation is a PowerShell module for working with the [YouTrack REST
API](https://www.jetbrains.com/help/youtrack/devportal/youtrack-rest-api.html). It provides functions for reading and
updating issues, projects, custom fields, tags, work items, and more.

# System Requirements

* Windows PowerShell 5.1
* PowerShell 7+

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

# Getting Started

## Create a Session

Every function takes a session object created with `New-YTSession`. Pass the base URL of your YouTrack instance (just the
protocol and hostname) and an API token. `New-YTSession` appends the REST API path (`/api/`) to the URL for you.

```powershell
$session = New-YTSession -Url 'https://youtrack.example.com' -ApiToken $apiToken
```

> The API token is stored on the returned session object as plain text. Treat the session object (and any variable
> holding your token) as a secret.

## Work With Issues

```powershell
# Get an issue (custom fields are flattened onto the returned object, e.g. $issue.State):
$issue = Get-YTIssue -Session $session -IssueId 'DEMO-1'

# Create an issue:
$new = New-YTIssue -Session $session -Project 'DEMO' -Summary 'New issue' -Description 'Details here.'

# Create an issue and set custom fields at the same time:
$fields = @(
    @{ name = 'Priority' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Major' } }
)
New-YTIssue -Session $session -Project 'DEMO' -Summary 'Triage' -CustomField $fields

# Change state, assignee, a custom field, or the description:
Set-YTIssueState         -Session $session -IssueID 'DEMO-1' -Value 'In Progress'
Set-YTIssueAssignee      -Session $session -IssueID 'DEMO-1' -Assignee 'Brian Freeman'
Set-YTIssueCustomField   -Session $session -IssueID 'DEMO-1' -CustomField 'Team' -Value 'SYSOPS'
Set-YTIssueDescription   -Session $session -Issue   'DEMO-1' -Description 'Updated description.'

# Comment, log work, link, and tag:
Add-YTComment  -Session $session -IssueID 'DEMO-1' -Comment 'Investigating.'
Add-YTWork     -Session $session -IssueID 'DEMO-1' -Work '15m' -Comment 'Triage.'
Set-YTIssueLink -Session $session -IssueID 'DEMO-1' -LinkType 'relates to' -TargetIssueId 'DEMO-2'

$tag = Get-YTTag -Session $session -Tag 'Terminations'
Set-YTTag -Session $session -IssueID 'DEMO-1' -TagID $tag.id
```

The issue-modifying functions (`New-*`, `Set-*`) support `-WhatIf` and `-Confirm`.

## Pipelines

Functions that take issues accept pipeline input, so you can operate on many issues at once:

```powershell
'DEMO-1', 'DEMO-2', 'DEMO-3' | Get-YTIssue -Session $session | Set-YTIssueState -Session $session -Value 'Fixed'
```

## Making Raw Requests

This module calls the YouTrack REST API directly with `Invoke-RestMethod`. If you need a resource the module doesn't yet
wrap, build the URL from the session's `Url` property (which already ends in `/api/`) and send your own request:

```powershell
$headers = @{ 'Accept' = 'application/json' ; 'Authorization' = "Bearer $($session.ApiToken)" }
Invoke-RestMethod -Uri "$($session.Url)users/me?fields=login,email" -Headers $headers -Method Get
```

When you build a resource path from untrusted input (user input, file contents, etc.), URL-encode each segment with
[Protect-YTResourcePath](YouTrackAutomation/Functions/Protect-YTResourcePath.ps1) to avoid breaking the URL.

# Functions

## Sessions
* [New-YTSession](YouTrackAutomation/Functions/New-YTSession.ps1): creates a session object for all other functions.

## Issues
* [Get-YTIssue](YouTrackAutomation/Functions/Get-YTIssue.ps1): gets issues by ID/readable ID, with custom fields
  flattened onto the object.
* [New-YTIssue](YouTrackAutomation/Functions/New-YTIssue.ps1): creates an issue, optionally setting custom fields.
* [Find-YTDescription](YouTrackAutomation/Functions/Find-YTDescription.ps1): searches a project for issues by
  description text.
* [Set-YTIssueState](YouTrackAutomation/Functions/Set-YTIssueState.ps1): sets an issue's State (via its state machine).
* [Set-YTIssueAssignee](YouTrackAutomation/Functions/Set-YTIssueAssignee.ps1): sets an issue's Assignee.
* [Set-YTIssueCustomField](YouTrackAutomation/Functions/Set-YTIssueCustomField.ps1): sets a single-enum custom field.
* [Set-YTIssueDescription](YouTrackAutomation/Functions/Set-YTIssueDescription.ps1): replaces an issue's description.
* [Set-YTIssueLink](YouTrackAutomation/Functions/Set-YTIssueLink.ps1): links an issue to another issue.
* [Add-YTComment](YouTrackAutomation/Functions/Add-YTComment.ps1): adds a comment to an issue.
* [Add-YTWork](YouTrackAutomation/Functions/Add-YTWork.ps1): logs work time against an issue.
* [Get-YTIssueCustomField](YouTrackAutomation/Functions/Get-YTIssueCustomField.ps1): gets an issue's custom fields.
* [Get-YTIssueState](YouTrackAutomation/Functions/Get-YTIssueState.ps1): gets an issue's State custom field.

## Projects
* [Get-YTProject](YouTrackAutomation/Functions/Get-YTProject.ps1): gets projects (all, or by short name).
* [New-YTProject](YouTrackAutomation/Functions/New-YTProject.ps1): creates a project.
* [Remove-YTProject](YouTrackAutomation/Functions/Remove-YTProject.ps1): deletes a project.
* [Resolve-YTProjectId](YouTrackAutomation/Functions/Resolve-YTProjectId.ps1): resolves a project object/ID/short name
  to its project ID.

## Tags
* [Get-YTTag](YouTrackAutomation/Functions/Get-YTTag.ps1): gets a tag by name.
* [Add-YTTag](YouTrackAutomation/Functions/Add-YTTag.ps1): creates a new tag.
* [Set-YTTag](YouTrackAutomation/Functions/Set-YTTag.ps1): attaches an existing tag to issues.

## Users, Bundles, Commands, and Fields
* [Get-YTUser](YouTrackAutomation/Functions/Get-YTUser.ps1): gets a user by login/ID, or the current user with `-Me`.
* [Get-YTBundle](YouTrackAutomation/Functions/Get-YTBundle.ps1): gets a custom field bundle.
* [Invoke-YTCommand](YouTrackAutomation/Functions/Invoke-YTCommand.ps1): runs a command against one or more issues.
* [Get-YTEntityField](YouTrackAutomation/Functions/Get-YTEntityField.ps1): builds a `fields` list for a YouTrack entity.
* [Protect-YTResourcePath](YouTrackAutomation/Functions/Protect-YTResourcePath.ps1): URL-encodes untrusted resource path
  segments.

## Helpers
* [ConvertTo-YTObj](YouTrackAutomation/Functions/ConvertTo-YTObj.ps1): flattens an issue's custom fields onto the object.
* [ConvertTo-YTString](YouTrackAutomation/Functions/ConvertTo-YTString.ps1): escapes text for YouTrack markdown/wiki
  fields.
* [ConvertTo-MarkdownTable](YouTrackAutomation/Functions/ConvertTo-MarkdownTable.ps1): renders objects as a Markdown
  table.
