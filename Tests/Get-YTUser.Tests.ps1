
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
}

Describe 'Get-YTUser' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'gets a user by login' {
        $user = Get-YTUser -Session $script:session -User 'admin'
        $user | Should -Not -BeNullOrEmpty
        $user.login | Should -Be 'admin'
        $user.id | Should -Not -BeNullOrEmpty
    }

    It 'gets a user by id' {
        $admin = Get-YTUser -Session $script:session -User 'admin'
        $user = Get-YTUser -Session $script:session -User $admin.id
        $user.id | Should -Be $admin.id
    }

    It 'gets the current user with -Me' {
        $me = Get-YTUser -Session $script:session -Me
        $me | Should -Not -BeNullOrEmpty
        $me.login | Should -Not -BeNullOrEmpty
    }

    It 'accepts a login from the pipeline' {
        $user = 'admin' | Get-YTUser -Session $script:session
        $user.login | Should -Be 'admin'
    }
}
