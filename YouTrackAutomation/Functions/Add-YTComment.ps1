
function Add-YTComment
{
    <#
    .SYNOPSIS
    Adds a comment to a YouTrack issue.

    .DESCRIPTION
    The `Add-YTComment` function adds a comment to one or more existing issues. Pass the issue's readable ID or internal
    ID to the `IssueID` parameter (or pipe issue objects/IDs in) and the comment text to the `Comment` parameter.

    .EXAMPLE
    Add-YTComment -Session $session -IssueID 'DEMO-24025' -Comment 'Investigating.'

    Demonstrates adding a comment to issue `DEMO-24025`.

    .OUTPUTS
    None.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue(s) to comment on, as a readable ID (`DEMO-24025`) or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The comment text.
        [Parameter(Mandatory, HelpMessage = 'Comment text')]
        [String] $Comment
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $headers = @{
            'Accept' = 'application/json'
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }

        $body = @{ text = $Comment } | ConvertTo-Json -Depth 3
    }

    process
    {
        foreach ($id in $IssueID)
        {
            $url = "$($Session.Url)issues/$($id)/comments?fields=id,text,author(login)"

            if (-not $PSCmdlet.ShouldProcess($id, 'add comment'))
            {
                continue
            }

            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body | Out-Null
            }
            catch
            {
                Write-Error -Message "Failed to comment on issue '$($id)': $($_)" -ErrorAction $ErrorActionPreference
            }
        }
    }
}
