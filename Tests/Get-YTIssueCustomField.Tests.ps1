
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
            [String] $WithSummary
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary
    }
}

Describe 'Get-YTIssueCustomField' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets all custom fields for an issue' {
        $issue = GivenIssue 'gets all custom fields'
        $fields = Get-YTIssueCustomField -Session $script:session -Issue $issue.idReadable
        $fields | Should -Not -BeNullOrEmpty
        $fields | Where-Object 'name' -EQ 'State' | Should -Not -BeNullOrEmpty
    }

    It 'gets a specific field by name' {
        $issue = GivenIssue 'gets a specific field'
        $field = Get-YTIssueCustomField -Session $script:session -Issue $issue.idReadable -Field 'State'
        $field | Should -Not -BeNullOrEmpty
        $field.name | Should -Be 'State'
    }

    It 'returns a typed field when given the field type' {
        $issue = GivenIssue 'returns a typed field'
        $field =
            Get-YTIssueCustomField -Session $script:session `
                                   -Issue $issue.idReadable `
                                   -Field 'State' `
                                   -Type 'StateIssueCustomField'
        $field | Should -Not -BeNullOrEmpty
        $field.name | Should -Be 'State'
    }

    It 'accepts field objects from the pipeline' {
        $issue = GivenIssue 'accepts field objects'
        $fields =
            Get-YTIssueCustomField -Session $script:session -Issue $issue.idReadable |
            Get-YTIssueCustomField -Session $script:session -Issue $issue.idReadable
        $fields | Should -Not -BeNullOrEmpty
    }

    It 'writes an error for a nonexistent issue' {
        $result =
            Get-YTIssueCustomField -Session $script:session -Issue 'FUBAR-999999' -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error | Should -Not -BeNullOrEmpty
    }
}
