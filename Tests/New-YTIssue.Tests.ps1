
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
}

Describe 'New-YTIssue' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creates an issue' {
        $result = New-YTIssue -Session $script:session -Project $script:project.shortName -Summary 'creates an issue'
        $result | Should -Not -BeNullOrEmpty
        $result.idReadable | Should -Not -BeNullOrEmpty
        $result.summary | Should -Be 'creates an issue'
    }

    It 'creates an issue with a description' {
        $result =
            New-YTIssue -Session $script:session `
                        -Project $script:project.shortName `
                        -Summary 'with description' `
                        -Description 'a description'
        $result.description | Should -Be 'a description'
    }

    It 'accepts a project object' {
        $result = New-YTIssue -Session $script:session -Project $script:project -Summary 'from project object'
        $result.idReadable | Should -Not -BeNullOrEmpty
    }

    It 'sets a custom field at creation time' {
        $customField = @{ name = 'Priority' ; '$type' = 'SingleEnumIssueCustomField' ; value = @{ name = 'Major' } }
        $result =
            New-YTIssue -Session $script:session `
                        -Project $script:project.shortName `
                        -Summary 'with custom field' `
                        -CustomField $customField
        $issue = Get-YTIssue -Session $script:session -IssueId $result.idReadable
        $issue.Priority | Should -Be 'Major'
    }

    It 'does not create an issue when -WhatIf is used' {
        $result =
            New-YTIssue -Session $script:session -Project $script:project.shortName -Summary 'whatif' -WhatIf
        $result | Should -BeNullOrEmpty
    }
}
