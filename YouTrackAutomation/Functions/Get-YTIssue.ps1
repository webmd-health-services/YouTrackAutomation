
function Get-YTIssue
{
    <#
    .SYNOPSIS
    Gets an issue from YouTrack.

    .DESCRIPTION
    The `Get-YTIssue` function gets an issue from YouTrack using the issue ID or issue key. Pass the issue ID to the
    `Issue` parameter.

    .EXAMPLE
    Get-YTIssue -Session $session -Issue 'DEMO-1'

    Demonstrates fetching an issue based on the issue key. This will return the default fields for the `DEMO-1` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -Issue '3-4'

    Demonstrates fetching an issue based on the issue id. This will return the default fields for the `DEMO-5` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -Issue 'DEMO-1' -Property 'comments(id,author(name),text)'

    Demonstrates fetching an issue based on the issue key and including additional fields. This will return the default
    fields for the `DEMO-1` issue, as well as the comments for the issue along with the comment id, comment author,
    and comment text.
    #>
    [CmdletBinding()]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID (e.g. `3-4`) or readable ID (e.g., `DEMO-3`) of the issue to get.
        [Parameter(Mandatory, ParameterSetName='SpecificIssue')]
        [String] $Issue,

        # Fields to include in the response. This should be a comma-separated list of field names.
        [String[]] $Property
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not $Property)
    {
        $Property = Get-YTEntityField -Type 'Issue' -Depth $script:defaultIssueFieldDepth
    }

    $endpoint = 'issues'
    if ($Issue)
    {
        $endpoint = "${endpoint}/$([Uri]::EscapeDataString($Issue))"
    }

    Invoke-YTRestMethod -Session $Session -Name $endpoint -Property $Property
}