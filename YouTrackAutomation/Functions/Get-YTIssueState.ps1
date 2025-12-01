
function Get-YTIssueState
{
    <#
    .SYNOPSIS
    Gets an issue's state custom field.

    .DESCRIPTION
    The `Get-YTIssueState` function gets an issue's `State` custom field. Pass the issue's ID, or the issue's readable
    ID to the `Issue` parameter (you can also pipe issue objects, issue IDs, or issue readable IDs to the function to
    get multiple issues' states). The issue's State custom field is returned. The function handles issues that can be in
    any state and transitioned to any state (where the state is of type `StateIssueCustomField`) and issues that use a
    state machine (i.e. where the state field is of type `StateMachineIssueCustomField`). In order to return the correct
    properties on the return object, this function makes two requests to the YouTrack API: one to get the State field's
    type, and another to get the actual field.

    .EXAMPLE
    Get-YTIssueState -Session $session -Issue 'DEMO-1'

    Demonstrates that you can pass an issue's readable ID to the `Issue` parameter to get that issue's state.

    .EXAMPLE
    Get-YTIssueState -Session $session -Issue '2-4832'

    Demonstrates that you can pass an issue's ID to the `Issue` parameter to get that issue's state.

    .EXAMPLE
    Get-YTIssueState -Session $session -Issue (Get-YTIssue -Session $session -Issue 'DEMO-1')

    Demonstrates that you can pass an issue object to the `Issue` parameter to get that issue's state.

    .EXAMPLE
    (Get-YTIssue -Session $session -Issue 'DEMO-1'),'DEMO-2','2-238' | Get-YTIssueState -Session $session

    Demonstrates that you can pipe issue objects, issue IDs, and issue readable IDs to `Get-YTIssueState` to get muliple
    issues' states.
    #>
    [CmdletBinding()]
    param(
        # The session to the instance of YouTrack to connect to. Use `New-YTSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue whose state to get. Can be an issue object, issue ID, or an issue's readable ID. Issue objects,
        # issue IDs, and issue readable IDs can also be piped to `Get-YTIssueState`.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('idReadable')]
        [String] $Issue
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        # YouTrack has two types of state fields. In order to get the right fields, we need to know which state field
        # the issue has.
        $field =
            Get-YTIssueCustomField -Session $Session -Issue $Issue |
            Where-Object '$type' -In @('StateIssueCustomField', 'StateMachineIssueCustomField')

        if (-not $field)
        {
            $msg = "Failed to get ${Issue} issue's State field because that issue doesn't have a state field."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        $stateFieldCount = ($field | Measure-Object).Count
        if ($stateFieldCount -gt 1)
        {
            $stateFieldsMsg = ($field | Select-Object -ExpandProperty 'name') -join ', '
            $msg = "Failed to get state for issue ${Issue} because that issue has ${stateFieldCount} state fields: " +
                   "${stateFieldsMsg}."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }

        Get-YTIssueCustomField -Session $Session -Issue $Issue -Field 'State' -Type $field.'$type'
    }
}
