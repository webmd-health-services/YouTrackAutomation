
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
            [String] $WithSummary = [Guid]::NewGuid().ToString()
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary
    }
}

Describe 'Set-YTIssueState' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'sets the state of an issue' {
        $issue = GivenIssue
        $result = Set-YTIssueState -Session $script:session -IssueID $issue.idReadable -Value 'Fixed'
        $result.State | Should -Be 'Fixed'
    }

    It 'accepts an internal issue id' {
        $issue = GivenIssue
        $result = Set-YTIssueState -Session $script:session -IssueID $issue.id -Value 'Fixed'
        $result.State | Should -Be 'Fixed'
    }

    It 'writes an error for an invalid state' {
        $issue = GivenIssue
        Set-YTIssueState -Session $script:session -IssueID $issue.idReadable -Value 'notastate' `
                         -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
    }

    It 'does not change the state when -WhatIf is used' {
        $issue = GivenIssue
        $before = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).State
        Set-YTIssueState -Session $script:session -IssueID $issue.idReadable -Value 'Fixed' -WhatIf
        $after = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).State
        $after | Should -Be $before
    }
}
