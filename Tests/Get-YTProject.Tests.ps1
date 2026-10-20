
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
}

Describe 'Get-YTProject' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'returns all projects' {
        $all = Get-YTProject -Session $script:session
        $all | Should -Not -BeNullOrEmpty
        $all | Where-Object { $_.shortName -eq $script:project.shortName } | Should -Not -BeNullOrEmpty
    }

    It 'returns a project by short name' {
        $project = Get-YTProject -Session $script:session -ShortName $script:project.shortName
        $project | Should -Not -BeNullOrEmpty
        $project.shortName | Should -Be $script:project.shortName
    }

    It 'returns default fields' {
        $project = Get-YTProject -Session $script:session -ShortName $script:project.shortName
        $project.id | Should -Not -BeNullOrEmpty
        $project.name | Should -Not -BeNullOrEmpty
        $project.shortName | Should -Not -BeNullOrEmpty
    }

    It 'includes additional fields' {
        $project =
            Get-YTProject -Session $script:session -ShortName $script:project.shortName -AdditionalField 'description'
        $project | Get-Member -Name 'description' | Should -Not -BeNullOrEmpty
    }
}
