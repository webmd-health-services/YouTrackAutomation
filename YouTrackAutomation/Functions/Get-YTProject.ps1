
function Get-YTProject
{
    <#
    .SYNOPSIS
    Gets projects from YouTrack.

    .DESCRIPTION
    The `Get-YTProject` function gets projects from YouTrack. By default, all projects are returned, fetched in batches
    so large instances are fully paged. To return a specific project, pass its short name to the `ShortName` parameter.
    Wildcards are not supported.

    The `id`, `name`, and `shortName` fields are returned by default. Use the `AdditionalField` parameter to request more
    fields; each entry is a field name.

    .EXAMPLE
    Get-YTProject -Session $session

    Demonstrates fetching all projects.

    .EXAMPLE
    Get-YTProject -Session $session -ShortName 'DEMO'

    Demonstrates fetching a single project by its short name.

    .EXAMPLE
    Get-YTProject -Session $session -AdditionalField 'description'

    Demonstrates requesting the `description` field in addition to the defaults.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The short name of a specific project to get.
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
    $fields = [Uri]::EscapeUriString($fields)

    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    $batchSize = 20
    $skip = 0
    $allProjects = @()
    do
    {
        $url = "$($Session.Url)admin/projects?fields=${fields}&`$top=${batchSize}&`$skip=${skip}"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        if ($response)
        {
            $allProjects += $response
        }
        $skip += $batchSize
    }
    while ($response)

    if ($ShortName)
    {
        return $allProjects | Where-Object 'shortName' -EQ $ShortName
    }

    return $allProjects
}
