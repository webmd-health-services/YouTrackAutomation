

Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'New-YTSession' {
    It 'should return a session object' {
        $url = 'https://fubar.snafu'
        $apiKey = 'my-api-key'
        $session = New-YTSession -Url $url -ApiToken $apiKey
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be "$url/api/"
        $session.ApiToken | Should -Be $apiKey
    }
}