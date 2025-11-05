
function New-YTProject
{
    <#
    .SYNOPSIS
    Creates a new project in YouTrack.

    .DESCRIPTION
    The `New-YTProject` function creates a new project in YouTrack. The function requires the following parameters:

    * `Name`: The name of the project.
    * `ShortName`: The short name of the project.
    * `Leader`: The id or the name of the project owner.

    .EXAMPLE
    New-YTProject -Session $session -Name 'Demo Project' -ShortName 'DEMO' -Leader 'admin'

    Demonstrates creating a new project in YouTrack with the name `Demo Project`, the short name `DEMO`, and the project
    owner `admin`.

    .EXAMPLE
    New-YTProject -Session $session -Name 'Demo Project' -ShortName 'DEMO' -Leader '2-1'

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

        # The id or the name of the project owner.
        [Parameter(Mandatory)]
        [String] $Leader,

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

    # TODO: require user to pass ID in or do a query to find user with specific name. Some installations of YouTrack
    # have thousands of users so this will effectively do nothing.
    if ($Leader -notmatch '\d+-\d+')
    {
        $Leader =
            Invoke-YTRestMethod -Session $Session -Name 'users' -Property 'name','id' |
            Where-Object 'name' -eq $Leader |
            Select-Object -ExpandProperty 'id'
    }

    $body = @{
        name = $Name;
        shortName = $ShortName;
        leader = @{
            id = $Leader;
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
                        -Name 'admin/projects' `
                        -Body $body `
                        -Property $Property `
                        -Method Post `
                        -QueryParameter $queryParams
}