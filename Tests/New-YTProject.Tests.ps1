
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:admin = Get-YTUser -Session $script:session -User 'admin'
}

Describe 'New-YTProject' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creates a project' {
        $shortName = "NP$(Get-Random -Minimum 1000 -Maximum 9999)"
        $name = "New-YTProject $([Guid]::NewGuid())"
        try
        {
            $project = New-YTProject -Session $script:session -Name $name -ShortName $shortName -LeaderID $script:admin.id
            $project | Should -Not -BeNullOrEmpty
            $project.shortName | Should -Be $shortName
            Get-YTProject -Session $script:session -ShortName $shortName | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Remove-YTProject -Session $script:session -Project $shortName -ErrorAction SilentlyContinue
        }
    }

    It 'creates a project with a description' {
        $shortName = "ND$(Get-Random -Minimum 1000 -Maximum 9999)"
        try
        {
            $project = New-YTProject -Session $script:session `
                                     -Name 'Described project' `
                                     -ShortName $shortName `
                                     -LeaderID $script:admin.id `
                                     -Description 'A described project.'
            $project | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Remove-YTProject -Session $script:session -Project $shortName -ErrorAction SilentlyContinue
        }
    }

    It 'does not create a project with -WhatIf' {
        $shortName = "NW$(Get-Random -Minimum 1000 -Maximum 9999)"
        New-YTProject -Session $script:session -Name 'whatif' -ShortName $shortName -LeaderID $script:admin.id -WhatIf
        Get-YTProject -Session $script:session -ShortName $shortName | Should -BeNullOrEmpty
    }
}
