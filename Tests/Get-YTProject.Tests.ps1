Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function GivenProject
    {
        [CmdletBinding()]
        param(
            [String] $ShortName = 'GYTP1',
            [String] $Name = 'Get-YTProject Test Project',
            [String] $Leader = 'admin'
        )

        New-YTProject -Session $script:session -ShortName $ShortName -Name $Name -Leader $Leader -Description 'This is a test project.'
    }

    function WhenGettingProject
    {
        [CmdletBinding()]
        param(
            [String] $ProjectShortName,
            [String] $AdditionalFields
        )

        $script:result = Get-YTProject -Session $script:session @PSBoundParameters
    }

    function ThenProjectHasField
    {
        [CmdletBinding()]
        param(
            [String] $Field
        )

        $script:result.$Field | Should -Not -BeNullOrEmpty
    }

    function ThenProjectsReturned
    {
        [CmdletBinding()]
        param(
            [Int] $GreaterThanEqual = 1

        )
        $script:result | Should -Not -BeNullOrEmpty
        if (Get-Member -Name Length -InputObject $script:result -ErrorAction SilentlyContinue)
        {
            $script:result.Length | Should -BeGreaterOrEqual $GreaterThanEqual
        }
        $idCount =
            $script:result |
            ForEach-Object { $_.id }  |
            Select-Object -Unique |
            Measure-Object |
            Select-Object -ExpandProperty Count
        $script:result | Should -HaveCount $idCount
    }

    function ThenProjectWithShortName
    {
        [CmdletBinding()]
        param(
            [String] $ShortName
        )

        $script:result |
            ForEach-Object { $_.shortName} |
            Where-Object { $_ -eq $ShortName } |
            Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-YTIssue' {
    BeforeEach {
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    }

    It 'returns one project' {
        GivenProject -ShortName 'GYTP1' -Name 'Get-YTProject Test Project' -Leader 'admin'
        WhenGettingProject -ProjectShortName 'DEMO'
        ThenProjectsReturned -GreaterThanEqual 1
        ThenProjectWithShortName -ShortName 'DEMO'
    }

    It 'return all projects' {
        WhenGettingProject
        ThenProjectsReturned -GreaterThanEqual 2
        ThenProjectWithShortName -ShortName 'DEMO'
    }

    It 'should support additional fields' {
        WhenGettingProject -AdditionalFields 'description'
        ThenProjectsReturned -GreaterThanEqual 2
        $script:result | Where-Object {$_.shortName -eq 'GYTP1'} | ForEach-Object { $_.description } | Should -Not -BeNullOrEmpty
    }
}