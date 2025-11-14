
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = $null
    $script:nextId = 0

    function WhenDeletingProject
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [Object] $WithNameOrID,

            [hashtable] $WithArgs = @{}
        )

        Remove-YTProject -Session $script:session -Project $WithNameOrID @WithArgs
    }

    function ThenProject
    {
        param(
            [switch] $Not,

            [switch] $Exists
        )

        $project = Get-YTProject -Session $script:session -Project $script:project.id -ErrorAction Ignore
        if ($Not)
        {
            $null -eq $project -or $project.name.Contains('deletion') | Should -BeTrue
        }
        else
        {
            $project | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Remove-YTProject' {
    BeforeEach {
        # Sometimes projects don't get deleted. So we can't hard-code project info and need to generate names
        # dynamically.
        $projects = Get-YTProject -Session $script:session | Where-Object 'shortName' -Like 'RYTP*'

        $script:nextId += 1
        while($projects | Where-Object 'shortName' -EQ "RYTP${script:nextId}")
        {
            $script:nextId += 1
        }

        $shortName = "RYTP${script:nextId}"
        $name = "Remove-YTProject ${script:nextId}"

        WRite-Verbose "[${shortName}]  ${name}"

        $script:project = New-YTProject -Session $script:session -Name $name -ShortName $shortName -Leader 'admin'

        $Global:Error.Clear()
    }

    AfterEach {
        # Delete any projects that weren't deleted.
        if (Get-YTProject -Session $script:session -Project $script:project.shortName -ErrorAction Ignore)
        {
            Invoke-YTRestMethod -Session $script:session `
                                -Method Delete `
                                -Resource "admin/projects/$($script:project.id)" `
                                -ErrorAction Ignore
        }
    }

    It 'deletes project using short name' {
        WhenDeletingProject $script:project.shortName
        ThenProject -Not -Exists
    }

    It 'deletes project using id' {
        WhenDeletingProject $script:project.id
        ThenProject -Not -Exists
    }

    It 'fails if project does not exist' {
        WhenDeletingProject 'fmvcklujhmkldu2qmklf' -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'not found'
    }

    It 'escapes project id' {
        WhenDeletingProject "$($script:project.shortName)?fields=fubar(snafu)" -ErrorAction SilentlyContinue
        ThenProject -Exists
        $Global:Error | Should -Match 'not found'
    }

    It 'accepts project short name from pipeline' {
        $script:project.shortName | Remove-YTProject -Session $script:session
        ThenProject -Not -Exists
    }

    It 'accepts project object with shortName property from pipeline' {
        $script:project | Select-Object -Property 'shortName' | Remove-YTProject -Session $script:session
        ThenProject -Not -Exists
    }

    It 'accepts project id from pipeline' {
        $script:project.id | Remove-YTProject -Session $script:session
        ThenProject -Not -Exists
    }

    It 'accepts project object with id from pipeline' {
        $script:project | Select-Object -Property 'id' | Remove-YTProject -Session $script:session
        ThenProject -Not -Exists
    }

    It 'accepts project object from pipeline' {
        $script:project | Remove-YTProject -Session $script:session
        ThenProject -Not -Exists
    }

    It 'supports WhatIf' {
        WhenDeletingProject $script:project.shortName -WithArgs @{ WhatIf = $true }
        ThenProject -Exists
    }
}