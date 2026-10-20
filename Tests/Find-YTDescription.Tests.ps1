
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject

    function GivenIssue
    {
        param(
            [Parameter(Mandatory, Position = 0)]
            [String] $WithSummary,

            [String] $WithDescription
        )

        Initialize-YTTIssue -Project $script:project.shortName -Summary $WithSummary -Description $WithDescription
    }

    function WhenFinding
    {
        param(
            [Parameter(Mandatory)]
            [String] $Description
        )

        # Issues can take a few seconds to be indexed for search, so retry for up to 10 seconds.
        $script:result = $null
        $timer = [Diagnostics.Stopwatch]::StartNew()
        do
        {
            $script:result = Find-YTDescription -Session $script:session -Description $Description -Project $script:project.shortName
            if ($script:result)
            {
                break
            }

            Start-Sleep -Seconds 1
        }
        while ($timer.Elapsed.TotalSeconds -lt 10)
    }
}

Describe 'Find-YTDescription' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'finds an issue by description text' {
        $marker = [Guid]::NewGuid().ToString('N')
        $issue = GivenIssue 'find by description' -WithDescription "Access Termination Date: ${marker}"
        WhenFinding -Description $marker
        $script:result | Should -Not -BeNullOrEmpty
        $script:result | Where-Object 'idReadable' -EQ $issue.idReadable | Should -Not -BeNullOrEmpty
    }

    It 'flattens custom fields onto the returned issues' {
        $marker = [Guid]::NewGuid().ToString('N')
        $null = GivenIssue 'find flattens fields' -WithDescription "Marker: ${marker}"
        WhenFinding -Description $marker
        $script:result | Should -Not -BeNullOrEmpty
        $script:result[0].PSObject.TypeNames | Should -Contain 'WHS.YTIssue.Object'
    }

    It 'returns nothing when no issue matches' {
        $result =
            Find-YTDescription -Session $script:session `
                               -Description ([Guid]::NewGuid().ToString('N')) `
                               -Project $script:project.shortName
        $result | Should -BeNullOrEmpty
    }
}
