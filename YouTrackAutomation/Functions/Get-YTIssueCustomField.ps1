
function Get-YTIssueCustomField
{
    <#
    .SYNOPSIS
    Gets an issue's custom fields.

    .DESCRIPTION
    The `Get-YTIssueCustomField` function gets an issue's custom fields. Pass the issue's ID or readable ID to the
    `Issue` parameter. All the custom fields for that issue are returned along with their ID and name (value).

    To get a specific custom field, pass its name or ID to the `Field` parameter. To get a typed object back, (i.e. all
    the field's properties exist), pass the field's type to the `Type` parameter.

    You can also pipe custom field objects to `Get-YTIssueCustomField` to get full fields back. So you can do things
    like:

        $issue = Get-YTIssue -Session $session -Issue 'DEMO-4'
        $issue.customFields | Get-YTIssueCustomField -Session $session -Issue $issue.idReadable

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-4'

    Demonstrates how to get all an issue's custom fields by passing the issue's ID or readable ID to the `Issue`
    parameter.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-20' -Field 'State'

    Demonstrates how to get a specific field by passings its ID or name to the `Field` parameter.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -Issue 'DEMO-2' -Field 'State' -Type 'StateIssueCustomField'

    Demonstrates how to return an object with the properties of the specific field type you want by passing the field's
    type name to the `Type` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='AllFields')]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or readable ID of the issue.
        [Parameter(Mandatory)]
        [String] $Issue,

        # The name or ID of the specific custom field to get. Default is to return all the issue's custom fields. You
        # can pipe field objects, IDs, or names as well. When you pipe objects, `Get-YTIssueCustomField` detects the
        # field's types and returns all object properties.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName='SpecificField')]
        [Alias('id')]
        [Alias('name')]
        [String] $Field,

        # The field's type, e.g. StateIssueCustomField, SingleEnumIssueCustomField, etc. Controls what properties exist
        # on the returned object. Required in order to return the field's value.
        [Parameter(ParameterSetName='SpecificField', ValueFromPipelineByPropertyName)]
        [Alias('$type')]
        [String] $Type
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $baseResource = Protect-YTResourcePath -SafeBasePath 'issues' -UnsafeChildPath $Issue
        $resource = "${baseResource}/customFields"
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

        # User wants custom value type, so all the sub-types are known and we should go one level deeper to get all the
        # info.
        if ($isTyped)
        {
            $propertyNames = & {
                $propertyNames | Where-Object { -not $_.StartsWith('value(') } | Write-Output
                $depth = 3
                if ($Type -eq 'SingleUserIssueCustomField')
                {
                    # If we go one more level, we return tags and saved queries, which is... a lot.
                    $depth = 2
                }

                Get-YTEntityField -Type $Type -Depth $depth | Where-Object { $_.StartsWith('value(') }
            }
        }

        return Invoke-YTRestMethod -Session $session -Resource $resource -Property $propertyNames
    }
}