
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTPRoject
    $script:nextId = (Get-YTIssue -Session $script:session -Project $script:project.shortName | Measure-Object).Count - 1
    $script:issue = $null

    function GivenIssue
    {
        param(
        )

        $script:issue = New-YTIssue -Session $script:session -ProjectID $script:project.id -Summary $script:nextId
        $script:issue | Write-Output
        $script:nextID += 1
    }

    function ThenState
    {
        param(
            [String] $ForIssue,
            [String] $Is
        )

        if (-not $ForIssue)
        {
            $ForIssue = $script:issue.idReadable
        }

        $state = Get-YTIssueState -Session $script:session -Issue $ForIssue
        $state | Should -Not -BeNullOrEmpty
        $state.value.name | Should -Be $Is
    }

    function WhenSettingState
    {
        [CmdletBinding()]
        param(
            [String] $ForIssue,
            [String] $To
        )

        if (-not $ForIssue)
        {
            $ForIssue = $script:issue.idReadable
        }

        Set-YTIssueState -Session $script:session -Issue $ForIssue -State $To
    }
}

Describe 'Set-YTIssueState' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'StateIssueCustomField' {
        It 'updates issue state using state name' {
            GivenIssue
            WhenSettingState -To 'Fixed'
            ThenState -Is 'Fixed'
        }

        It 'accepts issue ids' {
            $issue = GivenIssue
            WhenSettingState -ForIssue $issue.id -To 'Fixed'
            ThenState -ForIssue $issue.idReadable -Is 'Fixed'
        }

        It 'accepts issue readable ids' {
            $issue = GivenIssue
            WhenSettingState -ForIssue $issue.idReadable -To 'Fixed'
            ThenState -ForIssue $issue.idReadable -Is 'Fixed'
        }

        It 'updates issue state using state id' {
            GivenIssue
            $state = $script:issue | Get-YTIssueState -Session $Session
            $state | Should -Not -BeNullOrEmpty
            $statesBundle = $state.value.bundle | Get-YTBundle -Session $Session
            $statesBundle | Should -Not -BeNullOrEmpty
            $fixedState = $statesBundle.values | Where-Object 'name' -EQ 'Fixed'
            $fixedState | Should -Not -BeNullOrEmpty
            WhenSettingState -To $fixedState.id
            ThenState -Is 'Fixed'
        }

        It 'validates state' {
            WhenSettingState -To 'fajkdlfjksdafj' -ErrorAction SilentlyContinue
            $Global:Error | Should -Match 'possible next states'
        }

        Context 'pipeline' {
            BeforeEach {
                $script:issue1 = GivenIssue
                $script:issue2 = GivenIssue
            }

            It 'accepts issue objects' {
                $script:issue1,$script:issue2 | Set-YTIssueState -Session $script:session -State 'Fixed'
                ThenState -ForIssue $script:issue1.idReadable -Is 'Fixed'
                ThenState -ForIssue $script:issue2.idReadable -Is 'Fixed'
            }

            It 'accepts issue objects with id property' {
                $script:issue1,$script:issue2 |
                    Select-Object -Property 'id' |
                    Set-YTIssueState -Session $script:session -State 'Fixed'
                ThenState -ForIssue $script:issue1.idReadable -Is 'Fixed'
                ThenState -ForIssue $script:issue2.idReadable -Is 'Fixed'
            }

            It 'accepts issue objects with idReadable property' {
                $script:issue1,$script:issue2 |
                    Select-Object -Property 'idReadable' |
                    Set-YTIssueState -Session $script:session -State 'Fixed'
                ThenState -ForIssue $script:issue1.idReadable -Is 'Fixed'
                ThenState -ForIssue $script:issue2.idReadable -Is 'Fixed'
            }

            It 'accepts issue ids' {
                $script:issue1.id,$script:issue2.id | Set-YTIssueState -Session $script:session -State 'Fixed'
                ThenState -ForIssue $script:issue1.idReadable -Is 'Fixed'
                ThenState -ForIssue $script:issue2.idReadable -Is 'Fixed'
            }

            It 'accepts issue readable ids' {
                $script:issue1.idReadable,$script:issue2.idReadable |
                    Set-YTIssueState -Session $script:session -State 'Fixed'
                ThenState -ForIssue $script:issue1.idReadable -Is 'Fixed'
                ThenState -ForIssue $script:issue2.idReadable -Is 'Fixed'
            }
        }
    }

    Context 'StateMachineIssueCustomField' {
        # No idea how to automate creating a state machine in YouTrack and don't have time to figure it out.
    }
}