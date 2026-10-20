
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject

    function GivenIssue
    {
        param(
            [Parameter(Mandatory, Position = 0)]
            [String] $WithSummary
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary
    }
}

Describe 'Get-YTIssueState' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets the state of an issue by readable ID' {
        $issue = GivenIssue 'gets state by readable id'
        $state = Get-YTIssueState -Session $script:session -Issue $issue.idReadable
        $state | Should -Not -BeNullOrEmpty
        $state.name | Should -Be 'State'
    }

    It 'gets the state of an issue by internal ID' {
        $issue = GivenIssue 'gets state by internal id'
        $state = Get-YTIssueState -Session $script:session -Issue $issue.id
        $state | Should -Not -BeNullOrEmpty
        $state.name | Should -Be 'State'
    }

    It 'accepts issue objects from the pipeline' {
        $issue1 = GivenIssue 'state pipeline #1'
        $issue2 = GivenIssue 'state pipeline #2'
        $states = $issue1, $issue2 | Get-YTIssueState -Session $script:session
        $states | Should -HaveCount 2
    }

    It 'accepts issue readable ids from the pipeline' {
        $issue1 = GivenIssue 'state readable pipeline #1'
        $issue2 = GivenIssue 'state readable pipeline #2'
        $states = $issue1.idReadable, $issue2.idReadable | Get-YTIssueState -Session $script:session
        $states | Should -HaveCount 2
    }

    It 'writes an error for a nonexistent issue' {
        $state = Get-YTIssueState -Session $script:session -Issue 'FUBAR-999999' -ErrorAction SilentlyContinue
        $state | Should -BeNullOrEmpty
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}
