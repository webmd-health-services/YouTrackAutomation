
function New-YTProject
{
    <#
    .SYNOPSIS
    Creates a new project in YouTrack.

    .DESCRIPTION
    The `New-YTProject` function creates a new project in YouTrack. Pass the project name to the `Name` parameter, its
    short name to the `ShortName` parameter, and the user ID of the project's owner to the `LeaderID` parameter. Use
    `Get-YTUser` to look up a user's ID by login.

    .EXAMPLE
    New-YTProject -Session $session -Name 'Demo Project' -ShortName 'DEMO' -LeaderID '2-1'

    Demonstrates creating a project named `Demo Project` with short name `DEMO`, owned by the user with ID `2-1`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the project.
        [Parameter(Mandatory)]
        [String] $Name,

        # The short name of the project.
        [Parameter(Mandatory)]
        [String] $ShortName,

        # The user ID of the project owner. Use `Get-YTUser` to find a user's ID by login.
        [Parameter(Mandatory)]
        [String] $LeaderID,

        # The description of the project.
        [String] $Description,

        # Template project to use for the new project.
        [ValidateSet('scrum', 'kanban')]
        [String] $Template,

        # The fields to return on the created project.
        [String[]] $Property
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $project = @{
        name = $Name
        shortName = $ShortName
        leader = @{ id = $LeaderID }
    }

    if ($Description)
    {
        $project['description'] = $Description
    }

    if (-not $Property)
    {
        $Property = Get-YTEntityField -Type 'Project'
    }

    $fields = [Uri]::EscapeUriString(($Property -join ','))
    $url = "$($Session.Url)admin/projects?fields=${fields}"
    if ($Template)
    {
        $url += "&template=$($Template)"
    }

    $body = $project | ConvertTo-Json -Depth 50

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    if (-not $PSCmdlet.ShouldProcess($ShortName, 'create project'))
    {
        return
    }

    Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
}
