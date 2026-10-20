
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

Describe 'Get-YTBundle' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets a bundle by ID and type' {
        $issue = GivenIssue 'get bundle by id and type'
        $state = Get-YTIssueState -Session $script:session -Issue $issue.idReadable
        $bundle = $state.value.bundle
        $bundle | Should -Not -BeNullOrEmpty

        $result = Get-YTBundle -Session $script:session -ID $bundle.id -Type $bundle.'$type'
        $result | Should -Not -BeNullOrEmpty
        $result.values | Should -Not -BeNullOrEmpty
    }

    It 'accepts a bundle from the pipeline' {
        $issue = GivenIssue 'get bundle from pipeline'
        $state = Get-YTIssueState -Session $script:session -Issue $issue.idReadable
        $result = $state.value.bundle | Get-YTBundle -Session $script:session
        $result | Should -Not -BeNullOrEmpty
        $result.values | Should -Not -BeNullOrEmpty
    }
}
