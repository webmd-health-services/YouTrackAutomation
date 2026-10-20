
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
}

Describe 'Get-YTTag' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets a tag by name' {
        $tag = "get-$([Guid]::NewGuid())"
        Add-YTTag -Session $script:session -Tag $tag | Out-Null
        $result = Get-YTTag -Session $script:session -Tag $tag
        $result | Should -Not -BeNullOrEmpty
        $result.name | Should -Be $tag
        $result.id | Should -Not -BeNullOrEmpty
    }

    It 'returns nothing for a nonexistent tag' {
        Get-YTTag -Session $script:session -Tag "missing-$([Guid]::NewGuid())" | Should -BeNullOrEmpty
    }
}
