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
            [String] $HasSummary,
            [String] $HasDescription,
            [String] $InProject,
            [String] $HasParent,
            [hashtable] $HasCustomFields
        )

        $script:result.idReadable | Should -Not -BeNullOrEmpty

        if ($HasSummary)
        {
            $script:result.summary | Should -Be $HasSummary
        }

        $script:result.project.id | Should -Be $script:project.id

        if ($InProject)
        {
            $script:result.project.shortName | Should -Be $InProject
        }

        if ($HasDescription)
        {
            $script:result.description | Should -Be $HasDescription
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

        if ($HasCustomFields)
        {
            foreach ($expectedFieldName in $HasCustomFields.Keys)
            {
                $expectedField = $script:result.customFields | Where-Object 'name' -eq $expectedFieldName
                $actualField = $script:result | Get-YTIssueCustomField -Session $script:session -Field $expectedFieldName -Type $expectedField.'$type'
                $actualField | Should -Not -BeNullOrEmpty
                $actualField.name | Should -Be $expectedFieldName
                if ($actualField.'$type' -eq 'SingleUserIssueCustomField')
                {
                    $actualField.value.login -eq 'admin'
                }
                else
                {
                    $actualField.value.name | Should -Be $HasCustomFields[$expectedFieldName]
                }
            }
        }
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
        ThenIssue -HasSummary 'First YTAutomation Issue' `
                  -HasDescription 'This is the first issue created by the YouTrackAutomation module.'
    }

    It 'should allow issues with the same summary and description' {
        WhenCreatingIssue -WithArgs @{ Summary = 'same summary' ; Description = 'same description' }
        ThenIssue -HasSummary 'same summary' -HasDescription 'same description'
        $initialIssueId = $script:result.idReadable
        WhenCreatingIssue -WithArgs @{ Summary = 'same summary' ; Description = 'same description' }
        ThenIssue -HasSummary 'same summary' `
                  -HasDescription 'same description' `
                  -InProject $script:project.shortName
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

    It 'sets a custom field' {
        $customField = @{ name = 'Priority' ; value = @{ name = 'Major' } ; '$type' = 'SingleEnumIssueCustomField' }

        WhenCreatingIssue -WithArgs @{ Summary = 'Adding custom fields.' ; CustomField = $customField }
        ThenIssue -HasSummary 'Adding custom fields.' `
                  -HasCustomFields @{ Priority = 'Major' }
    }

    It 'sets custom fields' {
        $customFields = @(
            @{ name = 'Priority' ; value = @{ name = 'Major' } ; '$type' = 'SingleEnumIssueCustomField' }
            @{ name = 'Assignee' ;  value = @{ login = 'admin' } ; '$type' = 'SingleUserIssueCustomField' }
        )

        WhenCreatingIssue -WithArgs @{ Summary = 'Adding custom fields.' ; CustomField = $customFields }
        ThenIssue -HasSummary 'Adding custom fields.' `
                  -HasCustomFields @{ Priority = 'Major' ; Assignee = 'admin' }
    }
}