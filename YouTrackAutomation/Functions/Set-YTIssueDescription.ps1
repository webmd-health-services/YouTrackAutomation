
function Set-YTIssueDescription
{
    <#
    .SYNOPSIS
    Replaces the description of an existing YouTrack issue.

    .DESCRIPTION
    The `Set-YTIssueDescription` function replaces the description text of an existing issue. Pass the issue's readable ID
    or internal ID to the `Issue` parameter and the new description to the `Description` parameter.

    .EXAMPLE
    Set-YTIssueDescription -Session $session -Issue 'DEMO-25251' -Description 'Updated description.'

    Demonstrates replacing the description of issue `DEMO-25251`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue to update, as a readable ID (`DEMO-25251`) or internal ID.
        [Parameter(Mandatory)]
        [String] $Issue,

        # The description that replaces the issue's current description.
        [Parameter(Mandatory)]
        [String] $Description
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $url = "$($Session.Url)issues/$($Issue)?fields=description,name,idReadable,customFields(name,value(name))"

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    $body = @{
        description = $Description
        '$type' = 'Issue'
    } | ConvertTo-Json -Depth 3

    if (-not $PSCmdlet.ShouldProcess($Issue, 'set description'))
    {
        return
    }

    try
    {
        Invoke-RestMethod -Uri $url -Headers $headers -Body $body -Method Post
    }
    catch
    {
        Write-Error -Message "Failed to set description on issue '$($Issue)': $($_)" -ErrorAction $ErrorActionPreference
    }
}
