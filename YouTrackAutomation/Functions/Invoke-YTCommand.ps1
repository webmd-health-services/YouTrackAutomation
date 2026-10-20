
function Invoke-YTCommand
{
    <#
    .SYNOPSIS
    Runs a command against one or more YouTrack issues.

    .DESCRIPTION
    The `Invoke-YTCommand` function calls the YouTrack REST API's command resource. Pass the command/query to run to the
    `Query` parameter and the issue(s) to run it against to the `Issue` parameter (readable IDs, IDs, or issue objects;
    they can also be piped in). All the issues are sent in a single request.

    If you get an error like "issue id expected: NUM-NUM", the query contains an internal issue ID where a readable ID is
    required. Use the issue's readable ID.

    .LINK
    https://www.jetbrains.com/help/youtrack/devportal/api-usecase-commands.html

    .EXAMPLE
    Invoke-YTCommand -Session $session -Query 'subtask of: DEMO-3' -Issue 'DEMO-1'

    Demonstrates making `DEMO-1` a subtask of `DEMO-3`.

    .EXAMPLE
    'DEMO-1', 'DEMO-2' | Invoke-YTCommand -Session $session -Query 'State Fixed'

    Demonstrates piping readable IDs to run a command in bulk.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The command/query to run.
        [Parameter(Mandatory)]
        [String] $Query,

        # The issue(s) to run the command against. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('idReadable')]
        [String[]] $Issue
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $issues = [Collections.ArrayList]::new()
    }

    process
    {
        foreach ($item in $Issue)
        {
            [void]$issues.Add(@{ idReadable = $item })
        }
    }

    end
    {
        $body = @{
            query = $Query
            issues = $issues.ToArray()
        } | ConvertTo-Json -Depth 50

        $headers = @{
            'Accept' = 'application/json'
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }

        Invoke-RestMethod -Method Post -Uri "$($Session.Url)commands" -Headers $headers -Body $body |
            ConvertTo-Json -Depth 50 |
            Write-Verbose
    }
}
