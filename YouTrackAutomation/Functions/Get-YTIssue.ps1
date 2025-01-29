
function Get-YTIssue
{
    <#
    .SYNOPSIS
    Gets an issue from YouTrack.

    .DESCRIPTION
    The `Get-YTIssue` function gets an issue from YouTrack using the issue ID or issue key. Pass the issue ID to the
    `IssueId` parameter. The function returns the following fields by default:

    * `id`
    * `idReadable`
    * `summary`
    * `description`
    * `project(name)`
    * `reporter(name)`
    * `attachments(id,name,url,created,author(name))`

    In order to add additional fields to the response, use the `AdditionalField` parameter, with each field name being
    an entry in the string array.

    .EXAMPLE
    Get-YTIssue -Session $session -IssueId 'DEMO-1'

    Demonstrates fetching an issue based on the issue key. This will return the default fields for the `DEMO-1` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -IssueId '3-4'

    Demonstrates fetching an issue based on the issue id. This will return the default fields for the `DEMO-5` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -IssueId 'DEMO-1' -AdditionalField 'comments(id,author(name),text)'

    Demonstrates fetching an issue based on the issue key and including additional fields. This will return the default
    fields for the `DEMO-1` issue, as well as the comments for the issue along with the comment id, comment author,
    and comment text.
    #>
    [CmdletBinding()]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID of the issue to get. This can be the issue key (`DEMO-3`) or the issue ID (`3-4`).
        [Parameter(Mandatory)]
        [String] $IssueId,

        # Additional fields to include in the response. This should be a comma-separated list of field names.
        [String[]] $AdditionalField
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $fields = 'id,idReadable,summary,description,project(name,shortName),reporter(name),attachments(id,name,url,created,author(name))'

    if ($AdditionalField)
    {
        $fields += ",$($AdditionalField -join ',')"
    }

    $fields = [Uri]::EscapeDataString($fields)

    Invoke-YTRestMethod -Session $Session -Name "issues/${IssueId}?fields=$fields"
}