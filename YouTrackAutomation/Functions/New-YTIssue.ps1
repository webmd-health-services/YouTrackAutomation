
function New-YTIssue
{
    <#
    .SYNOPSIS
    Creates a new issue in YouTrack.

    .DESCRIPTION
    The `New-YTIssue` function creates a new issue in YouTrack. To create an issue, you must provide the project's short
    name to the `Project` parameter, and the title of the issue to the `Summary` parameter. You can also provide an
    optional description to the `Description` parameter.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'New Issue'

    Demonstrates creating a new issue in the `DEMO` project with the summary `New Issue`.

    .EXAMPLE
    New-YTIssue -Session $session -Project 'DEMO' -Summary 'Write Docs' -Description 'Write YouTrackAutomation docs'

    Demonstrates creating a new issue in the `DEMO` project with the summary `Write Docs` and the description `Write
    YouTrackAutomation docs`.
    #>
    [CmdletBinding()]
    param(
        # The session object for a Youtrack Session. Create a new Session using `New-XWSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The project that the issue will be created in. This should be the short name of the project.
        [Parameter(Mandatory)]
        [String] $Project,

        # The summary of the issue.
        [Alias('Title')]
        [Parameter(Mandatory)]
        [String] $Summary,

        # The description of the issue.
        [String] $Description
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $issueFields = @{
        summary = $Summary
        project = @{
            id = (Get-YTProject -Session $Session -ProjectShortName $Project).id
        }
    }

    if ($Description) {
        $issueFields['description'] = $Description
    }

    $fields = 'id,idReadable,summary'

    Invoke-YTRestMethod -Session $Session -Name "issues?fields=$fields" -Body $issueFields -Method Post
}