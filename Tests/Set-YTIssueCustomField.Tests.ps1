
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

Describe 'Set-YTIssueCustomField' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'sets a single-enum custom field' {
        $issue = GivenIssue
        $result =
            Set-YTIssueCustomField -Session $script:session `
                                   -IssueID $issue.idReadable `
                                   -CustomField 'Priority' `
                                   -Value 'Major'
        $result.Priority | Should -Be 'Major'
    }

    It 'writes an error for an invalid value' {
        $issue = GivenIssue
        Set-YTIssueCustomField -Session $script:session `
                               -IssueID $issue.idReadable `
                               -CustomField 'Priority' `
                               -Value 'notavalue' `
                               -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
    }

    It 'writes an error for an unknown field' {
        $issue = GivenIssue
        Set-YTIssueCustomField -Session $script:session `
                               -IssueID $issue.idReadable `
                               -CustomField 'NotAField' `
                               -Value 'x' `
                               -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
    }

    It 'accepts issues from the pipeline' {
        $issue1 = GivenIssue
        $issue2 = GivenIssue
        $results =
            $issue1, $issue2 |
            Set-YTIssueCustomField -Session $script:session -CustomField 'Priority' -Value 'Major'
        $results | Should -HaveCount 2
        $results[0].Priority | Should -Be 'Major'
        $results[1].Priority | Should -Be 'Major'
    }

    It 'does not change the field when -WhatIf is used' {
        $issue = GivenIssue
        $before = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).Priority
        Set-YTIssueCustomField -Session $script:session `
                               -IssueID $issue.idReadable `
                               -CustomField 'Priority' `
                               -Value 'Major' `
                               -WhatIf
        $after = (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).Priority
        $after | Should -Be $before
    }
}
