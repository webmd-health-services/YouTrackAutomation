Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession

    function GivenProject
    {
        [CmdletBinding()]
        param(
            [String] $ShortName = 'GYTP1',
            [String] $Name = 'Get-YTProject Test Project',
            [String] $Leader = 'admin'
        )

        $script:projectShortName = $ShortName
        $project = New-YTProject -Session $script:session `
                                 -ShortName $ShortName `
                                 -Name $Name `
                                 -Leader $Leader `
                                 -Description 'This is a test project.' `
                                 -ErrorAction Ignore
        if ($project)
        {
            return $project
        }

        Get-YTProject -Session $script:session -Project $ShortName
    }

    function WhenGettingProject
    {
        [CmdletBinding()]
        param(
            [hashtable] $WithArgs = @{}
        )

        $script:result = Get-YTProject -Session $script:session @WithArgs
    }

    function ThenReturns
    {
        [CmdletBinding()]
        param(
            [int] $Count,
            [String[]] $ProjectWithShortName,
            [String] $ProjectWithField
        )

        if ($Count)
        {
            $script:result | Should -Not -BeNullOrEmpty
            if (Get-Member -Name Length -InputObject $script:result -ErrorAction SilentlyContinue)
            {
                $script:result.Length | Should -Be $Count
            }
            $idCount =
                $script:result |
                ForEach-Object { $_.id }  |
                Select-Object -Unique |
                Measure-Object |
                Select-Object -ExpandProperty Count
            $script:result | Should -HaveCount $idCount
        }

        if ($ProjectWithField)
        {
            $script:result.$ProjectWithField | Should -Not -BeNullOrEmpty
        }

        if ($ProjectWithShortName)
        {
            $script:result |
                ForEach-Object { $_.shortName} |
                Where-Object { $_ -in $ProjectWithShortName } |
                Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Get-YTProject' {
    BeforeEach {
        $script:result = $null
        $Global:Error.Clear()
    }

    It 'gets project by short name' {
        GivenProject -ShortName 'GYTP1' -Name 'Get-YTProject Test Project' -Leader 'admin'
        WhenGettingProject -WithArgs @{ Project = 'GYTP1' }
        ThenReturns -Count 1 -ProjectWithShortName 'GYTP1'
    }

    It 'gets project by ID' {
        $project = GivenProject -ShortName 'GYTP1B' -Name 'Get-YTProject Test Project 1B' -Leader 'admin'
        WhenGettingProject -WithArgs @{ Project = $project.id }
        ThenReturns -Count 1 -ProjectWithShortName 'GYTP1B'
    }

    It 'returns all projects' {
        WhenGettingProject
        ($script:result | Measure-Object).Count | Should -BeGreaterThan 1
    }

    It 'supports custom properties' {
        WhenGettingProject -WithArgs @{ Project = 'GYTP1'; Property = 'id','description' }
        ThenReturns -Count 2 -ProjectWithField 'description'
    }

    It 'supports top' {
        WhenGettingProject -WithArgs @{ Top = 1; }
        ThenReturns -Count 1
    }

    It 'escapes project' {
        WhenGettingProject -WithArgs @{ Project = 'GYTP1?fields=iconUrl' } -ErrorAction SilentlyContinue
        $Global:Error | Should -Match 'not found'
    }

    It 'ignores errors' {
        WhenGettingProject -WithArgs @{ Project = 'fubarsnafufizzbuzz' ; ErrorAction = 'Ignore' }
        $script:result | Should -BeNullOrEmpty
        $Global:Error | Should -HaveCount 1 # The original HTTP 500 server exception can't be removed.
    }
}