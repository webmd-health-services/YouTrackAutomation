
function Remove-YTProject
{
    <#
    .SYNOPSIS
    Removes a YouTrack project.

    .DESCRIPTiON
    The `Remove-YTProject` function deletes an entire project in YouTrack. Pass the project ID or short name to the
    `Project` parameter. You can also pipe the short name, the id, or a project object to `Remove-YTProject`.

    .EXAMPLE
    Remove-YTProject -Session $session -Project 'DEMO'

    Demonstrates removing the project with the 'DEMO' short name.

    .EXAMPLE
    Remove-YTProject -Session $session -Project '0-1'

    Demonstrates removing the project with the '0-1' id.

    .EXAMPLE
    Get-YTProject -Session $session -Project 'MYPROJ' | Remove-YTProject -Session $session

    Demonstrates that you can pipe project objects to `Remove-YTProject`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessage('PSShouldProcess', '')]
    param(
        # The session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or short name of the project to deleted.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('shortName')]
        [String] $Project
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $endpoint = Protect-YTPath -SafeBasePath 'admin/projects' -UnsafeChildPath $Project
        Invoke-YTRestMethod -Session $Session -Method Delete -Name $endpoint
    }
}