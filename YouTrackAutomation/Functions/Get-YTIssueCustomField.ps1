
function Get-YTIssueCustomField
{
    <#
    .SYNOPSIS
    Gets an issue's custom fields.

    .DESCRIPTION
    The `Get-YTIssueCustomField` function gets an issue's custom fields. Pass the issue's ID or readable ID to the
    `Issue` parameter. All the custom fields for that issue are returned with their ID and name.

    To get a specific custom field, pass its name or ID to the `Field` parameter. To get a fully-typed object back (i.e.
    all the field's properties), also pass the field's type to the `Type` parameter. You can pipe custom field objects to
    `Get-YTIssueCustomField` to get full fields back.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-4'

    Demonstrates getting all an issue's custom fields.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-20' -Field 'State' -Type 'StateIssueCustomField'

    Demonstrates getting a specific field as a fully-typed object.
    #>
    [CmdletBinding(DefaultParameterSetName = 'AllFields')]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or readable ID of the issue.
        [Parameter(Mandatory)]
        [String] $Issue,

        # The name or ID of a specific custom field to get. Accepts pipeline input; piping field objects returns
        # fully-typed fields.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'SpecificField')]
        [Alias('id')]
        [Alias('name')]
        [String] $Field,

        # The field's type (e.g. `StateIssueCustomField`). Controls which properties exist on the returned object and is
        # required to return the field's value.
        [Parameter(ParameterSetName = 'SpecificField', ValueFromPipelineByPropertyName)]
        [Alias('$type')]
        [String] $Type
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $baseResource = Protect-YTResourcePath -SafeBasePath 'issues' -UnsafeChildPath $Issue
        $resource = "${baseResource}/customFields"

        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }
    }

    process
    {
        if ($Field)
        {
            $resource = Protect-YTResourcePath -SafeBasePath "${baseResource}/fields" -UnsafeChildPath $Field
        }

        $isTyped = $true
        if (-not $Type)
        {
            $isTyped = $false
            $Type = 'IssueCustomField'
        }

        $propertyNames = Get-YTEntityField -Type $Type -Depth 2

        # When the caller gives us the field's type, all its sub-types are known, so go one level deeper to return the
        # field's value.
        if ($isTyped)
        {
            $propertyNames = & {
                $propertyNames | Where-Object { -not $_.StartsWith('value(') } | Write-Output

                $depth = 3
                if ($Type -eq 'SingleUserIssueCustomField')
                {
                    # One more level here returns tags and saved queries, which is a lot.
                    $depth = 2
                }

                Get-YTEntityField -Type $Type -Depth $depth | Where-Object { $_.StartsWith('value(') }
            }
        }

        $queryParams = @{ fields = ($propertyNames -join ',') }

        Invoke-RestMethod -Uri "$($Session.Url)$($resource)" -Headers $headers -Method Get -Body $queryParams
    }
}
