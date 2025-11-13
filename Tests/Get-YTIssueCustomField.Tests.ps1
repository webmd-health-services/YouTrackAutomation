
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
    $script:issue = Initialize-YTTIssue -Summary "Get-YTIssueCustomField test issue" -Project $script:project.id
    $script:issueID = $script:issue.idReadable
}

Describe 'Get-YTIssueCustomField' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets all an issues custom fields' {
        $fields = Get-YTIssueCustomField -Session $script:session -Issue $script:issueID
        $fields | Should -Not -BeNullOrEmpty
        $fields.Count | Should -BeGreaterThan 1
    }

    It 'gets a specific custom field and its value' {
        $field = Get-YTIssueCustomField -Session $script:session -Issue $script:issueID -Field 'State'
        $field | Should -Not -BeNullOrEmpty
        $field | Should -HaveCount 1
        $field.value.id | Should -Be '139-0'
    }

    It 'escapes issue' {
        $fields = Get-YTIssueCustomField -Session $script:session `
                                         -Issue "$($script:issueID)?fields=id" `
                                         -ErrorAction SilentlyContinue
        $fields | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'not found'
    }

    It 'escapes field' {
        $fields = Get-YTIssueCustomField -Session $script:session `
                                         -Issue $script:issueID `
                                         -Field '?fields=id' `
                                         -ErrorAction SilentlyContinue
        $fields | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'not found'
    }

    Context 'piped input' {
        It 'accepts issue id' {
            (Get-YTIssue -Session $script:session -Issue $script:issueID).id |
                Get-YTIssueCustomField -Session $script:session |
                Should -Not -BeNullOrEmpty
        }

        It 'accepts issue readable id' {
            $script:issueID | Get-YTIssueCustomField -Session $script:session | Should -Not -BeNullOrEmpty
        }

        It 'accepts object' {
            Get-YTIssue -Session $script:session -Issue $script:issueID |
                Get-YTIssueCustomField -Session $script:session |
                Should -Not -BeNullOrEmpty
        }

        It 'accepts object with id' {
            Get-YTIssue -Session $script:session -Issue $script:issueID |
                Select-Object -Property 'id' |
                Get-YTIssueCustomField -Session $script:session |
                Should -Not -BeNullOrEmpty
        }

        It 'accepts object with readable id' {
            Get-YTIssue -Session $script:session -Issue $script:issueID |
                Select-Object -Property 'idReadable' |
                Get-YTIssueCustomField -Session $script:session |
                Should -Not -BeNullOrEmpty
        }
    }

    It 'gets typed field' {
        $field =
            Get-YTIssueCustomField -Session $script:session `
                                   -Issue $script:issueID `
                                   -Field 'State' `
                                   -Type 'StateIssueCustomField'
        $field | ConvertTo-Json -Depth 50 | Write-Verbose
        $field | Should -Not -BeNullOrEmpty
        $field | Should -HaveCount 1
        # Specified the type for the value, so it should have that type's properties.
        $field.value | Should -Not -BeNullOrEmpty
        $field.value | Get-Member -Name 'localizedName' | Should -Not -BeNullOrEmpty
        # Returns base bundle element
        $field.value.bundle | Should -Not -BeNullOrEmpty
        $field.value.bundle | Get-Member -Name 'isUpdateable' | Should -Not -BeNullOrEmpty
    }
}