
function Resolve-YTProjectId
{
    <#
    .SYNOPSIS
    Gets ID for a project.

    .DESCRIPTION
    The `Resolve-YTProjectId` function takes in a project, project short name, or project id and returns the project id
    associated with the project provided.

    .EXAMPLE
    Resolve-YTProjectId -Session $session -Project 'DEMO'

    Demonstrates resolving the project id for the project with the `DEMO` short name.

    .EXAMPLE
    Resolve-YTProjectId -Session $session -Project '0-1'

    Demonstrates resolving the project id for the project with the `0-1` id.

    .EXAMPLE
    Resolve-YTProjectId -Session $session -Project $project

    Demonstrates resolving the project id using a project object.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Object] $Session,

        # The project to resolve the id for. Can be a project object, a project id, or a project short name.
        [Object] $Project
    )

    if ($Project | Get-Member -Name 'id')
    {
        return $Project.id
    }

    if (-not $Project -is [String])
    {
        $msg = "Failed to resolve project ""${Project}"": expected an object with an `id` property, a string ID " +
            '(e.g. ''0-0''), or a project short name.'
        Write-Error $msg
        return
    }

    if ($Project -match '^\d+-\d+$')
    {
        return $Project
    }

    return Get-YTProject -Session $Session -ShortName $Project | Select-Object -ExpandProperty 'id'
}