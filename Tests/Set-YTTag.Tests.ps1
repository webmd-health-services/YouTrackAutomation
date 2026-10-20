
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
}

Describe 'Set-YTTag' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'attaches a tag to an issue' {
        $tagName = "set-$([Guid]::NewGuid())"
        $tag = Add-YTTag -Session $script:session -Tag $tagName
        $issue = Initialize-YTTIssue -Project $script:project.shortName -Summary 'set tag'

        $result = Set-YTTag -Session $script:session -IssueID $issue.idReadable -TagID $tag.id
        $result | Should -Not -BeNullOrEmpty

        (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).tags.name | Should -Contain $tagName
    }

    It 'accepts issues from the pipeline' {
        $tagName = "setp-$([Guid]::NewGuid())"
        $tag = Add-YTTag -Session $script:session -Tag $tagName
        $issue1 = Initialize-YTTIssue -Project $script:project.shortName -Summary 'set tag pipe 1'
        $issue2 = Initialize-YTTIssue -Project $script:project.shortName -Summary 'set tag pipe 2'

        $issue1.idReadable, $issue2.idReadable | Set-YTTag -Session $script:session -TagID $tag.id

        (Get-YTIssue -Session $script:session -IssueId $issue1.idReadable).tags.name | Should -Contain $tagName
        (Get-YTIssue -Session $script:session -IssueId $issue2.idReadable).tags.name | Should -Contain $tagName
    }

    It 'does not attach a tag with -WhatIf' {
        $tagName = "setw-$([Guid]::NewGuid())"
        $tag = Add-YTTag -Session $script:session -Tag $tagName
        $issue = Initialize-YTTIssue -Project $script:project.shortName -Summary 'set tag whatif'

        Set-YTTag -Session $script:session -IssueID $issue.idReadable -TagID $tag.id -WhatIf

        (Get-YTIssue -Session $script:session -IssueId $issue.idReadable).tags.name | Should -Not -Contain $tagName
    }
}
