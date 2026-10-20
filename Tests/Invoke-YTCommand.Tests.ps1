
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
}

Describe 'Invoke-YTCommand' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'runs a command against an issue' {
        $tag = "cmd-$([Guid]::NewGuid())"
        Add-YTTag -Session $script:session -Tag $tag | Out-Null
        $issue = Initialize-YTTIssue -Project $script:project.shortName -Summary 'invoke command'

        Invoke-YTCommand -Session $script:session -Query "tag $tag" -Issue $issue.idReadable

        $updated = Get-YTIssue -Session $script:session -IssueId $issue.idReadable
        $updated.tags.name | Should -Contain $tag
    }

    It 'accepts issues from the pipeline' {
        $tag = "cmd-$([Guid]::NewGuid())"
        Add-YTTag -Session $script:session -Tag $tag | Out-Null
        $issue1 = Initialize-YTTIssue -Project $script:project.shortName -Summary 'invoke command pipe 1'
        $issue2 = Initialize-YTTIssue -Project $script:project.shortName -Summary 'invoke command pipe 2'

        $issue1.idReadable, $issue2.idReadable | Invoke-YTCommand -Session $script:session -Query "tag $tag"

        (Get-YTIssue -Session $script:session -IssueId $issue1.idReadable).tags.name | Should -Contain $tag
        (Get-YTIssue -Session $script:session -IssueId $issue2.idReadable).tags.name | Should -Contain $tag
    }
}
