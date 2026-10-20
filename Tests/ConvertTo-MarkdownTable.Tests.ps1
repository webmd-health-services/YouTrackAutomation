
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
}

Describe 'ConvertTo-MarkdownTable' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'renders a table with header, separator, and data rows' {
        $objects = [pscustomobject]@{ a = 1; b = 2 }, [pscustomobject]@{ a = 3; b = 4 }
        $table = $objects | ConvertTo-MarkdownTable
        $lines = $table -split "`n"
        $lines | Should -HaveCount 4
        $lines[0] | Should -Be '| a | b |'
        $lines[1] | Should -Be '| --- | --- |'
        $lines[2] | Should -Be '| 1 | 2 |'
        $lines[3] | Should -Be '| 3 | 4 |'
    }

    It 'uses real newlines, not a literal backslash-n' {
        $table = [pscustomobject]@{ a = 1 } | ConvertTo-MarkdownTable
        $table.Contains('\n') | Should -BeFalse
        $table.Contains("`n") | Should -BeTrue
    }

    It 'returns an empty string for no input' {
        $table = @() | ConvertTo-MarkdownTable
        $table | Should -Be ''
    }
}
