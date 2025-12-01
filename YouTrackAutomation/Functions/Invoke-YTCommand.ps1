
function Invoke-YTCommand
{
    <#
    .SYNOPSIS
    Calls the `command` REST API resource.

    .DESCRIPTION
    The `Invoke-YTCommand` function calls the YouTrack REST API's [command
    resource](https://www.jetbrains.com/help/youtrack/devportal/resource-api-commands.html). Pass the query to execute
    to the `Query` parameter. Pass a list of issue IDs or readable IDs to the `Issue` parameter.  You can also pipe the
    IDs and readable IDs, or you can pipe in issue objects to the function (objects must have an `id` or `idReadable`
    property). When piping or passing multiple issues, the fuction only makes one request to the API.

    If you get an error that says something like "issue id expected: NUM-NUM", it means that the query contains an issue
    ID instead of an issue's readable ID. Use the issue's readable ID instead.

    .LINK
    https://www.jetbrains.com/help/youtrack/devportal/api-usecase-commands.html

    .EXAMPLE
    Invoke-YTCommand -Session $session -Query 'subtask of: 3-3' -Issue 'DEMO-1'

    Demonstrates how to make an issue a subtask of another. In this example, DEMO-1 will be a subtask of the issue with
    ID 3-3.

    .EXAMPLE

    'DEMO-1','DEMO-2' | Invoke-YTCommand -Session $session -Query 'subtask of: 3-3'

    Demonstrates that you can pipe issue readable IDs to `Invoke-YTCommand` to bulk operate
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory)]
        [String] $Query,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('idReadable')]
        [String[]] $Issue
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $issues = [collections.ArrayList]::New()
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
        # Must be an array.
        $body = @{
            'query' = $Query;
            'issues' = $issues.ToArray();
        }

        Invoke-YTRestMethod -Session $Session -Resource 'commands' -Body $body -Method Post |
            ConvertTo-Json -Depth 50 |
            Write-Verbose
    }
}
