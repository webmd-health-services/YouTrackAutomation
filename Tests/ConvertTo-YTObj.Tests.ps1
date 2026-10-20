
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)

    function NewIssueObject
    {
        return [pscustomobject]@{
            idReadable = 'DEMO-1'
            summary = 'An issue'
            customFields = @(
                [pscustomobject]@{ name = 'State' ; value = [pscustomobject]@{ name = 'Open' } }
                [pscustomobject]@{ name = 'Assignee' ; value = [pscustomobject]@{ name = 'admin' } }
                [pscustomobject]@{ name = 'Estimate' ; value = $null }
            )
        }
    }
}

Describe 'ConvertTo-YTObj' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'flattens named custom field values onto the object' {
        $result = NewIssueObject | ConvertTo-YTObj
        $result.State | Should -Be 'Open'
        $result.Assignee | Should -Be 'admin'
    }

    It 'sets a null custom field value to null' {
        $result = NewIssueObject | ConvertTo-YTObj
        $result.Estimate | Should -BeNullOrEmpty
    }

    It 'keeps the original customFields property' {
        $result = NewIssueObject | ConvertTo-YTObj
        $result.customFields | Should -Not -BeNullOrEmpty
    }

    It 'adds the WHS.YTIssue.Object type name' {
        $result = NewIssueObject | ConvertTo-YTObj
        $result.PSObject.TypeNames | Should -Contain 'WHS.YTIssue.Object'
    }

    It 'does not mutate the original object' {
        $issue = NewIssueObject
        $null = $issue | ConvertTo-YTObj
        $issue.PSObject.Properties.Name | Should -Not -Contain 'State'
    }
}
