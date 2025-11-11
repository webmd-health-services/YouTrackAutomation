
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)

}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
}

Describe 'Get-YTEntityField' {
    BeforeEach {
        $Global:Error.Clear()
    }

    $knownEntities = InModuleScope -ModuleName 'YouTrackAutomation' { return $script:entityAttributes }
    $knownEntities = $knownEntities.Keys | Sort-Object

    It 'gets <_> fields' -ForEach $knownEntities {
        Get-YTEntityField -Type $_ | Should -Not -BeNullOrEmpty
    }

    It 'avoids infinite cursion for <_> fields' -ForEach $knownEntities {
        Get-YTEntityField -Type $_ -Depth ([Int32]::MaxValue) -WarningVariable 'warnings' | Should -Not -BeNullOrEmpty
        $warnings | Should -BeNullOrEmpty
    }

    It 'gets properties for nested objects' {
        $properties = Get-YTEntityField -Type 'Issue'
        $properties -split ',' | Should -Contain 'attachments'
    }

    It 'api respects property list' {
        # We're requesting *a lot* of data, so make sure there is a minimal amount of data to actually return.
        New-YTIssue -Session $script:session  -ProjectID $script:project.id -Summary 'Just Need One'
        $properties = Get-YTEntityField -Type 'Project' -Depth ([Int32]::MaxValue)
        $properties | Should -Not -BeNullOrEmpty
        $project = Get-YTProject -Session $script:session -Project $script:project.id -Property $properties
        $project | Should -Not -BeNullOrEmpty
    }
}