

Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'New-YTSession' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creates session that uses an API key' {
        $url = 'https://fubar.snafu'
        $apiKey = 'my-api-key'
        $session = New-YTSession -Url $url -ApiToken $apiKey
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be "${url}/"
        $session.ApiToken | Should -Be $apiKey
        $session.Credential | Should -BeNullOrEmpty
    }

    It 'creates session that uses credential' {
        $url = 'https://fubar.snafu'
        $credential =
            [pscredential]::new('new-ytsession2', (ConvertTo-SecureString 'new-ytsession2' -Force -AsPlainText))
        $session = New-YTSession -Url $url -Credential $credential
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be "${url}/"
        $session.ApiToken | Should -BeNullOrEmpty
        $session.Credential | Should -BeExactly $credential
    }

    It 'handles directory separator in URL' {
        $session = New-YTSession -Url 'http://localhost:8080/' -ApiToken 'doesnotmatter'
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be 'http://localhost:8080/'
        $session.ApiToken | Should -Be 'doesnotmatter'
        $session.Credential | Should -BeNullOrEmpty
    }

    It 'supports cloud URLs' {
        $session = New-YTSession -Url 'http://localhost:8080/youtrack' -ApiToken 'doesnotmatter'
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be 'http://localhost:8080/youtrack/'
        $session.ApiToken | Should -Be 'doesnotmatter'
        $session.Credential | Should -BeNullOrEmpty
    }

    It 'handles directory separator in cloud URL' {
        $session = New-YTSession -Url 'http://localhost:8080/youtrack/' -ApiToken 'doesnotmatter'
        $session | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be 'http://localhost:8080/youtrack/'
        $session.ApiToken | Should -Be 'doesnotmatter'
        $session.Credential | Should -BeNullOrEmpty
    }
}
