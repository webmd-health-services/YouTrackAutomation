
function Resolve-YTProjectId
{
    <#
    .SYNOPSIS
    Resolves a project reference to its YouTrack project ID.

    .DESCRIPTION
    The `Resolve-YTProjectId` function takes a project object, a project ID, or a project short name and returns the
    corresponding project ID. Project objects (anything with an `id` property) return their `id` directly. Strings that
    look like an ID (`0-1`) are returned as-is. Any other string is treated as a short name and looked up with
    `Get-YTProject`.

    .EXAMPLE
    Resolve-YTProjectId -Session $session -Project 'DEMO'

    Demonstrates resolving a short name to its project ID.

    .EXAMPLE
    Resolve-YTProjectId -Session $session -Project '0-1'

    Demonstrates that an ID is returned unchanged.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The project to resolve: a project object, a project ID, or a project short name.
        [Parameter(Mandatory)]
        [Object] $Project
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($Project -isnot [String] -and ($Project.PSObject.Properties.Name -contains 'id'))
    {
        return $Project.id
    }

    if ($Project -isnot [String])
    {
        $msg =
            "Failed to resolve project '$($Project)': expected an object with an 'id' property, a string ID " +
            "(e.g. '0-0'), or a project short name."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if ($Project -match '^\d+-\d+$')
    {
        return $Project
    }

    return Get-YTProject -Session $Session -ShortName $Project | Select-Object -ExpandProperty 'id'
}
