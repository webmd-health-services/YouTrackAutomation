
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
}

Describe 'New-YTSession' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creates a session that uses an API token' {
        $url = 'https://fubar.snafu'
        $apiToken = 'my-api-token'
        $session = New-YTSession -Url $url -ApiToken $apiToken
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be "${url}/api/"
        $session.ApiToken | Should -Be $apiToken
    }

    It 'appends the api path without doubling the slash when the URL has a trailing slash' {
        $session = New-YTSession -Url 'https://fubar.snafu/' -ApiToken 'doesnotmatter'
        $session.Url | Should -Be 'https://fubar.snafu/api/'
    }

    It 'supports URLs with a path' {
        $session = New-YTSession -Url 'https://fubar.snafu/youtrack' -ApiToken 'doesnotmatter'
        $session.Url | Should -Be 'https://fubar.snafu/youtrack/api/'
    }

    It 'requires a URL' {
        { New-YTSession -ApiToken 'doesnotmatter' -ErrorAction Stop } | Should -Throw
    }

    It 'requires an API token' {
        { New-YTSession -Url 'https://fubar.snafu' -ErrorAction Stop } | Should -Throw
    }
}
