
function New-YTIssue
{
    <#
    .SYNOPSIS
    Creates a new issue in YouTrack.

    .DESCRIPTION
    The `New-YTIssue` function creates a new issue in YouTrack. Pass the project's short name, ID, or a project object
    where the issue should get created to the Project parameter, and the title of the issue to the `Summary` parameter.
    You can also provide an optional description to the `Description` parameter.

    You can set an issue's custom fields at creation time by passing the fields to set to the `CustomField` parameter.
    Each item must be a hashtable with the field information required by the API to set that field. Each field must at a
    minimum have the field name (or ID), the `$type`, and a value. Some fields require the value to be an object, others
    a text value.

    To set `SingleUserIssueCustomField` fields, the value should have an id or login property if using the user's id or
    login:

        @{ name = 'Assignee' ; '$type' = 'SingleUserIssueCustomField' ; value = @{ login = 'admin' } }

    To set `SingleEnumIssueCustomField` fields, the value should have a `name` property that is the value you want to
    set:

        @{ name = 'Type' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Task' } }

    To set `SimpleIssueCustomField` fields, the value is the value you want to set, not an object:

        @{ name = 'CustomText' ; '$type' = 'SimpleIssueCustomField' ; value = 'Field value' }

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue'

    Demonstrates creating a new issue in the `DEMO` project with the summary `New Issue`.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'Write Docs' -Description 'Write YouTrackAutomation docs'

    Demonstrates creating a new issue in the `DEMO` project with the summary `Write Docs` and the description `Write
    YouTrackAutomation docs`.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue' -CustomField @{ name = 'Assignee' ; '$type' = 'SingleUserIssueCustomField' ; value = @{ login = 'admin' } }

    Demonstrates how to create an issue and assign a value to a `SingleUserIssueCustomField` custom field using a user's
    login name. You can use the user's ID instead setting the `value` property to `@{ id = 'USER_ID' }`.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue' -CustomField @{ name = 'Type' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Task' } }

    Demonstrates how to create an issue and assign a value to a `SingleEnumIssueCustomField` custom field using the
    enumeration value. You can also use the enumeration's value by setting the `value` property to `@{ id =
    'ENUM_VALUE_ID' }`.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue' -CustomField @{ name = 'CustomText' ; '$type' = 'SimpleIssueCustomField' ; value = 'Field value' }

    Demonstrates how to create an issue and assign a value to a `SimpleIssueCustomField` custom field.
    #>
    [CmdletBinding()]
    param(
        # The session object for a Youtrack Session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The project ID where the issue should be created.
        [Parameter(Mandatory)]
        [String] $ProjectID,

        # The summary of the issue.
        [Parameter(Mandatory)]
        [Alias('Title')]
        [String] $Summary,

        # The description of the issue.
        [String] $Description,

        # Readable issue ID for the parent issue.
        [String] $Parent,

        # Any custom fields to set. Each custom field must be a hashtable with the magic properties required for each
        # field type. If any property is missing or invalid, you'll get cryptic errors back from YouTrack. It is best
        # to work on each field, one at a time, until you get its values correct. The best way to see how to structure
        # each field is to create an issue with the expected fields you want in the YouTrack UI while your browser's
        # developer tools are running. The YouTrack UI use the YouTrack API to do its work. Some fields can't be set
        # on issue creation and the API doesn't tell you that when it fails.
        #
        # If you get an error about incompatible-issue-custom-field-id, it usually means that field doesn't exist for
        # issues in that project.
        [hashtable[]] $CustomField
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $parentIssue = $null
    if ($Parent)
    {
        $parentIssue = Get-YTIssue -Session $Session -Issue $Parent -Property 'idReadable'
        if (-not $parentIssue)
        {
            $msg = "Failed to create issue ""${Summary}"" because parent issue ""${Parent}"" does not exist."
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
    }

    $issue = @{
        summary = $Summary
        project = @{
            id = $ProjectID
        }
    }

    if ($Description)
    {
        $issue['description'] = $Description
    }

    if ($CustomField)
    {
        $issue['customFields'] = $CustomField
    }

    $fields = Get-YTEntityField -Type 'Issue' -Depth $script:defaultIssueFieldDepth

    $issue = Invoke-YTRestMethod -Session $Session -Resource 'issues' -Property $fields -Body $issue -Method Post

    if (-not $Parent)
    {
        return $issue
    }

    $query = "subtask of: $($parentIssue.idReadable)"
    $issue | Invoke-YTCommand -Session $Session -Query $query | ConvertTo-Json -Depth 50 | Write-Verbose

    # Make sure to return an object that has the new relationship.
    $fields = Get-YTEntityField -Type 'Issue' -Depth $script:defaultIssueFieldDepth
    $fields = "$($fields -join ','),parent($((Get-YTEntityField -Type 'IssueLink' -Depth 2) -join ','))"
    Get-YTIssue -Session $Session -Issue $issue.idReadable -Property $fields
}