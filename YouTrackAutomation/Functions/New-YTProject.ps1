
function New-YTProject
{
    <#
    .SYNOPSIS
    Creates a new project in YouTrack.

    .DESCRIPTION
    The `New-YTProject` function creates a new project in YouTrack. The function requires the following parameters:

    * `Name`: The name of the project.
    * `ShortName`: The short name of the project.
    * `LeaderID`: The user id of the project owner.

    .EXAMPLE
    New-YTProject -Session $session -Name 'Demo Project' -ShortName 'DEMO' -LeaderID '2-1'

    Demonstrates creating a new project in YouTrack with the name `Demo Project`, the short name `DEMO`, and the project
    owner `admin`.

    .EXAMPLE
    New-YTProject -Session $session -Name 'Demo Project' -ShortName 'DEMO' -LeaderID '2-1'

    Demonstrates creating a new project in YouTrack with the name `Demo Project`, the short name `DEMO`, and the project
    owner `admin`, but using the project owner's id instead of their name.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack Session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the project.
        [Parameter(Mandatory)]
        [String] $Name,

        # The short name of the project.
        [Parameter(Mandatory)]
        [String] $ShortName,

        # The user id of the project owner. Use `Get-YTUser` to find users by login to get their IDs.
        [Parameter(Mandatory)]
        [String] $LeaderID,

        # The description of the project.
        [String] $Description,

        # Template project to use for the new project.
        [ValidateSet('scrum', 'kanban')]
        [String] $Template,

        # Additional fields to include in the response.
        [String[]] $Property
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $body = @{
        name = $Name;
        shortName = $ShortName;
        leader = @{
            id = $LeaderID;
        };
    }

    if ($Description)
    {
        $body['description'] = $Description
    }

    if (-not $Property)
    {
        $Property = Get-YTEntityField -Type 'Project'
    }

    $queryParams = @{}
    if ($Template)
    {
        $queryParams['template'] = $Template
    }

    Invoke-YTRestMethod -Session $Session `
                        -Resource 'admin/projects' `
                        -Body $body `
                        -Property $Property `
                        -Method Post `
                        -QueryParameter $queryParams
}