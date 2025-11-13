
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
    $script:issue = Initialize-YTTIssue -Project $script:project.shortName -Summary 'Get-YTBundle Test Issue'
}

Describe 'Get-YTBundle' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets bundle' {
        $fields = $script:issue | Get-YTIssueCustomField -Session $script:session

        $foundOne = $false
        foreach ($field in $fields)
        {
            $typedField = Get-YTIssueCustomField -Session $script:session `
                                                 -Issue $script:issue.idReadable `
                                                 -Field $field.name `
                                                 -Type $field.'$type'
            if (-not $typedField.value -or -not ($typedField.value | Get-Member -Name 'bundle'))
            {
                continue
            }

            $foundOne = $true

            $bundle = $typedField.value.bundle

            # Accepts a bundle from the pipeline.
            $bundle = $typedField.value.bundle | Get-YTBundle -Session $script:session
            $bundle | Should -Not -BeNullOrEmpty
            $bundle.values | Should -Not -BeNullOrEmpty
            $bundle.values | Get-Member 'id' | Should -Not -BeNullOrEmpty
            $bundle.values | Get-Member 'name' | Should -Not -BeNullOrEmpty

            # Gets bundle by id and type.
            $bundle = Get-YTBundle -Session $script:session -ID $bundle.id -Type $bundle.'$type'
            $bundle | Should -Not -BeNullOrEmpty
            $bundle.values | Should -Not -BeNullOrEmpty
            $bundle.values | Get-Member 'id' | Should -Not -BeNullOrEmpty
            $bundle.values | Get-Member 'name' | Should -Not -BeNullOrEmpty
        }

        $foundOne | Should -BeTrue
    }
}