
function Get-YTTag
{
    <#
    .SYNOPSIS
    Gets a YouTrack tag by name.

    .DESCRIPTION
    The `Get-YTTag` function looks up a tag by name and returns its tag object, including the `id` needed by `Set-YTTag`.
    Pass the tag name to the `Tag` parameter.

    .EXAMPLE
    Get-YTTag -Session $session -Tag 'Terminations'

    Demonstrates getting the `Terminations` tag.

    .OUTPUTS
    The matching tag object(s).
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the tag to get.
        [Parameter(Mandatory, HelpMessage = 'Tag name')]
        [String] $Tag
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $url = "$($Session.Url)tags?fields=id,name&`$top=9999&`$skip=0"

    $headers = @{
        'Accept' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    try
    {
        $tagList = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    }
    catch
    {
        Write-Error -Message "Failed to get tags: $($_)" -ErrorAction $ErrorActionPreference
        return
    }

    $tagList | Where-Object { $_.name -eq $Tag } | Write-Output
}
