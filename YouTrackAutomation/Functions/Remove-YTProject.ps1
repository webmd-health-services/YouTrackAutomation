
function Remove-YTProject
{
    <#
    .SYNOPSIS
    Removes a YouTrack project.

    .DESCRIPTiON
    The `Remove-YTProject` function deletes an entire project in YouTrack. Pass the project object, the id of the
    object, or the short name of the project to the `Project` parameter.

    .EXAMPLE
    Remove-YTProject -Session $session -Project 'DEMO'

    Demonstrates removing the project with the 'DEMO' short name.

    .EXAMPLE
    Remove-YTProject -Session $session -Project '0-1'

    Demonstrates removing the project with the '0-1' id.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The project to be deleted. This can be a project object, project short name, or project ID.
        [Parameter(Mandatory)]
        [Object] $Project
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $projectId = Resolve-YTProjectId -Session $Session -Project $Project
    Invoke-YTRestMethod -Session $Session -Method Delete -Name "admin/projects/${ProjectId}"
}