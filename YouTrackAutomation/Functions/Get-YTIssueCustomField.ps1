
function Get-YTIssueCustomField
{
    <#
    .SYNOPSIS
    Gets an issue's custom fields.

    .DESCRIPTION
    The `Get-YTIssueCustomField` function gets an issue's custom fields. Pass the issue's ID or readable ID to the
    `Issue` parameter. All the custom fields for that issue are returned along with their ID and name (value).

    To get a specific custom field, pass its name or ID to the `Field` parameter. To get just the field's value, use the
    `Value` switch.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-4'

    Demonstrates how to get all an issue's custom fields by passing the issue's ID or readable ID to the `Issue`
    parameter.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-20' -Field 'State'

    Demonstrates how to get a specific field by passings its ID or name to the `Field` parameter.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-20' -Field 'State' -ValueOnly

    Demonstrates how to get just the value of a custom field using the `ValueOnly` switch.
    #>
    [CmdletBinding(DefaultParameterSetName='AllFields')]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID of the issue.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [Alias('idReadable')]
        [String] $Issue,

        # The name or ID of the specific custom field to get. Default is to return all the issue's custom fields.
        [Parameter(Mandatory, ParameterSetName='SpecificField')]
        [String] $Field,

        # Returns only the value of the custom field.
        [Parameter(ParameterSetName='SpecificField')]
        [switch] $ValueOnly

        # TODO: Add a Type parameter so that all of a specific custom field's data is returned. Will need to iterate
        # through all the issue custom field entities at https://www.jetbrains.com/help/youtrack/devportal/api-entity-IssueCustomField.html
        # and add them to the list of fields in YouTrackAutomation.psm1. Add a ValidateSet attribute for all the known
        # issue custom type entity names.
        #
        # Maybe make the type optional and if it isn't returned, make a request to get the field's type, then another
        # request to get its value?
        # [ValidateSet('MultiBuildIssueCustomField', 'MultiEnumIssueCustomField', ...)]
        # [String] $Type
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $baseEndpoint = Protect-YTPath -SafeBasePath 'issues' -UnsafeChildPath $Issue
        $endpoint = "${baseEndpoint}/customFields"

        if ($Field)
        {
            $endpoint = Protect-YTPath -SafeBasePath "${baseEndpoint}/fields" -UnsafeChildPath $Field
        }
        $propertyNames = Get-YTEntityField -Type 'IssueCustomField' -Depth 2
        $fields = Invoke-YTRestMethod -Session $session -Name $endpoint -Property $propertyNames

        if ($ValueOnly)
        {
            return $fields.value.name
        }

        return $fields
    }
}