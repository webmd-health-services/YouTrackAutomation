
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession

    # Make sure any projects from previous runs are gone.
    Get-YTProject -Session $script:session |
        Where-Object 'ShortName' -Like 'NYTP*' |
        Remove-YTProject -Session $script:session

    $login = 'newytproject'
    # Create a project leader that isn't the current user to test that assigning a custom leader works.
    $script:leader = Get-YTUser -Session $script:session -User $login -ErrorAction Ignore
    if (-not $script:leader)
    {
        $fields = Get-YTEntityField -Type 'User'
        # Users can only be created using the Hub API. YouTrackAutomation doesn't have native support for the HUB api,
        # but we can fake it out.
        $hubSession = New-YTSession -Url "$($script:session.Url)hub/" -ApiToken $script:session.ApiToken
        $body = @{
            login = $login
        }
        Invoke-YTRestMethod -Session $hubSession -Resource 'rest/users' -Method Post -Body $body -Property $fields |
            Out-Null

        # It can take a minute for the user to exist.
        $timer = [Diagnostics.Stopwatch]::StartNew()
        do
        {
            # Hub API objects and REST API objects can't be intermingled.
            $script:leader = Get-YTUser -Session $script:session -User $login -ErrorAction Ignore
            if ($script:leader)
            {
                break
            }
            Start-Sleep -Seconds 1
        }
        while ($timer.Elapsed -lt (New-TimeSpan -Seconds 10))
    }

    function WhenCreatingProject
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $Name,

            [Parameter(Mandatory)]
            [String] $ShortName,

            [String] $Description,

            [String] $Template,

            [String] $AdditionalFields
        )

        $script:result =
            New-YTProject -Session $session @PSBoundParameters -LeaderID $script:leader.id -ErrorAction 'Stop'
    }

    function ThenProjectExists
    {
        [CmdletBinding()]
        param(
            [String] $ShortName
        )

        $project = Get-YTProject -Session $session -Project $ShortName
        $project | Should -Not -BeNullOrEmpty
        $project.leader.id | Should -Be $script:leader.id
    }
}

Describe 'New-YTProject' {
    It 'should create a new project' {
        WhenCreatingProject -Name 'New-YTProject Test1' -ShortName 'NYTP1'
        ThenProjectExists -ShortName 'NYTP1'
    }

    It 'should create a new project with a template' {
        WhenCreatingProject -Name 'New-YTProject Test2' -ShortName 'NYTP2' -Template 'scrum'
        WhenCreatingProject -Name 'New-YTProject Test3' -ShortName 'NYTP3' -Template 'kanban'
        ThenProjectExists -ShortName 'NYTP2'
        ThenProjectExists -ShortName 'NYTP3'
    }

    It 'should fail to make a project with a short name that already exists' {
        WhenCreatingProject -Name 'New-YTProject Test4' -ShortName 'NYTP4'
        ThenProjectExists -ShortName 'NYTP4'
        { WhenCreatingProject -Name 'New-YTProject Test4' -ShortName 'NYTP4' } | Should -Throw '*Project is not unique*'
    }
}