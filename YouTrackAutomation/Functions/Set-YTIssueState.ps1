
function Set-YTIssueState
{
    <#
    .SYNOPSIS
    Sets an issue's state.

    .DESCRIPTION
    The `Set-YTIssueState` function set's a YouTrack issue's state. Pass the issue ID or readable ID to the `Issue`
    parameter (you can also pipe issue objects, issue IDs, or issue readable IDs to the function to set the state on
    multiple issues). Pass the ID or state name to the `State` parameter. The function handles issues that can be in any
    state and transitioned to any state (where the state is of type `StateIssueCustomField`) and issues that use a state
    machine (i.e. where the state field is of type `StateMachineIssueCustomField`).

    For each issue, the function makes the following request to YouTrack:

    * get the custom fields to find the state field
    * get the next possible, valid states for the issue
    * set the state

    If the state passed in isn't a valid next state, the function writes an error, which will is the valid next states.
    Each state will be listed as a `name/ID` pair. You can use either name or ID as the value of the `State` parameter.

    .EXAMPLE
    Set-YTIssueState -Session $session -Issue 'DEMO-1' -State 'In Progress'

    Demonstrates that you can use an issue's readable ID as the value for the `Issue` parameter and that you can use a
    state's name as the value for the `State` parameter.

    .EXAMPLE
    Set-YTIssueState -Session $session -Issue '2-437823' -State '103-7'

    Demonstrates that you can use an issue's ID as the value for the `Issue` parameter and that you can use a state's ID
    as the value for the `State` parameter.

    .EXAMPLE
    $issue,'DEM0-1','2-4873' | Set-YTIssue -Session $session -State 'In Progress'

    Demonstrates that you can pipe issue objects, issue IDs, and issue readable IDs to `Set-YTIssue` to bulk update
    state.
    #>
    [CmdletBinding()]
    param(
        # The session to the instance of YouTrack to connect to. Use `New-YTSession` to create a session.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue whose state to update. Can be an issue object, issue ID, or issue readable ID. Multiple values can
        # be piped to `Set-YTIssue` state.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('idReadable')]
        [Alias('id')]
        [String] $Issue,

        # The new state of the issue. Can be the state's name or ID.
        [Parameter(Mandatory)]
        [String] $State
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $stateField = Get-YTIssueState -Session $Session -Issue $Issue
        if (-not $stateField)
        {
            return
        }

        $stateFieldType = $stateField.'$type'
        $setStateBody = @{
            id = $stateField.id
            name = $stateField.name
            '$type' = $stateFieldType
        }
        # The issue's state can be any one from a list of states.
        if ($stateFieldType -eq 'StateIssueCustomField')
        {
            # The state bundle for this issue's state field has the possible values.
            $stateBundle = $stateField.value.bundle | Get-YTBundle -Session $Session
            if (-not $stateBundle)
            {
                $msg = "Failed to set ${Issue} issue's state because that issue's state field is missing a state bundle, " +
                    'which is the list of possible states for the issue.'
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }

            $validStatesIds = $stateBundle.values | Select-Object -ExpandProperty 'id'
            $validStateNames = $stateBundle.values | Select-Object -ExpandProperty 'name'

            if ($State -in $validStatesIds)
            {
                $setStateBody['value'] = @{ id = $State }
            }
            elseif ($State -in $validStateNames)
            {
                $setStateBody['value'] = @{ name = $State }
            }
            else
            {
                $validStatesMsg = $stateBundle.values | ForEach-Object { "$($_.name)/$($_.id)" }
                $msg = "Failed to update ${Issue} issue's state to ""${State}"" because that state is not a possible " +
                    "next state for that issue. Possible next states are: $($validStatesMsg -join ', ')."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }
        }
        # The issue's state has a state machine workflow.
        elseif ($stateFieldType -eq 'StateMachineIssueCustomField')
        {
            $validStateIds = $stateField.possibleEvents | Select-Object -ExpandProperty 'id'
            $validStateNames = $stateField.possibleEvents | Select-Object -ExpandProperty 'presentation'

            if ($State -in $validStateIds)
            {
                $setStateBody['event'] = @{ id = $State }
            }
            elseif ($State -in $validStateNames)
            {
                $setStateBody['event'] = @{ name = $State }
            }
            else
            {
                $validStatesMsg = $stateField.possibleEvents | ForEach-Object { "$($_.presentation)/$($_.id)" }
                $msg = "Failed to update ${Issue} issue's state to ""${State}"" because that state is not a possible " +
                       "next state for that issue. Possible next states are: $($validStatesMsg -join ', ')."
                Write-Error -Message $msg -ErrorAction $ErrorActionPreference
                return
            }
        }
        else
        {
            $msg = "Failed to set ${Issue} issue's state because that issue's state field type, ${stateFieldType}, " +
                   'isn''t supported.'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        }

        $endpoint = Protect-YTPath -SafeBasePath 'issues' -UnsafeChildPath $Issue,'fields',$stateField.name

        Invoke-YTRestMethod -Session $Session -Name $endpoint -Body $setStateBody -Method Post
    }
}