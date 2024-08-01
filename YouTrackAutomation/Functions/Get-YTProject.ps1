
function Get-YTProject
{
    <#
    .SYNOPSIS
    Gets projects from YouTrack.

    .DESCRIPTION
    The `Get-YTProject` function gets projects from YouTrack. The function returns the following fields by default:

    * `id`
    * `name`
    * `shortName`

    In order to add additional fields to the response, use the `-AdditionalFields` parameter, with each field name being
    an entry in the string array.

    If the `-ProjectShortName` parameter is provided, the function will return only the project with the matching short
    name.

    .EXAMPLE
    Get-YTProject -Session $session

    Demonstrates fetching all projects from YouTrack. This will return the default fields for all projects.

    .EXAMPLE
    Get-YTProject -Session $session -ProjectShortName 'DEMO'

    Demonstrates fetching a specific project from YouTrack. This will return the default fields for the `DEMO` project.

    .EXAMPLE
    Get-YTProject -Session $session -AdditionalFields 'description'

    Demonstrates fetching all projects from YouTrack and including additional fields. This will return the default
    fields along with the description for all projects.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack Session. Create a new Session using `New-XWSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The short name of the project to get.
        [String] $ProjectShortName,

        # Additional fields to include in the response.
        [String[]] $AdditionalFields
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $fields = 'id,name,shortName'

    if ($AdditionalFields)
    {
        $fields += ",$($AdditionalFields -join ',')"
    }

    $projects = Invoke-YTRestMethod -Session $Session -Name "admin/projects?fields=$fields"

    if ($ProjectShortName)
    {
        $projects | Where-Object { $_.shortName -eq $ProjectShortName }
    }
    else
    {
        $projects
    }
}