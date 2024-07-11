
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function GivenModuleLoaded
    {
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation\YouTrackAutomation.psd1' -Resolve)
        Get-Module -Name 'YouTrackAutomation' | Add-Member -MemberType NoteProperty -Name 'NotReloaded' -Value $true
    }

    function GivenModuleNotLoaded
    {
        Remove-Module -Name 'YouTrackAutomation' -Force -ErrorAction Ignore
    }

    function ThenModuleLoaded
    {
        $module = Get-Module -Name 'YouTrackAutomation'
        $module | Should -Not -BeNullOrEmpty
        $module | Get-Member -Name 'NotReloaded' | Should -BeNullOrEmpty
    }

    function WhenImporting
    {
        $script:importedAt = Get-Date
        Start-Sleep -Milliseconds 1
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation\Import-YouTrackAutomation.ps1' -Resolve)
    }
}

Describe 'Import-YouTrackAutomation' {
    It 'should import the module' {
        GivenModuleNotLoaded
        WhenImporting
        ThenModuleLoaded
    }

    It 'should re-import the module' {
        GivenModuleLoaded
        WhenImporting
        ThenModuleLoaded
    }
}
