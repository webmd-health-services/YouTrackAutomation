
function Resolve-YTIssueCustomFields
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object] $Session,

        [Parameter(Mandatory)]
        [String] $IssueId
    )

    $issue = Get-YTIssue -Session $Session -IssueId $IssueId -AdditionalField 'customFields(id,projectCustomField(field(name)))'

    $fields = @{}

    foreach ($customField in $issue.customFields)
    {
        $fields[$customField.projectCustomField.field.name] = $customField.id
    }

    return $fields
}