Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    try
    {
        New-YTProject -Session $script:session -Leader 'admin' -Name 'New-YTIssue' -ShortName 'NYTI' -ErrorAction Stop | Out-Null
    }
    catch {}

    function GivenDescription
    {
        [CmdletBinding()]
        param(
            [String] $Description
        )

        $script:description = $Description
    }

    function GivenSummary
    {
        [CmdletBinding()]
        param(
            [String] $Summary
        )

        $script:summary = $Summary
    }

    function GivenProjectShortName
    {
        [CmdletBinding()]
        param(
            [String] $ShortName
        )

        $script:project = $ShortName
    }

    function GivenProject
    {
        [CmdletBinding()]
        param(
            [String] $Name,
            [String] $ShortName
        )

        New-YTProject -Session $script:session -Leader 'admin' @PSBoundParameters | Out-Null
    }

    function WhenCreatingIssue
    {
        $splat = @{}
        if ($Description) {
            $splat['Description'] = $script:Description
        }


        $script:result = New-YTIssue -Session $script:session -Project $script:project -Summary $script:summary @splat
    }

    function ThenIssue
    {
        [CmdletBinding()]
        param(
        )

        $script:result.idReadable | Should -Not -BeNullOrEmpty
        $issue = Get-YTIssue -Session $script:session -IssueId $script:result.idReadable
        $issue.summary | Should -Be $script:summary
        $issue.project.shortName | Should -Be $script:project
        $issue.description | Should -Be $script:description
        $issue.reporter.name | Should -Be 'admin'
    }
}

Describe 'New-YTIssue' {
    BeforeEach {
        $script:summary = $null
        $script:description = $null
        $script:project = $null
    }

    It 'should create a new issue' {
        GivenSummary 'First YTAutomation Issue'
        GivenDescription 'This is the first issue created by the YouTrackAutomation module.'
        GivenProjectShortName 'NYTI'
        WhenCreatingIssue
        ThenIssue
    }

    It 'should allow issues with the same summary and description' {
        GivenSummary 'same summary'
        GivenDescription 'same description'
        GivenProjectShortName 'NYTI'
        WhenCreatingIssue
        ThenIssue
        $issueId = $script:result.idReadable
        WhenCreatingIssue
        ThenIssue
        $script:result.idReadable | Should -Not -Be $issueId
    }
}