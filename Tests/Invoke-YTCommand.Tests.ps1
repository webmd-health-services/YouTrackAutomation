
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Get-YTProject -Session $script:session -Project 'IYTC' -ErrorAction Ignore
    if (-not $script:project)
    {
        $script:project =
            New-YTProject -Session $script:session -Name 'Invoke-YTCommand' -ShortName 'IYTC' -Leader 'admin'
    }


    function GivenIssue
    {
        param(
            [String] $Summary
        )

        New-YTIssue -Session $script:session -Summary $Summary -ProjectID $script:project.id
    }

    function ThenIssue
    {
        param(
            [String] $WithID,
            [String[]] $HasChildren
        )

        $property = Get-YTEntityField -Type 'IssueLink' -Depth 2
        $issue = Get-YTIssue -Session $script:session -Issue $WithID -Property "subtasks($($property -join ','))"
        $issue | Should -Not -BeNullOrEmpty

        if ($HasChildren)
        {
            foreach ($childID in $HasChildren)
            {
                $childIssue = Get-YTIssue -Session $script:session -Issue $childID
                $childIssue | Should -Not -BeNullOrEmpty

                $issue.subtasks.issues | Where-Object 'id' -EQ $childIssue.id | Should -Not -BeNullOrEmpty
            }
        }
    }

    function  ThenNothingReturned
    {
        $script:result | Should -BeNullOrEmpty
    }

    function WhenInvoking
    {
        param(
            [hashtable] $WithArgs
        )

        $script:result = Invoke-YTCommand -Session $script:session @WithArgs
    }
}

Describe 'Invoke-YTCommand' {
    BeforeEach {
        $script:result = $null
    }

    It 'accepts single issue id' {
        $parent = GivenIssue 'parent 1'
        $child = GivenIssue 'child 1'
        WhenInvoking @{ Query = "subtask of: $($parent.idReadable)"; Issue = $child.id }
        ThenIssue $parent.id -HasChildren $child.id
    }

    It 'accepts multiple issue IDs' {
        $parent = GivenIssue 'parent 2'
        $child1 = GivenIssue 'child 2'
        $child2 = GivenIssue 'child 3'
        WhenInvoking @{ Query = "subtask of: $($parent.idReadable)"; Issue = $child1.id,$child2.id }
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts issue ids from the pipeline' {
        $parent = GivenIssue 'parent 3'
        $child1 = GivenIssue 'child 4'
        $child2 = GivenIssue 'child 5'
        $child1.id,$child2.id | Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts issue readable ids from the pipeline' {
        $parent = GivenIssue 'parent 3b'
        $child1 = GivenIssue 'child 4b'
        $child2 = GivenIssue 'child 5b'
        $child1.idReadable,$child2.idReadable | Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts both issue ids and readable ids from the pipeline' {
        $parent = GivenIssue 'parent 3c'
        $child1 = GivenIssue 'child 4c'
        $child2 = GivenIssue 'child 5c'
        $child1.id,$child2.idReadable | Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts issue objects from the pipeline' {
        $parent = GivenIssue 'parent 4'
        $child1 = GivenIssue 'child 6'
        $child2 = GivenIssue 'child 7'
        $child1,$child2 | Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts issue object with just id property from the pipeline' {
        $parent = GivenIssue 'parent 5'
        $child1 = GivenIssue 'child 8'
        $child2 = GivenIssue 'child 9'
        $child1,$child2 |
            Select-Object -Property 'id' |
            Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }

    It 'accepts issue object with just readable id property from the pipeline' {
        $parent = GivenIssue 'parent 6'
        $child1 = GivenIssue 'child 10'
        $child2 = GivenIssue 'child 11'
        $child1,$child2 |
            Select-Object -Property 'idReadable' |
            Invoke-YTCommand -Session $script:session -Query "subtask of: $($parent.idReadable)"
        ThenIssue $parent.id -HasChildren $child1.id,$child2.id
    }
}
