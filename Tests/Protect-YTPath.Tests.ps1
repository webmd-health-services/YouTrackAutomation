
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
}

Describe 'Protect-YTResourcePath' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'joins paths' {
        Protect-YTResourcePath 'one','two','three' | Should -Be 'one/two/three'
    }

    It 'accepts pipeline input' {
        'four','five','six' | Protect-YTResourcePath | Should -Be 'four/five/six'
    }

    It 'escapes URL-sensitive characters' {
        Protect-YTResourcePath '?','//', '=&' | Should -Be '%3F/%2F%2F/%3D%26'
    }

    It 'prepends base path' {
        Protect-YTResourcePath -SafeBasePath 'seven/eight/nine' -UnsafeChildPath 'fubar/snafu' |
            Should -Be 'seven/eight/nine/fubar%2Fsnafu'
    }
}