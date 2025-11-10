
function Get-YTIssue
{
    <#
    .SYNOPSIS
    Gets issues from YouTrack.

    .DESCRIPTION
    The `Get-YTIssue` function gets issue from YouTrack. By default all issues are returned. To get a specific issue,
    pass its ID or its readable ID to the `Issue` parameter.

    By default all issue fields and fields for those fields are returned. Use the `Property` parameter to customize what
    fields to return and what fields on nested objects to return. Use the `Get-YTEntityField` function to get a full
    field list for an object by its type, with the option to get a field list for nested fields up to five levels deep.

    You can search for issues that belong to a specific project, contain text in their summary, or are subtasks of
    another issue using the `Project`, `Summary`, and `SubtaskOf` parameters, respectively. The values of these
    parameters should be the same as you'd use to search in the YouTrack UI using the `project:`, `summary`, and
    `subtask of:` attribute search clauses. See YouTrack's
    [Search](https://www.jetbrains.com/help/youtrack/server/search-for-issues.html) documenation for more information
    for how to search YouTrack.

    .LINK
    https://www.jetbrains.com/help/youtrack/server/search-for-issues.html

    .EXAMPLE
    Get-YTIssue -Session $session -Issue 'DEMO-1'

    Demonstrates fetching an issue based on the issue key. This will return the default fields for the `DEMO-1` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -Issue '3-4'

    Demonstrates fetching an issue based on the issue id. This will return the default fields for the `DEMO-5` issue.

    .EXAMPLE
    Get-YTIssue -Session $session -Issue 'DEMO-1' -Property 'comments(id,author(name),text)'

    Demonstrates fetching an issue based on the issue key and including additional fields. This will return the default
    fields for the `DEMO-1` issue, as well as the comments for the issue along with the comment id, comment author, and
    comment text.

    .EXAMPLE
    Get-YTIssue -Session $session -Project 'MYPROJ'

    Demonstrates how to get all the issues in a specific project by passing the project short name to the `Project`
    parameter. See https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#project for more
    information.

    .EXAMPLE
    Get-YTIssue -Session $session -Summary 'some search text'

    Demonstrates how to get all issues whose summaries match a search query.See
    https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#summary for more information.

    .EXAMPLE
    Get-YTIssue -Session $session -SubtaskOf DEMO-2

    Demonstrates how to get all issues that are subtasks of a parent issue by passing the parent issue's readable ID to
    the `SubtaskOf` parameter. See
    https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#subtask-of for more information.
    #>
    [CmdletBinding(DefaultParameterSetName='Query')]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID (e.g. `3-4`) or readable ID (e.g., `DEMO-3`) of the issue to get. Default is to get all issues.
        [Parameter(Mandatory, ParameterSetName='SpecificIssue')]
        [String] $Issue,

        # Returns issues in project that match this search query. Sent as the value for the `project:` search clause.
        # See https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#project for more
        # information.
        [Parameter(ParameterSetName='Query')]
        [String] $Project,

        # Gets all the issues matching the given summary. Sent as the value for the `summary:` search clause. See
        # https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#summary for more
        # information.
        [Parameter(ParameterSetName='Query')]
        [string] $Summary,

        # Gets all the issues that are a subtask of the given value. Sent as the value for the `subtask of:` search
        # clause. See https://www.jetbrains.com/help/youtrack/server/search-and-command-attributes.html#subtask-of for
        # more information.
        [Parameter(ParameterSetName='Query')]
        [String] $SubtaskOf,

        # Fields to include in the response. This should be a comma-separated list of field names.
        [String[]] $Property
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not $Property)
    {
        $Property = Get-YTEntityField -Type 'Issue' -Depth $script:defaultIssueFieldDepth
    }

    $endpoint = 'issues'
    if ($Issue)
    {
        $endpoint = Protect-YTPath -SafeBasePath $endpoint -UnsafeChildPath $Issue
    }

    $queryParams = @{}
    if ($PSCmdlet.ParameterSetName -eq 'Query')
    {
        $queryParts = & {

            if ($Project)
            {
                "project:${Project}" | Write-Output
            }

            if ($Summary)
            {
                "summary:${Summary}" | Write-Output
            }

            if( $SubtaskOf)
            {
                "subtask of:${SubtaskOf}"
            }
        }

        if ($queryParts)
        {
            $queryParams['query'] = $queryParts -join ' '
        }
    }

    Invoke-YTRestMethod -Session $Session -Name $endpoint -Property $Property -QueryParameter $queryParams
}