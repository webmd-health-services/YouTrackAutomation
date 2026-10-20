
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
            [String] $WithSummary,

            [String] $WithDescription
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary -Description $WithDescription
    }
}

Describe 'Get-YTIssue' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'issue from parameters' {
        It 'supports issue ID' {
            $issue = GivenIssue 'supports issue ID'
            $result = Get-YTIssue -Session $script:session -IssueId $issue.id
            $result.id | Should -Be $issue.id
            $result.idReadable | Should -Be $issue.idReadable
            $result.summary | Should -Be 'supports issue ID'
        }

        It 'supports issue readable ID' {
            $issue = GivenIssue 'supports issue readable ID'
            $result = Get-YTIssue -Session $script:session -IssueId $issue.idReadable
            $result.id | Should -Be $issue.id
            $result.idReadable | Should -Be $issue.idReadable
        }

        It 'flattens custom fields onto the object' {
            $issue = GivenIssue 'flattens custom fields'
            $result = Get-YTIssue -Session $script:session -IssueId $issue.idReadable
            # State is a custom field; ConvertTo-YTObj flattens it onto the object.
            $result | Get-Member -Name 'State' | Should -Not -BeNullOrEmpty
            $result.PSObject.TypeNames | Should -Contain 'WHS.YTIssue.Object'
        }
    }

    Context 'issue from pipeline' {
        BeforeAll {
            $script:issue1 = GivenIssue 'issue from pipeline #1'
            $script:issue2 = GivenIssue 'issue from pipeline #2'
        }

        It 'accepts issue ids' {
            $issues = $script:issue1.id, $script:issue2.id | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }

        It 'accepts issue readable ids' {
            $issues = $script:issue1.idReadable, $script:issue2.idReadable | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
        }

        It 'accepts issue objects' {
            $issues = $script:issue1, $script:issue2 | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
        }

        It 'accepts objects with idReadable property' {
            $issues =
                $script:issue1, $script:issue2 |
                Select-Object -Property 'idReadable' |
                Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
        }
    }

    It 'writes an error for a nonexistent issue' {
        $result = Get-YTIssue -Session $script:session -IssueId 'FUBAR-999999' -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}
