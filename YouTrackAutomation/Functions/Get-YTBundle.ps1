
function Get-YTBundle
{
    <#
    .SYNOPSIS
    Gets a bundle from YouTrack.

    .DESCRIPTION
    The `Get-YTBundle` function gets a bundle from YouTrack. Pass the bundle ID to the ID parameter. Pass the bundle's
    type to the `Type` parameter. The function returns the bundle.

    To get a bundle ID and type from an issue, use `Get-YTIssueCustomField` for the specific field. The return object
    will have a `value.bundle` property. You can pipe the `value.bundle` object to this function, or pass the
    `value.bundle.id` property to the `ID` parameter, and the `value.bundle.'$type'` property to the `Type` parameter.

    .EXAMPLE
    Get-YTBundle -Session $session -ID 136-0 -Type 'EnumBundle'

    Demonstrates how to get a bundle by passing its ID to the `ID` parameter and its type to the `Type` parameter.

    .EXAMPLE
    (Get-YTIssueCustomField -Session $session -Issue 'DEMO-1' -Field 'State').value.bundle | Get-YTBundle -Session $session

    Demonstrates how to get a bundle from an issue's custom field. In this example, the bundle for the DEMO-2 issue's
    state field is returned.
    #>
    [CmdletBinding()]
    param(
        # The session to the instance of YouTrack. Use `New-YTSession` to create sessions.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID of the bundle to get.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String] $ID,

        # The Type of bundle to get.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('$type')]
        [String] $Type
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $typeResourceName = $Type.ToLowerInvariant() -replace 'bundle$', ''
        $resource =
            Protect-YTResourcePath -SafeBasePath 'admin/customFieldSettings/bundles' -UnsafeChildPath $typeResourceName,$ID

        $fields = Get-YTEntityField -Type $Type -Depth 2
        if (-not $fields)
        {
            $fields = Get-YTEntityField -Type 'Bundle' -Depth 2
        }

        Invoke-YTRestMethod -Session $Session -Resource $resource -Property $fields
    }

}