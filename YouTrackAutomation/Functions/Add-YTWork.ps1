
function Add-YTWork
{
    <#
    .SYNOPSIS
    Logs work time against a YouTrack issue.

    .DESCRIPTION
    The `Add-YTWork` function logs work time (and an optional comment) against one or more issues using the YouTrack
    commands API. Pass the issue(s) to the `IssueID` parameter (or pipe them in) and the amount of work to the `Work`
    parameter, as a number followed by a unit, e.g. `15m` (15 minutes), `1h` (1 hour), `1d` (1 day), or `1w` (1 week).

    .EXAMPLE
    Add-YTWork -Session $session -IssueID 'DEMO-22650' -Work '15m'

    Demonstrates logging 15 minutes of work against issue `DEMO-22650`.

    .OUTPUTS
    None.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue(s) to log work against, as a readable ID or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The amount of work: a number followed by a unit, e.g. `15m`, `1h`, `1d`, or `1w`.
        [Parameter(Mandatory, HelpMessage = 'Work as a number then a unit, e.g. 15m, 1h, 1d')]
        [String] $Work,

        # An optional comment to attach to the work item.
        [String] $Comment
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $url = "$($Session.Url)commands?fields=issues(idReadable),time"

        $headers = @{
            'Accept' = 'application/json'
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }
    }

    process
    {
        foreach ($id in $IssueID)
        {
            $body = @{
                query = "Work $($Work)"
                issues = @(
                    @{ idReadable = $id }
                )
                silent = $false
                comment = $Comment
            } | ConvertTo-Json -Depth 5

            if (-not $PSCmdlet.ShouldProcess($id, "log work '$($Work)'"))
            {
                continue
            }

            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body | Out-Null
            }
            catch
            {
                Write-Error -Message "Failed to log work on issue '$($id)': $($_)" -ErrorAction $ErrorActionPreference
            }
        }
    }
}
