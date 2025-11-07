Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:projectShortName = 'NYTI'

    $script:project = Get-YTProject -Session $script:session -Project $script:projectShortName -ErrorAction Ignore
    if (-not $script:project)
    {
        $script:project = New-YTProject -Session $script:session `
                                        -Leader 'admin' `
                                        -Name 'New-YTIssue' `
                                        -ShortName $script:projectShortName
    }

    function GivenIssue
    {
        param(
            [String] $Summary
        )

        New-YTIssue -Session $script:session -Summary $Summary -ProjectID $script:project.id
    }

    function WhenCreatingIssue
    {
        [CmdletBinding()]
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
            [String] $Project,
            [String] $HasParent
        )

        $script:result.idReadable | Should -Not -BeNullOrEmpty

        if ($Summary)
        {
            $script:result.summary | Should -Be $Summary
        }

        $script:result.project.id | Should -Be $script:project.id

        if ($Description)
        {
            $script:result.description | Should -Be $Description
        }

        if ($HasParent)
        {
            $script:result.parent | Should -Not -BeNullOrEmpty
            $script:result.parent.issues | Should -Not -BeNullOrEmpty
            $script:result.parent.issues.id | Should -Be $HasParent
        }

        # Make sure two levels of objects are returned
        $script:result.reporter | Get-Member 'login' | Should -Not -BeNullOrEmpty
        $script:result.reporter.login | Should -Be 'admin'
    }
}

Describe 'New-YTIssue' {
    BeforeEach {
        $Global:Error.Clear()
    }

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

    It 'assigns new issue to parent' {
        $parent = GivenIssue 'Parent Issue'
        $parent | Should -Not -BeNullOrEmpty
        WhenCreatingIssue -WithArgs @{ Summary = 'Child Issue' ; Parent = $parent.id }
        ThenIssue -HasParent $parent.id
    }

    It 'validates parent issue id' {
        WhenCreatingIssue -WithArgs @{ Summary = 'Missing Parent'; Parent = 'fubarsnafu' } -ErrorAction SilentlyContinue
        $script:result | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'not found|does not exist'
    }
}