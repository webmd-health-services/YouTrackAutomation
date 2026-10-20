
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)

    $script:session = [pscustomobject]@{ Url = 'http://localhost:8080/api/' ; ApiToken = 'x' }
}

Describe 'Resolve-YTProjectId' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'returns the id of a project object' {
        $project = [pscustomobject]@{ id = '0-5' ; shortName = 'DEMO' }
        Resolve-YTProjectId -Session $script:session -Project $project | Should -Be '0-5'
    }

    It 'returns an ID string unchanged' {
        Resolve-YTProjectId -Session $script:session -Project '0-7' | Should -Be '0-7'
    }

    It 'resolves a short name via Get-YTProject' {
        Mock -ModuleName 'YouTrackAutomation' -CommandName 'Get-YTProject' -MockWith {
            [pscustomobject]@{ id = '0-9' ; shortName = 'DEMO' }
        }
        Resolve-YTProjectId -Session $script:session -Project 'DEMO' | Should -Be '0-9'
        Should -Invoke -ModuleName 'YouTrackAutomation' -CommandName 'Get-YTProject' -Times 1 -Exactly
    }
}
