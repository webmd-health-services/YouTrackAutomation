
function Get-YTProject
{
    <#
    .SYNOPSIS
    Gets projects from YouTrack.

    .DESCRIPTION
    The `Get-YTProject` function gets projects from YouTrack. By default, all projects are returned. To return a
    specific project pass in its short name to the `ShortName` parameter. Wildcards are not supported.

    The function returns the following fields by default:

    * `id`
    * `name`
    * `shortName`

    In order to add additional fields to the response, use the `AdditionalField` parameter, with each field name being
    an entry in the string array.

    If the `ShortName` parameter is provided, the function will return only the project with the matching short
    name.

    .EXAMPLE
    Get-YTProject -Session $session

    Demonstrates fetching all projects from YouTrack. This will return the default fields for all projects.

    .EXAMPLE
    Get-YTProject -Session $session -ShortName 'DEMO'

    Demonstrates fetching a specific project from YouTrack. This will return the default fields for the `DEMO` project.

    .EXAMPLE
    Get-YTProject -Session $session -AdditionalField 'description'

    Demonstrates fetching all projects from YouTrack and including additional fields. This will return the default
    fields along with the description for all projects.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack Session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The short name of the project to get.
        [String] $ShortName,

        # Additional fields to include in the response.
        [String[]] $AdditionalField
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $fields = 'id,name,shortName'

    if ($AdditionalField)
    {
        $fields += ",$($AdditionalField -join ',')"
    }

    $fields = [Uri]::EscapeDataString($fields)

    $projects = Invoke-YTRestMethod -Session $Session -Name "admin/projects?fields=$fields"

    if ($ShortName)
    {
        return $projects | Where-Object 'shortName' -EQ $ShortName
    }

    return $projects
}