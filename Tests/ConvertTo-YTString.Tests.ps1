
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
}

Describe 'ConvertTo-YTString' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'escapes brackets and backslashes' {
        'a[b]c' | ConvertTo-YTString | Should -Be 'a\[b\]c'
    }

    It 'converts newlines to the literal \n sequence' {
        $result = "line1`nline2" | ConvertTo-YTString
        $result | Should -Be 'line1\nline2'
    }

    It 'converts CRLF newlines to the literal \n sequence' {
        $result = "line1`r`nline2" | ConvertTo-YTString
        $result | Should -Be 'line1\nline2'
    }

    It 'returns an empty string unchanged' {
        '' | ConvertTo-YTString | Should -Be ''
    }

    It 'returns null unchanged' {
        $null | ConvertTo-YTString | Should -BeNullOrEmpty
    }
}
