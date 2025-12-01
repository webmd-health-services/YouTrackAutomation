
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
    $knownEntitiesTypeNames = $knownEntities.Keys | Sort-Object

    It 'gets fields for <_>' -ForEach $knownEntitiesTypeNames {
        $knownEntities = InModuleScope -ModuleName 'YouTrackAutomation' { return $script:entityAttributes }
        $typeName = $_
        $fields = Get-YTEntityField -Type $typeName
        $fields | Should -Not -BeNullOrEmpty
        foreach ($expectedField in $knownEntities[$typeName])
        {
            if ($expectedField -is [String])
            {
                $fields | Should -Contain $expectedField
                continue
            }

            $fieldType = $expectedField['Type']
            $fieldName = $expectedField['Name']
            $fieldIsArray = $expectedField['IsArray']

            if ($fieldIsArray)
            {
                $fields |
                    Where-Object { $_ -eq $fieldName -or $_.StartsWith("${fieldName}(") } |
                    Should -BeNullOrEmpty `
                           -Because "${fieldtype}.${fieldName} is an array but was present when depth is 1"
                continue
            }

            $fields | Should -Contain "${fieldName}(id)" `
                             -Because "${fieldType}.${fieldName} object's id property should be returned"
        }
    }

    It 'gets nested fields for <_>' -ForEach $knownEntitiesTypeNames {
        $knownEntities = InModuleScope -ModuleName 'YouTrackAutomation' { return $script:entityAttributes }
        $typeName = $_
        $fields = Get-YTEntityField -Type $typeName -Depth 2
        $fields | Should -Not -BeNullOrEmpty
        foreach ($expectedField in $knownEntities[$typeName])
        {
            if ($expectedField -is [String])
            {
                $fields | Should -Contain $expectedField
                continue
            }

            $fieldName = $expectedField['Name']
            $fieldType = $expectedField['Type']

            $fields |
                Where-Object { $_.StartsWith("${fieldName}(") } |
                    Should -Not -BeNullOrEmpty -Because "${fieldType}.${fieldName} should be present"
        }
    }

    It 'avoids infinite recursion for <_>' -ForEach $knownEntitiesTypeNames {
        Get-YTEntityField -Type $_ -Depth ([Int32]::MaxValue) -WarningVariable 'warnings' | Should -Not -BeNullOrEmpty
        $warnings | Should -BeNullOrEmpty
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