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
            $issue = GivenIssue -WithSummary 'supports issue ID'
            WhenGettingIssue -WithArgs @{ Issue = $issue.id }
            ThenIssueHasValue -Field 'idReadable' -Value $issue.idReadable
            ThenIssueHasValue -Field 'id' -Value $issue.id
            ThenIssueHasValue -Field 'summary' -Value $issue.summary
            # Make sure two level of properties returned
            $script:result.updater | Should -Not -BeNullOrEmpty
            $script:result.updater.id | Should -Not -BeNullOrEmpty
            $script:result.updater | Get-Member 'tags' | Should -BeNullOrEmpty
        }

        It 'supports issue readable ID' {
            $issue = GivenIssue -WithSummary 'supports issue readable ID'
            WhenGettingIssue -WithArgs @{ Issue = $issue.idReadable }
            ThenIssueHasValue -Field 'id' -Value $issue.id
            ThenIssueHasValue -Field 'idReadable' -Value $issue.idReadable
            ThenIssueHasValue -Field 'summary' -Value $issue.summary
        }
    }

    Context 'issue from pipeline' {
        BeforeAll {
            $script:issue1 = GivenIssue -WithSummary 'issue from pipeline #1'
            $script:issue2 = GivenIssue -WithSummary 'issue from pipeline #2'
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
        $issue = GivenIssue -WithSummary 'supports custom fields'
        $fields = 'summary'
        WhenGettingIssue -WithArgs @{ Issue = $issue.idReadable; Property = $fields }
        ThenIssueHasField -Field 'summary'
        $script:result | Get-Member -Name 'idReadable' | Should -BeNullOrEmpty
    }

    It 'escapes issue ID' {
        WhenGettingIssue -WithArgs @{ Issue = '?fields=id' } -ErrorAction SilentlyContinue
        $script:result | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'not found'
    }

    It 'gets all issues in a project' {
        # Make sure there are issues in other projects.
        $otherProject = Initialize-YTTProject -ShortName 'GTYI2'
        $otherIssue = Initialize-YTTIssue -Project $otherProject.shortName -Summary 'At Least One'
        $allIssues = Get-YTIssue -Session $script:session
        $projIssues = Get-YTIssue -Session $script:session -Project $script:project.shortName
        $projIssues | Where-Object { $_.project.id -ne $script:project.id } | Should -BeNullOrEmpty
        $projIssues.Count | Should -BeLessThan $allIssues.Count
        $projIssues | Where-Object 'id' -EQ $otherIssue.id | Should -BeNullOrEmpty
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