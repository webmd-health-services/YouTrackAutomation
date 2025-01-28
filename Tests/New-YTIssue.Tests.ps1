Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    Clear-Project -Wait

    New-YTProject -Session $script:session -Leader 'admin' -Name 'New-YTIssue' -ShortName 'NYTI' -ErrorAction Stop | Out-Null

    function WhenCreatingIssue
    {
        param(
            [String] $WithSummary,
            [String] $WithDescription,
            [String] $InProject
        )

        $splat = @{}

        if ($WithSummary)
        {
            $splat['Summary'] = $WithSummary
        }

        if ($WithDescription)
        {
            $splat['Description'] = $WithDescription
        }

        if ($InProject)
        {
            $splat['Project'] = $InProject
        }


        $script:result = New-YTIssue -Session $script:session @splat
    }

    function ThenIssue
    {
        [CmdletBinding()]
        param(
            [String] $Summary,
            [String] $Description,
            [String] $Project
        )

        $script:result.idReadable | Should -Not -BeNullOrEmpty
        $issue = Get-YTIssue -Session $script:session -IssueId $script:result.idReadable

        $issue.summary | Should -Be $Summary
        $issue.project.shortName | Should -Be $Project
        $issue.description | Should -Be $Description
        $issue.reporter.name | Should -Be 'admin'
    }
}

Describe 'New-YTIssue' {
    BeforeEach {
        $script:summary = $null
        $script:description = $null
        $script:project = $null
    }

    It 'should create a new issue' {
        WhenCreatingIssue -WithSummary 'First YTAutomation Issue' -WithDescription 'This is the first issue created by the YouTrackAutomation module.' -InProject 'NYTI'
        ThenIssue -Summary 'First YTAutomation Issue' -Description 'This is the first issue created by the YouTrackAutomation module.' -Project 'NYTI'
    }

    It 'should allow issues with the same summary and description' {
        WhenCreatingIssue -WithSummary 'same summary' -WithDescription 'same description' -InProject 'NYTI'
        ThenIssue -Summary 'same summary' -Description 'same description' -Project 'NYTI'
        $initialIssueId = $script:result.idReadable
        WhenCreatingIssue -WithSummary 'same summary' -WithDescription 'same description' -InProject 'NYTI'
        ThenIssue -Summary 'same summary' -Description 'same description' -Project 'NYTI'
        $script:result.idReadable | Should -Not -Be $initialIssueId
    }
}