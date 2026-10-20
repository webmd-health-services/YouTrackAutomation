
function Set-YTTag
{
    <#
    .SYNOPSIS
    Attaches an existing tag to one or more YouTrack issues.

    .DESCRIPTION
    The `Set-YTTag` function attaches an existing tag to one or more issues. Pass the tag's ID (from `Get-YTTag`) to the
    `TagID` parameter and the issue(s) to the `IssueID` parameter, or pipe issue objects/IDs in. For each issue, an
    object is returned describing the tag and the issues currently carrying it.

    .EXAMPLE
    Set-YTTag -Session $session -IssueID 'DEMO-24025' -TagID '5-12'

    Demonstrates attaching the tag with ID `5-12` to issue `DEMO-24025`.

    .OUTPUTS
    One result object per issue, with the tag name, ID, and the issues carrying the tag.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue(s) to tag, as a readable ID or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The ID of the tag to attach. Get it with `Get-YTTag`.
        [Parameter(Mandatory, HelpMessage = 'Tag ID, get it from Get-YTTag')]
        [String] $TagID
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

        $body = @{ id = $TagID } | ConvertTo-Json -Depth 3
    }

    process
    {
        foreach ($id in $IssueID)
        {
            $url = "$($Session.Url)issues/$($id)/tags?fields=id,name,issues(idReadable)"

            if (-not $PSCmdlet.ShouldProcess($id, "add tag '$($TagID)'"))
            {
                continue
            }

            Write-Verbose "Setting tag '$($TagID)' on issue '$($id)'."
            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body |
                    Select-Object @{ Name = 'IssuesWithTag' ; Expression = { $_.issues.idReadable } }, 'name', 'id' |
                    Write-Output
            }
            catch
            {
                Write-Error -Message "Failed to tag issue '$($id)': $($_)" -ErrorAction $ErrorActionPreference
            }
        }
    }
}
