
function New-YTIssue
{
    <#
    .SYNOPSIS
    Creates a new issue in YouTrack.

    .DESCRIPTION
    The `New-YTIssue` function creates a new issue in YouTrack. Pass the project's short name (or a project object with a
    `shortName` property) to the `Project` parameter and the issue's title to the `Summary` parameter. Optionally pass a
    description to the `Description` parameter.

    To set custom fields at creation time, pass one or more hashtables to the `CustomField` parameter. Each hashtable
    must contain the properties YouTrack requires for that field type, at minimum the field `name`, its `$type`, and a
    `value`. For example:

        $fields = @(
            @{ name = 'Priority' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Major' } },
            @{ name = 'Assignee' ; '$type' = 'SingleUserIssueCustomField' ; value = @{ login = 'admin' } }
        )
        New-YTIssue -Session $session -Project 'DEMO' -Summary 'New issue' -CustomField $fields

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue'

    Demonstrates creating an issue in the `DEMO` project.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'Write Docs' -Description 'Write YouTrackAutomation docs'

    Demonstrates creating an issue with a description.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'Triage' -CustomField @{ name = 'Priority' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Major' } }

    Demonstrates creating an issue and setting a custom field.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The project the issue is created in. Pass the project short name or a project object with a `shortName`
        # property.
        [Parameter(Mandatory)]
        [Object] $Project,

        # The summary (title) of the issue.
        [Parameter(Mandatory)]
        [Alias('Title')]
        [String] $Summary,

        # The description of the issue.
        [String] $Description,

        # Custom fields to set on the new issue. Each item is a hashtable with the properties YouTrack requires for that
        # field type (at minimum `name`, `$type`, and `value`).
        [hashtable[]] $CustomField
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $shortName = $Project
    if ($Project -isnot [String] -and ($Project.PSObject.Properties.Name -contains 'shortName'))
    {
        $shortName = $Project.shortName
    }

    $issue = @{
        project = @{ shortName = "$($shortName)" }
        summary = $Summary
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $issue['description'] = $Description
    }

    if ($CustomField)
    {
        $issue['customFields'] = $CustomField
    }

    $body = $issue | ConvertTo-Json -Depth 50

    $url =
        "$($Session.Url)issues" +
        '?fields=idReadable,summary,description,customFields(projectCustomField(field(name)),value(name))'

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    if (-not $PSCmdlet.ShouldProcess("project '$($shortName)'", "create issue '$($Summary)'"))
    {
        return
    }

    Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
}
