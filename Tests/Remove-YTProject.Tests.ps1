
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:admin = Get-YTUser -Session $script:session -User 'admin'

    function GivenProject
    {
        param(
            [Parameter(Mandatory)]
            [String] $ShortName
        )

        New-YTProject -Session $script:session -Name "Remove $ShortName" -ShortName $ShortName -LeaderID $script:admin.id |
            Out-Null
    }
}

Describe 'Remove-YTProject' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'removes a project by short name' {
        $shortName = "RP$(Get-Random -Minimum 1000 -Maximum 9999)"
        GivenProject -ShortName $shortName
        Remove-YTProject -Session $script:session -Project $shortName
        Get-YTProject -Session $script:session -ShortName $shortName | Should -BeNullOrEmpty
    }

    It 'accepts project objects from the pipeline' {
        $shortName = "RPP$(Get-Random -Minimum 100 -Maximum 999)"
        GivenProject -ShortName $shortName
        Get-YTProject -Session $script:session -ShortName $shortName | Remove-YTProject -Session $script:session
        Get-YTProject -Session $script:session -ShortName $shortName | Should -BeNullOrEmpty
    }

    It 'does not remove with -WhatIf' {
        $shortName = "RW$(Get-Random -Minimum 1000 -Maximum 9999)"
        GivenProject -ShortName $shortName
        try
        {
            Remove-YTProject -Session $script:session -Project $shortName -WhatIf
            Get-YTProject -Session $script:session -ShortName $shortName | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Remove-YTProject -Session $script:session -Project $shortName -ErrorAction SilentlyContinue
        }
    }
}
