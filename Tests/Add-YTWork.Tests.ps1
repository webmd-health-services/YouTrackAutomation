
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

Describe 'Add-YTWork' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'logs work against an issue' {
        $issue = GivenIssue
        Add-YTWork -Session $script:session -IssueID $issue.idReadable -Work '15m'
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'logs work with a comment' {
        $issue = GivenIssue
        Add-YTWork -Session $script:session -IssueID $issue.idReadable -Work '30m' -Comment 'did some work'
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'accepts issues from the pipeline' {
        $issue1 = GivenIssue
        $issue2 = GivenIssue
        $issue1, $issue2 | Add-YTWork -Session $script:session -Work '15m'
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'supports -WhatIf' {
        $issue = GivenIssue
        Add-YTWork -Session $script:session -IssueID $issue.idReadable -Work '15m' -WhatIf
        $headers = @{ 'Accept' = 'application/json' ; 'Authorization' = "Bearer $($script:session.ApiToken)" }
        $url = "$($script:session.Url)issues/$($issue.idReadable)/timeTracking/workItems?fields=duration(minutes)"
        $work = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $work | Should -BeNullOrEmpty
    }
}
