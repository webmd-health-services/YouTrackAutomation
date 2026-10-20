
function Remove-YTProject
{
    <#
    .SYNOPSIS
    Removes a YouTrack project.

    .DESCRIPTION
    The `Remove-YTProject` function deletes an entire project in YouTrack. Pass the project ID or short name to the
    `Project` parameter. You can also pipe the short name, the ID, or a project object to `Remove-YTProject`. Supports
    `-WhatIf` and `-Confirm`.

    .EXAMPLE
    Remove-YTProject -Session $session -Project 'DEMO'

    Demonstrates removing the project with the `DEMO` short name.

    .EXAMPLE
    Get-YTProject -Session $session -ShortName 'MYPROJ' | Remove-YTProject -Session $session

    Demonstrates piping a project object to `Remove-YTProject`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or short name of the project to delete.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('shortName')]
        [String] $Project
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $resource = Protect-YTResourcePath -SafeBasePath 'admin/projects' -UnsafeChildPath $Project

        if (-not $PSCmdlet.ShouldProcess($Project, 'remove project'))
        {
            return
        }

        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }

        Invoke-RestMethod -Method Delete -Uri "$($Session.Url)$($resource)" -Headers $headers
    }
}
