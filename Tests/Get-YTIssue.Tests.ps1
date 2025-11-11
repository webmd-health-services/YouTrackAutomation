Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTPRoject

    function GivenIssue
    {
        param(
            [Parameter(Mandatory, Position=0)]
            [String] $WithSummary,

            [String] $WithDescription,

            [String] $SubtaskOf
        )

        $newArgs = @{}
        if ($WithDescription)
        {
            $newArgs['Description'] = $WithDescription
        }

        if ($SubtaskOf)
        {
            $newArgs['Parent'] = $SubtaskOf
        }

        New-YTIssue -Session $script:session -ProjectID $script:project.id -Summary $WithSummary @newArgs
    }

    function WhenGettingIssue
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs = @{}
        )

        $script:result = Get-YTIssue -Session $session @WithArgs
    }

    function ThenIssueHasValue
    {
        [CmdletBinding()]
        param(
            [String] $Field,
            [String] $Value
        )

        $script:result.$Field | Should -Be $Value
    }

    function ThenIssueHasField
    {
        [CmdletBinding()]
        param(
            [String] $Field
        )

        $script:result.$Field | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-YTIssue' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'issue from parameters' {
        It 'supports issue ID' {
            WhenGettingIssue -WithArgs @{ Issue = '3-4' }
            ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-5'
            ThenIssueHasValue -Field 'id' -Value '3-4'
            ThenIssueHasValue -Field 'summary' -Value 'First steps for project administrators'
            # Make sure two level of properties returned
            $script:result.updater | Should -Not -BeNullOrEmpty
            $script:result.updater.id | Should -Not -BeNullOrEmpty
            $script:result.updater | Get-Member 'tags' | Should -BeNullOrEmpty
        }

        It 'supports issue readable ID' {
            WhenGettingIssue -WithArgs @{ Issue = 'DEMO-1' }
            ThenIssueHasValue -Field 'id' -Value '3-0'
            ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-1'
            ThenIssueHasValue -Field 'summary' -Value 'Launch YouTrack'
        }
    }

    Context 'issue from pipeline' {
        BeforeAll {
            $script:issue1 = Get-YTIssue -Session $script:session -Issue 'DEMO-2'
            $script:issue2 = Get-YTIssue -Session $script:session -Issue 'DEMO-1'
        }
        It 'accepts issue ids' {
            $issues = $script:issue1.id,$script:issue2.id | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }

        It 'accepts issue readable ids' {
            $issues = $script:issue1.idReadable,$script:issue2.idReadable | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }

        It 'accepts issue objects' {
            $issues = $script:issue1,$script:issue2 | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }

        It 'accepts objects with id property' {
            $issues =
                $script:issue1,$script:issue2 | Select-Object -Property 'id' | Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }

        It 'accepts objects with idReadable property' {
            $issues =
                $script:issue1,$script:issue2 |
                Select-Object -Property 'idReadable' |
                Get-YTIssue -Session $script:session
            $issues | Should -HaveCount 2
            $issues[0].id | Should -Be $script:issue1.id
            $issues[1].id | Should -Be $script:issue2.id
        }
    }

    It 'supports custom fields' {
        $fields = 'comments(id,author(name),text,created,updated)'
        WhenGettingIssue -WithArgs @{ Issue = 'DEMO-1'; Property = $fields }
        ThenIssueHasField -Field 'comments'
        $script:result | Get-Member -Name 'idReadable' | Should -BeNullOrEmpty
    }

    It 'escapes issue ID' {
        WhenGettingIssue -WithArgs @{ Issue = '?fields=id' } -ErrorAction SilentlyContinue
        $script:result | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'not found'
    }

    It 'gets all issues in a project' {
        # Make sure there are issues in other projects.
        $issue = New-YTIssue -Session $script:session -ProjectID $script:project.id -Summary 'At Least One'
        $allIssues = Get-YTIssue -Session $script:session
        $projIssues = Get-YTIssue -Session $script:session -Project 'DEMO'
        $projIssues.Count | Should -BeLessThan $allIssues.Count
        $projIssues | Where-Object 'id' -EQ $issue.id | Should -BeNullOrEmpty
    }

    It 'finds issue by summary' {
        $expectedIssue = GivenIssue ([Guid]::NewGuid())

        # It can take a few seconds for issue to be indexed, so retry for 10.
        $actualIssue = $null
        $timer = [Diagnostics.Stopwatch]::StartNew()
        do
        {
            $actualIssue = Get-YTIssue -Session $script:session -Summary $expectedIssue.summary
            if ($actualIssue)
            {
                break
            }

            Start-Sleep -Seconds 1
        }
        while ($timer.Elapsed.TotalSeconds -lt 10)

        $actualIssue | Should -Not -BeNullOrEmpty
        $actualIssue.id | Should -Be $expectedIssue.id
    }

    It 'finds subtasks' {
        $parent = GivenIssue "Parent 7"
        $subtask1 = GivenIssue "Subtask 1 of $($parent.idReadable)" -SubtaskOf $parent.id
        $subtask2 = GivenIssue "Subtask 2 of $($parent.idReadable)" -SubtaskOf $parent.id
        $issue = GivenIssue 'Issue 3'

        $issues = Get-YTIssue -Session $script:session -SubtaskOf $parent.idReadable
        $issues | Should -HaveCount 2
        $issues | Where-Object 'id' -EQ $subtask1.id | Should -Not -BeNullOrEmpty
        $issues | Where-Object 'id' -EQ $subtask2.id | Should -Not -BeNullOrEmpty
        $issues | Where-Object 'id' -EQ $issue.id | Should -BeNullOrEmpty
    }
}