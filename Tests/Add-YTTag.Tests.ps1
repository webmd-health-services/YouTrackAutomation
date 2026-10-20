
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
}

Describe 'Add-YTTag' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creates a new tag' {
        $tag = "add-$([Guid]::NewGuid())"
        $result = Add-YTTag -Session $script:session -Tag $tag
        $result | Should -Not -BeNullOrEmpty
        $result.name | Should -Be $tag
        Get-YTTag -Session $script:session -Tag $tag | Should -Not -BeNullOrEmpty
    }

    It 'supports -WhatIf' {
        $tag = "whatif-$([Guid]::NewGuid())"
        Add-YTTag -Session $script:session -Tag $tag -WhatIf
        Get-YTTag -Session $script:session -Tag $tag | Should -BeNullOrEmpty
    }
}
