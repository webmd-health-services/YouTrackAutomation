Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:projectShortName = 'NYTI'

    $script:project = Get-YTProject -Session $script:session -ShortName $script:projectShortName -ErrorAction Ignore
    if (-not $script:project)
    {
        $script:project = New-YTProject -Session $script:session `
                                        -Leader 'admin' `
                                        -Name 'New-YTIssue' `
                                        -ShortName $script:projectShortName
    }


    function WhenCreatingIssue
    {
        param(
            [hashtable] $WithArgs = @{}
        )

        $WithArgs['ProjectID'] = $script:project.id

        $script:result = New-YTIssue -Session $script:session @WithArgs
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
        $script:result.summary | Should -Be $Summary
        $script:result.project.id | Should -Be $script:project.id
        $script:result.description | Should -Be $Description
        # Make sure two levels of objects are returned
        $script:result.reporter.login | Should -Be 'admin'
    }
}

Describe 'New-YTIssue' {
    It 'should create a new issue' {
        WhenCreatingIssue -WithArgs @{
            Summary = 'First YTAutomation Issue'
            Description = 'This is the first issue created by the YouTrackAutomation module.'
        }
        ThenIssue -Summary 'First YTAutomation Issue' `
                  -Description 'This is the first issue created by the YouTrackAutomation module.'
    }

    It 'should allow issues with the same summary and description' {
        WhenCreatingIssue -WithArgs @{ Summary = 'same summary' ; Description = 'same description' }
        ThenIssue -Summary 'same summary' -Description 'same description' -Project 'NYTI'
        $initialIssueId = $script:result.idReadable
        WhenCreatingIssue -WithArgs @{ Summary = 'same summary' ; Description = 'same description' }
        ThenIssue -Summary 'same summary' -Description 'same description' -Project 'NYTI'
        $script:result.idReadable | Should -Not -Be $initialIssueId
    }
}