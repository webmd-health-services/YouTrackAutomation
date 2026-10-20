
function Set-YTIssueState
{
    <#
    .SYNOPSIS
    Sets the State custom field on an existing YouTrack issue.

    .DESCRIPTION
    The `Set-YTIssueState` function changes the `State` custom field on an existing issue, moving it through the issue's
    state machine. Pass the issue's readable ID or internal ID to the `IssueID` parameter and the new state name to the
    `Value` parameter.

    If `Value` is not one of the issue's currently valid next states, the function writes an error listing the valid
    options and makes no change.

    .EXAMPLE
    Set-YTIssueState -Session $session -IssueID 'DEMO-25' -Value 'Open'

    Demonstrates setting the state of issue `DEMO-25` to `Open`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue to update, as a readable ID (`DEMO-25`) or internal ID (`3-4`).
        [Parameter(Mandatory)]
        [String] $IssueID,

        # The new state value.
        [Parameter(Mandatory)]
        [String] $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    $issue = Get-YTIssue -Session $Session -IssueId $IssueID
    $fieldID = $issue.customFields | Where-Object { $_.name -eq 'State' } | Select-Object -ExpandProperty 'id'

    $url = "$($Session.Url)issues/$($IssueID)/fields/$($fieldID)/possibleEvents?fields=id,name,presentation"
    $bundle = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    if ($Value -notin $bundle.name)
    {
        $msg =
            "'$($Value)' is not a valid next State for issue '$($IssueID)'. The possible next states are: " +
            "$($bundle.name -join ', ')."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $eventId = $bundle | Where-Object { $_.name -eq $Value } | Select-Object -ExpandProperty 'id'
    $url = "$($Session.Url)issues/$($IssueID)/fields/$($fieldID)?fields=`$type,id,Event(presentation,`$type,id)"
    $body = @{
        id = "$($fieldID)"
        '$type' = 'StateMachineIssueCustomField'
        event = @{
            presentation = "$($Value)"
            '$type' = 'Event'
            id = "$($eventId)"
        }
    } | ConvertTo-Json -Depth 5

    if (-not $PSCmdlet.ShouldProcess($IssueID, "set State to '$($Value)'"))
    {
        return
    }

    try
    {
        Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body | Out-Null
    }
    catch
    {
        Write-Error -Message "Failed to update State on issue '$($IssueID)': $($_)" -ErrorAction $ErrorActionPreference
        return
    }

    Get-YTIssue -Session $Session -IssueId $IssueID
}
