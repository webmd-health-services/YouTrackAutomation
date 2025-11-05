
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)

}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:yttSession = Get-YTTSession
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

    It 'gets <_> fields up to maximum depth' -ForEach $knownEntities {
        Get-YTEntityField -Type $_ -Depth 5 | Should -Not -BeNullOrEmpty
    }

    It 'gets properties for nested objects' {
        $properties = Get-YTEntityField -Type 'Issue'
        $properties -split ',' | Should -Contain 'attachments'
    }

    It 'does not go more than five layers deep' {
        { Get-YTEntityField -Type 'Project' -Depth 10 } | Should -Throw '*maximum allowed range of 5*'
        $Global:Error | Should -Match 'maximum allowed range of 5'
    }

    It 'gets no more than five layers deep' {
        $properties = Get-YTEntityField -Type 'Project' -Depth 5
        $properties | Should -Not -BeNullOrEmpty
        $project = Get-YTProject -Session $script:yttSession -ShortName 'DEMO' -Property $properties
        $project | Should -Not -BeNullOrEmpty
        $project.customFields.project.customFields.project | Should -Not -BeNullOrEmpty
        $deepestObject = $project.customFields[0].project.customFields[0].project
        # This object should have empty properties.
        $deepestObject | Get-Member -Name 'customFields' | Should -Not -BeNullOrEmpty
        $members = $deepestObject.customFields[0] | Get-Member -MemberType NoteProperty
        $members | Should -HaveCount 1
        $members.Name | Should -Be '$type'
    }
}