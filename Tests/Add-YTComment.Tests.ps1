
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

    function ThenIssueHasComment
    {
        param(
            [String] $ForIssue,
            [String] $Text
        )

        $headers = @{ 'Accept' = 'application/json' ; 'Authorization' = "Bearer $($script:session.ApiToken)" }
        $url = "$($script:session.Url)issues/$($ForIssue)/comments?fields=text"
        $comments = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $comments.text | Should -Contain $Text
    }
}

Describe 'Add-YTComment' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'adds a comment to an issue' {
        $issue = GivenIssue
        Add-YTComment -Session $script:session -IssueID $issue.idReadable -Comment 'a comment'
        $Global:Error | Should -BeNullOrEmpty
        ThenIssueHasComment -ForIssue $issue.idReadable -Text 'a comment'
    }

    It 'accepts issues from the pipeline' {
        $issue1 = GivenIssue
        $issue2 = GivenIssue
        $issue1, $issue2 | Add-YTComment -Session $script:session -Comment 'piped comment'
        $Global:Error | Should -BeNullOrEmpty
        ThenIssueHasComment -ForIssue $issue1.idReadable -Text 'piped comment'
        ThenIssueHasComment -ForIssue $issue2.idReadable -Text 'piped comment'
    }

    It 'supports -WhatIf' {
        $issue = GivenIssue
        Add-YTComment -Session $script:session -IssueID $issue.idReadable -Comment 'whatif comment' -WhatIf
        $headers = @{ 'Accept' = 'application/json' ; 'Authorization' = "Bearer $($script:session.ApiToken)" }
        $url = "$($script:session.Url)issues/$($issue.idReadable)/comments?fields=text"
        $comments = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        $comments.text | Should -Not -Contain 'whatif comment'
    }
}
