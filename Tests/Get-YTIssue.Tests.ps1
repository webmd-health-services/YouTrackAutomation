Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession

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

    It 'supports issue ID' {
        WhenGettingIssue -WithArgs @{ Issue = '3-4' }
        ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-5'
        ThenIssueHasValue -Field 'id' -Value '3-4'
        ThenIssueHasValue -Field 'summary' -Value 'First steps for project administrators'
        # Make sure two level of properties returned
        $script:result.updater | Should -Not -BeNullOrEmpty
        $script:result.updater.id | Should -Not -BeNullOrEmpty
        $script:result.updater.tags | Get-Member 'id' | Should -BeNullOrEmpty
    }

    It 'supports issue readable ID' {
        WhenGettingIssue -WithArgs @{ Issue = 'DEMO-1' }
        ThenIssueHasValue -Field 'id' -Value '3-0'
        ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-1'
        ThenIssueHasValue -Field 'summary' -Value 'Launch YouTrack'
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
}