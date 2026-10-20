
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject

    # The display name of the user to assign to. 'admin' is the default YouTrack administrator.
    $script:assignee = 'admin'

    function GivenIssue
    {
        param(
            [String] $WithSummary = [Guid]::NewGuid().ToString()
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary
    }
}

Describe 'Set-YTIssueAssignee' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'sets the assignee of an issue' {
        $issue = GivenIssue
        $result = Set-YTIssueAssignee -Session $script:session -IssueID $issue.idReadable -Assignee $script:assignee
        $result | Should -Not -BeNullOrEmpty
        $result.Assignee | Should -Not -BeNullOrEmpty
    }

    It 'writes an error for an invalid assignee' {
        $issue = GivenIssue
        Set-YTIssueAssignee -Session $script:session `
                            -IssueID $issue.idReadable `
                            -Assignee 'Not A User' `
                            -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
    }

    It 'accepts issues from the pipeline' {
        $issue1 = GivenIssue
        $issue2 = GivenIssue
        $results = $issue1, $issue2 | Set-YTIssueAssignee -Session $script:session -Assignee $script:assignee
        $results | Should -HaveCount 2
    }

    It 'does not change the assignee when -WhatIf is used' {
        $issue = GivenIssue
        $before = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).Assignee
        Set-YTIssueAssignee -Session $script:session -IssueID $issue.idReadable -Assignee $script:assignee -WhatIf
        $after = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).Assignee
        $after | Should -Be $before
    }
}
