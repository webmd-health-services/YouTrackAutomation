Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function WhenGettingIssue
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $IssueId,
            [String] $AdditionalField
        )

        $script:result = Get-YTIssue -Session $session @PSBoundParameters
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
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    }

    It 'should return an issue using the ''jira id''' {
        WhenGettingIssue -IssueId '3-4'
        ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-5'
        ThenIssueHasValue -Field 'id' -Value '3-4'
        ThenIssueHasValue -Field 'summary' -Value 'First steps for project administrators'
    }

    It 'should return an issue using the ''issue key''' {
        WhenGettingIssue -IssueId 'DEMO-1'
        ThenIssueHasValue -Field 'id' -Value '3-0'
        ThenIssueHasValue -Field 'idReadable' -Value 'DEMO-1'
        ThenIssueHasValue -Field 'summary' -Value 'Launch YouTrack'
    }

    It 'should support additional fields' {
        $additionalFields = 'comments(id,author(name),text,created,updated)'
        WhenGettingIssue -IssueId 'DEMO-1' -AdditionalField $additionalFields
        ThenIssueHasField -Field 'comments'
    }
}