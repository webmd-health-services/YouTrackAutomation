
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

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary -Description 'original'
    }
}

Describe 'Set-YTIssueDescription' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'replaces the description of an issue' {
        $issue = GivenIssue
        Set-YTIssueDescription -Session $script:session -Issue $issue.idReadable -Description 'updated description'
        $result = Get-YTIssue -Session $script:session -IssueId $issue.idReadable
        $result.description | Should -Be 'updated description'
    }

    It 'does not change the description when -WhatIf is used' {
        $issue = GivenIssue
        Set-YTIssueDescription -Session $script:session -Issue $issue.idReadable -Description 'should not apply' -WhatIf
        $result = Get-YTIssue -Session $script:session -IssueId $issue.idReadable
        $result.description | Should -Be 'original'
    }
}
