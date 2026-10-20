
function Get-YTBundle
{
    <#
    .SYNOPSIS
    Gets a bundle from YouTrack.

    .DESCRIPTION
    The `Get-YTBundle` function gets a bundle from YouTrack. Pass the bundle ID to the `ID` parameter and the bundle's
    type to the `Type` parameter. The function returns the bundle.

    To get a bundle ID and type from an issue, use `Get-YTIssueCustomField` for the specific field. The returned object
    has a `value.bundle` property you can pipe to this function.

    .EXAMPLE
    Get-YTBundle -Session $session -ID '136-0' -Type 'EnumBundle'

    Demonstrates getting a bundle by its ID and type.

    .EXAMPLE
    (Get-YTIssueCustomField -Session $session -Issue 'DEMO-1' -Field 'State').value.bundle | Get-YTBundle -Session $session

    Demonstrates getting a bundle from an issue's custom field.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID of the bundle to get.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [String] $ID,

        # The type of bundle to get.
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
            Protect-YTResourcePath -SafeBasePath 'admin/customFieldSettings/bundles' `
                                   -UnsafeChildPath $typeResourceName, $ID

        $fields = Get-YTEntityField -Type $Type -Depth 2
        if (-not $fields)
        {
            $fields = Get-YTEntityField -Type 'Bundle' -Depth 2
        }

        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }

        $queryParams = @{ fields = ($fields -join ',') }

        Invoke-RestMethod -Uri "$($Session.Url)$($resource)" -Headers $headers -Method Get -Body $queryParams
    }
}
