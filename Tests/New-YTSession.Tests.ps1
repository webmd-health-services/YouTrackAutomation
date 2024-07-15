

Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'New-XWSession' {
    It 'should return a session object' {
        $url = 'https://fubar.snafu'
        $apiKey = 'my-api-key'
        $session = New-YTSession -Url $url -ApiToken $apiKey
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be ([uri]$url)
        $session.Connection | Should -Not -BeNullOrEmpty
        $session.ApiToken | Should -Be $apiKey
    }
}