
function Add-YTTag
{
    <#
    .SYNOPSIS
    Creates a new tag in YouTrack.

    .DESCRIPTION
    The `Add-YTTag` function creates a new tag definition in YouTrack that can later be attached to issues with
    `Set-YTTag`. Pass the tag's name to the `Tag` parameter. Returns the created tag object.

    .EXAMPLE
    Add-YTTag -Session $session -Tag 'Terminations'

    Demonstrates creating a tag named `Terminations`.

    .OUTPUTS
    The created tag object.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the tag to create.
        [Parameter(Mandatory, HelpMessage = 'Tag name')]
        [String] $Tag
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $url = "$($Session.Url)tags?fields=id,name"

    $headers = @{
        'Accept' = 'application/json'
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $($Session.ApiToken)"
    }

    $body = @{ name = $Tag } | ConvertTo-Json -Depth 3

    if (-not $PSCmdlet.ShouldProcess($Tag, 'create tag'))
    {
        return
    }

    try
    {
        Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
    }
    catch
    {
        Write-Error -Message "Failed to create tag '$($Tag)': $($_)" -ErrorAction $ErrorActionPreference
    }
}
