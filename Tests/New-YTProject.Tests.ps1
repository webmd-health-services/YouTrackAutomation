
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)

    function WhenCreatingProject
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [String] $Name,

            [Parameter(Mandatory)]
            [String] $ShortName,

            [Parameter(Mandatory)]
            [String] $Leader,

            [String] $Description,

            [String] $Template,

            [String] $AdditionalFields
        )

        $script:result = New-YTProject -Session $session @PSBoundParameters
    }

    function ThenProjectExists
    {
        [CmdletBinding()]
        param(
            [String] $ProjectShortName
        )

        Get-YTProject -Session $session -ProjectShortName $ProjectShortName | Should -Not -BeNullOrEmpty
    }
}

Describe 'New-YTProject' {
    BeforeEach {
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    }

    It 'should create a new project' {
        WhenCreatingProject -Name 'New-YTProject Test1' -ShortName 'NYTP1' -Leader 'admin'
        ThenProjectExists -ProjectShortName 'NYTP1'
    }

    It 'should create a new project with a template' {
        WhenCreatingProject -Name 'New-YTProject Test2' -ShortName 'NYTP2' -Leader 'admin' -Template 'scrum'
        WhenCreatingProject -Name 'New-YTProject Test3' -ShortName 'NYTP3' -Leader 'admin' -Template 'kanban'
        ThenProjectExists -ProjectShortName 'NYTP2'
        ThenProjectExists -ProjectShortName 'NYTP3'
    }

    It 'should fail to make a project with a short name that already exists' {
        WhenCreatingProject -Name 'New-YTProject Test4' -ShortName 'NYTP4' -Leader 'admin'
        ThenProjectExists -ProjectShortName 'NYTP4'
        { WhenCreatingProject -Name 'New-YTProject Test4' -ShortName 'NYTP4' -Leader 'admin' } | Should -Throw
    }

    It 'should handle leader by id' {
        WhenCreatingProject -Name 'New-YTProject Test5' -ShortName 'NYTP5' -Leader '2-1'
        ThenProjectExists -ProjectShortName 'NYTP5'
    }
}