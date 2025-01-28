Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    Clear-Project -Wait

    function GivenProject
    {
        [CmdletBinding()]
        param(
            [String] $ShortName = 'GYTP1',
            [String] $Name = 'Get-YTProject Test Project',
            [String] $Leader = 'admin'
        )

        $script:projectShortName = $ShortName
        New-YTProject -Session $script:session -ShortName $ShortName -Name $Name -Leader $Leader -Description 'This is a test project.'
    }

    function WhenGettingProject
    {
        [CmdletBinding()]
        param(
            [String] $ShortName,
            [String] $AdditionalField
        )

        $script:result = Get-YTProject -Session $script:session @PSBoundParameters
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
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
        $script:result = $null
    }

    It 'returns one project' {
        GivenProject -ShortName 'GYTP1' -Name 'Get-YTProject Test Project' -Leader 'admin'
        WhenGettingProject -ShortName 'GYTP1'
        ThenReturns -Count 1 -ProjectWithShortName 'GYTP1'
    }

    It 'return all projects' {
        GivenProject -ShortName 'GYTP2' -Name 'Get-YTProject Test Project' -Leader 'admin'
        WhenGettingProject
        ThenReturns -Count 2 -ProjectWithShortName 'GYTP1', 'GYTP2'
    }

    It 'should support additional fields' {
        WhenGettingProject -ShortName 'GYTP1' -AdditionalField 'description'
        ThenReturns -Count 2 -ProjectWithField 'description'
    }
}