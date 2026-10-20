
function Get-YTIssue
{
    <#
    .SYNOPSIS
    Gets one or more issues from YouTrack.

    .DESCRIPTION
    The `Get-YTIssue` function gets issues from YouTrack by issue ID (`3-4`) or readable ID (`DEMO-3`). Pass one or more
    IDs to the `IssueId` parameter, or pipe issue objects, issue IDs, and/or readable IDs to the function.

    A set of default fields is returned for each issue, including the issue's custom fields. The custom fields are also
    flattened onto the returned object as top-level properties (via `ConvertTo-YTObj`) so, e.g., an issue's `State`
    custom field is available as `$issue.State`.

    .EXAMPLE
    Get-YTIssue -Session $session -IssueId 'DEMO-1'

    Demonstrates fetching an issue by its readable ID.

    .EXAMPLE
    'DEMO-1', 'DEMO-2' | Get-YTIssue -Session $session

    Demonstrates fetching multiple issues by piping their readable IDs.
    #>
    [CmdletBinding()]
    param(
        # The ID of the issue to get. This can be the readable ID (`DEMO-3`) or the internal ID (`3-4`). Accepts an
        # array and pipeline input.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueId,

        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $fields =
            'id,idReadable,summary,description,tags(name,id),' +
            'links(id,direction,linkType(name),issues(id,idReadable,summary)),' +
            'project(id,name,shortName),attachments(id,name,url,created,author(name)),' +
            'customFields(name,id,value(name,minutes,presentation))'

        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }
    }

    process
    {
        foreach ($id in $IssueId)
        {
            $apiUrl = "$($Session.Url)issues/$($id)"
            $queryParams = @{ fields = $fields }

            try
            {
                $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -Body $queryParams
            }
            catch
            {
                Write-Error -Message "Failed to retrieve issue '$($id)': $($_)" -ErrorAction $ErrorActionPreference
                continue
            }

            ConvertTo-YTObj -YTIssue $response | Write-Output
        }
    }
}
