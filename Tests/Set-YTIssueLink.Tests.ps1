
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

Describe 'Set-YTIssueLink' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'links an issue to another issue' {
        $source = GivenIssue
        $target = GivenIssue
        Set-YTIssueLink -Session $script:session `
                        -IssueID $source.idReadable `
                        -LinkType 'relates to' `
                        -TargetIssueId $target.idReadable
        $result = Get-YTIssue -Session $script:session -IssueId $source.idReadable
        $result.links.issues.idReadable | Should -Contain $target.idReadable
    }

    It 'rejects an invalid link type' {
        $source = GivenIssue
        $target = GivenIssue
        {
            Set-YTIssueLink -Session $script:session `
                            -IssueID $source.idReadable `
                            -LinkType 'not a link type' `
                            -TargetIssueId $target.idReadable
        } | Should -Throw
    }

    It 'accepts issues from the pipeline' {
        $source1 = GivenIssue
        $source2 = GivenIssue
        $target = GivenIssue
        $source1, $source2 |
            Set-YTIssueLink -Session $script:session -LinkType 'relates to' -TargetIssueId $target.idReadable
        $result1 = Get-YTIssue -Session $script:session -IssueId $source1.idReadable
        $result2 = Get-YTIssue -Session $script:session -IssueId $source2.idReadable
        $result1.links.issues.idReadable | Should -Contain $target.idReadable
        $result2.links.issues.idReadable | Should -Contain $target.idReadable
    }

    It 'does not create a link when -WhatIf is used' {
        $source = GivenIssue
        $target = GivenIssue
        Set-YTIssueLink -Session $script:session `
                        -IssueID $source.idReadable `
                        -LinkType 'relates to' `
                        -TargetIssueId $target.idReadable `
                        -WhatIf
        $result = Get-YTIssue -Session $script:session -IssueId $source.idReadable
        $result.links.issues.idReadable | Should -Not -Contain $target.idReadable
    }
}
