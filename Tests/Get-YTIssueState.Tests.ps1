
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
    $script:issue = Initialize-YTTIssue -Summary 'Get-YTIssueState Issue' -Project $script:project.shortName
    $script:issueID = $script:issue.idReadable
}

Describe 'Get-YTIssueState' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'StateIssueCustomField' {
        Context 'issue via parameter' {
            It 'gets state by issue readable ID' {
                $state = Get-YTIssueState -Session $session -Issue $script:issueID
                $state | Should -Not -BeNullOrEmpty
                $state.value.name | Should -Be 'Submitted'
            }

            It 'gets state by issue ID' {
                $state = Get-YTIssueState -Session $session -Issue $script:issue.id
                $state | Should -Not -BeNullOrEmpty
                $state.value.name | Should -Be 'Submitted'
            }
        }

        Context 'via pipeline' {
            BeforeEach {
                $script:issue2 =
                    Initialize-YTTIssue -Summary 'Get-YTIssueState Issue 2' -Project $script:project.shortName
                # Make sure second issue is in a different state than the first.
                Set-YTIssueState -Session $script:session -Issue $script:issue2.idReadable -State 'Fixed'
                $script:issue2 = Get-YTIssue -Session $script:session -Issue $script:issue2.idReadable
                $script:issues = $script:issue,$script:issue2
            }

            It 'gets state by issue object' {
                $states = $script:issues | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Submitted'
                $states[1].value.name | Should -Be 'Fixed'
            }

            It 'gets state by issue object with only an id property' {
                $states = $script:issues | Select-Object -Property 'id' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Submitted'
                $states[1].value.name | Should -Be 'Fixed'
            }

            It 'gets state by issue object with only an idReadable property' {
                $states = $script:issues | Select-Object -Property 'idReadable' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Submitted'
                $states[1].value.name | Should -Be 'Fixed'
            }

            It 'gets state by issue ids' {
                $states = $script:issues | Select-Object -ExpandProperty 'id' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Submitted'
                $states[1].value.name | Should -Be 'Fixed'
            }

            It 'gets state by issue readable ids' {
                $states =
                    $script:issues | Select-Object -ExpandProperty 'idReadable' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Submitted'
                $states[1].value.name | Should -Be 'Fixed'
            }
        }
    }

    Context 'StateMachineIssueCustomField' {
        # No idea how to automate creating a state machine in YouTrack and don't have time to figure it out.
    }
}