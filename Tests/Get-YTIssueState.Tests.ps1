
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
}

Describe 'Get-YTIssueState' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'StateIssueCustomField' {
        Context 'issue via parameter' {
            It 'gets state by issue readable ID' {
                $state = Get-YTIssueState -Session $session -Issue 'DEMO-1'
                $state | Should -Not -BeNullOrEmpty
                $state.value.name | Should -Be 'Fixed'
            }

            It 'gets state by issue ID' {
                $state = Get-YTIssueState -Session $session -Issue (Get-YTIssue -Session $script:session -Issue 'DEMO-1').id
                $state | Should -Not -BeNullOrEmpty
                $state.value.name | Should -Be 'Fixed'
            }
        }

        Context 'via pipeline' {
            BeforeEAch {
                $script:issues = 'DEMO-1','DEMO-2' | ForEach-Object { Get-YTIssue -Session $script:session -Issue $_ }
            }

            It 'gets state by issue object' {
                $states = $script:issues | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Fixed'
                $states[1].value.name | Should -Be 'Submitted'
            }

            It 'gets state by issue object with only an id property' {
                $states = $script:issues | Select-Object -Property 'id' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Fixed'
                $states[1].value.name | Should -Be 'Submitted'
            }

            It 'gets state by issue object with only an idReadable property' {
                $states = $script:issues | Select-Object -Property 'idReadable' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Fixed'
                $states[1].value.name | Should -Be 'Submitted'
            }

            It 'gets state by issue ids' {
                $states = $script:issues | Select-Object -ExpandProperty 'id' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Fixed'
                $states[1].value.name | Should -Be 'Submitted'
            }

            It 'gets state by issue readable ids' {
                $states =
                    $script:issues | Select-Object -ExpandProperty 'idReadable' | Get-YTIssueState -Session $session
                $states | Should -HaveCount 2
                $states[0].value.name | Should -Be 'Fixed'
                $states[1].value.name | Should -Be 'Submitted'
            }
        }
    }

    Context 'StateMachineIssueCustomField' {
        # No idea how to automate creating a state machine in YouTrack and don't have time to figure it out.
    }
}