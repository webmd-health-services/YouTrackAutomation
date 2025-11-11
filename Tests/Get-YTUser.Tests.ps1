
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
}

Describe 'Get-YTUser' {
    BeforeEach {
        $script:me = Get-YTUser -Session $script:session -User 'me'
        $Global:Error.Clear()
    }

    It 'gets me' {
        $me = Get-YTUser -Session $script:session -Me
        $me | Should -Not -BeNullOrEmpty
        $me.'$type' | Should -Be 'Me'
        # The only difference between a normal user and Me, is the savedQueries property
        $me | Get-Member 'savedQueries' | Should -Not -BeNullOrEmpty
    }

    It 'gets me when passed me as id' {
        $me = Get-YTUser -Session $script:session -User 'me'
        $me | Should -Not -BeNullOrEmpty
        $me.'$type' | Should -Be 'Me'
        # The only difference between a normal user and Me, is the savedQueries property
        $me | Get-Member 'savedQueries' | Should -Not -BeNullOrEmpty
    }

    Context 'parameters' {
        It 'gets user by id' {
            $user = Get-YTUser -Session $script:session -User $script:me.id
            $user | Should -Not -BeNullOrEmpty
            $user.id | Should -Be $script:me.id
            $user.fullName | Should -Be $script:me.fullName
            # Make sure nested objects don't have any properties.
            $user.tags | Get-Member 'issues' | Should -BeNullOrEmpty
        }

        It 'gets user by login' {
            $user = Get-YTUser -Session $script:session -user $script:me.login
            $user | Should -Not -BeNullOrEmpty
            $user.id | Should -Be $script:me.id
        }

        It 'encodes user id' {
            $user = Get-YTUser -Session $script:session -User "$($script:me.id)?p=v" -ErrorAction SilentlyContinue
            $user | Should -BeNullOrEmpty
            $Global:Error | Should -Match 'not found'
        }
    }

    Context 'pipeline' {
        It 'accepts user object from pipeline' {
            $users = $script:me,$script:me | Get-YTUser -Session $script:session
            $users | Should -HaveCount 2
            $users[0].id | Should -Be $script:me.id
            $users[1].id | Should -Be $script:me.id
        }

        It 'accepts object with id property from pipeline' {
            $users = $script:me,$script:me | Select-Object -Property 'id' | Get-YTUser -Session $script:session
            $users | Should -HaveCount 2
            $users[0].id | Should -Be $script:me.id
            $users[1].id | Should -Be $script:me.id
        }

        It 'accepts object with id property from pipeline' {
            $users = $script:me,$script:me | Select-Object -Property 'login' | Get-YTUser -Session $script:session
            $users | Should -HaveCount 2
            $users[0].id | Should -Be $script:me.id
            $users[1].id | Should -Be $script:me.id
        }

        It 'accepts ids and logins from the pipeline' {
            $users = $script:me.id,$script:me.login | Get-YTUser -Session $script:session
            $users | Should -HaveCount 2
            $users[0].id | Should -Be $script:me.id
            $users[1].id | Should -Be $script:me.id
        }
    }
}
