
function Find-YTDescription
{
    <#
    .SYNOPSIS
    Searches a YouTrack project for issues by description text.

    .DESCRIPTION
    The `Find-YTDescription` function searches a project for issues whose description matches a search string. Pass the
    text to the `Description` parameter and the project short name to the `Project` parameter. Matching issues are
    returned with their custom fields flattened onto each object (via `ConvertTo-YTObj`).

    .EXAMPLE
    Find-YTDescription -Session $session -Description 'Access Termination Date:' -Project 'DEMO'

    Demonstrates finding all issues in the `DEMO` project whose description contains "Access Termination Date:".
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The text to search for in issue descriptions.
        [Parameter(Mandatory)]
        [String] $Description,

        # The short name of the project to search.
        [Parameter(Mandatory)]
        [String] $Project
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $fields =
        'id,idReadable,summary,description,' +
        'links(id,direction,linkType(name),issues(id,idReadable,summary)),' +
        'project(id,name,shortName),attachments(id,name,url,created,author(name)),' +
        'customFields(name,id,value(name))'

    $query = "description:$($Description) project:$($Project)"

    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    $queryParams = @{
        fields = $fields
        query = $query
    }

    $url = "$($Session.Url)issues"

    try
    {
        $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers -Body $queryParams
    }
    catch
    {
        Write-Error -Message "Failed to search project '$($Project)': $($_)" -ErrorAction $ErrorActionPreference
        return
    }

    foreach ($issue in $response)
    {
        ConvertTo-YTObj -YTIssue $issue | Write-Output
    }
}
