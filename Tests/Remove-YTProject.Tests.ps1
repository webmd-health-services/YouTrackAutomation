
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function GivenProject
    {
        param(
            $WithName,
            $WithProjectShortName
        )

        New-YTProject -Session $script:session -Name  $WithName -ShortName $WithProjectShortName -Leader 'admin'
        $script:projectName = $WithProjectShortName
    }

    function WhenDeletingProject
    {
        param(
            [Parameter(Mandatory)]
            [Object] $WithProject
        )

        Remove-YTProject -Session $script:session -Project $WithProject -ErrorAction 'Stop'
    }

    function ThenProjectIsDeleted
    {
        param(
            $WithProjectShortName
        )

        $project = Get-YTProject -Session $script:session -ShortName $WithProjectShortName
        $null -eq $project -or $project.name.Contains('deletion') | Should -BeTrue
    }
}

Describe 'Remove-YTProject' {
    BeforeEach {
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
        $script:projectName = ''
    }

    AfterEach {
        Clear-Project -Wait
    }

    It 'should delete project based on short name' {
        GivenProject -WithName 'Remove-YTProjectTest' -WithProjectShortName 'RYTP'
        WhenDeletingProject -WithProject 'RYTP'
        ThenProjectIsDeleted -WithProjectShortName 'RYTP'
    }

    It 'should delete project based on id' {
        GivenProject -WithName 'Remove-YTProjectTest2' -WithProjectShortName 'RYTP2'
        $id = (Get-YTProject -Session $script:session -ShortName 'RYTP2').id
        WhenDeletingProject -WithProject $id
        ThenProjectIsDeleted -WithProjectShortName 'RYTP2'
    }

    It 'should error if project does not exist' {
        GivenProject -WithName 'Remove-YTProjectTest3' -WithProjectShortName 'RYTP3'
        { WhenDeletingProject -WithProject 'RYTP3' } | Should -Not -Throw
        { WhenDeletingProject -WithProject 'RYTP3' } | Should -Throw
    }

}