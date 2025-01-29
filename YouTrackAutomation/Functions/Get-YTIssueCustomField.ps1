
function Get-YTIssueCustomField
{
    <#
    .SYNOPSIS
    Gets a custom field for an issue.

    .DESCRIPTION
    The `Get-YTIssueCustomField` function gets the specified field information from a YouTrack issue. Provide the
    issue's ID to the `IssueID` parameter. Provide the name of the custom field to the `CustomField` parameter. If the
    custom field is not available this function will throw an error.

    By default, this function will return an object containing the name of the custom field and its value. To just get
    the value of the field use the `Value` switch.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -IssueId 'DEMO-4' -CustomField 'Type'

    Demonstrates getting the issue type for issue 'DEMO-4'.

    .EXAMPLE
    Get-YTIssueCustomField -Session $session -IssueId 'DEMO-20' -CustomField 'State' -Value

    Demonstrates getting the state value for the issue 'DEMO-20'
    #>
    [CmdletBinding()]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID of the issue.
        [Parameter(Mandatory)]
        [String] $IssueId,

        # The name of the custom field to fetch.
        [Parameter(Mandatory)]
        [String] $CustomField,

        # Returns only the value of the custom field.
        [switch] $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $issueFields = Resolve-YTIssueCustomFields -Session $Session -IssueId $IssueId

    $endpoint = "issues/${IssueId}/customFields/$($issueFields[$customField])?fields=id,projectCustomField(id,field(id,name))," +
                'value(id,isResolved,localizedName,name)'
    $customFieldObject = Invoke-YTRestMethod -Session $session `
                                             -Name $endpoint
    if ($Value)
    {
        return $customFieldObject.value.name
    }

    return $customFieldObject
}