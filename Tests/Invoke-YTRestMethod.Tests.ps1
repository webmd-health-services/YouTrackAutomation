Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'Invoke-YTRestMethod' {
    BeforeEach {
        $script:session = New-YTSession -Url $apiUrl -ApiToken $apiToken
    }

    It 'should always make GET requests' {
        $res = Invoke-YTRestMethod -Session $script:session -Name 'users/me' -Method Get
        $res.id | Should -Not -BeNullOrEmpty
        $res.'$type' | Should -Be 'Me'
        $res = Invoke-YTRestMethod -Session $script:session -Name 'users/me' -Method Get -WhatIf
        $res.id | Should -Not -BeNullOrEmpty
        $res.'$type' | Should -Be 'Me'
    }

    It 'should not make POST requests with WhatIf' {
        Clear-Project -Wait
        New-YTProject -Session $script:session -Name 'Invoke-YTRestMethod' -ShortName 'IYTRM' -Leader 'admin'
        $project = Invoke-YTRestMethod -Session $script:session -Name 'admin/projects?fields=id,name,shortName'
        $issue = New-YTIssue -Session $script:session -Project $project -Summary 'Test Ticket' -Description 'This is a test ticket.'
        
        # Should update issue summary
        $res = Invoke-YTRestMethod -Session $script:session -Name "issues/$($issue.id)" -Body @{summary = "New Title"} -Method Post
        $res | Should -Not -BeNullOrEmpty
        $res.id | Should -Be $issue.id
        $issue = Get-YTIssue -Session $script:session -IssueId $issue.id
        $issue.summary | Should -Be "New Title"

        # Should not update issue summary
        Invoke-YTRestMethod -Session $script:session -Name "issues/$($issue.id)" -Body @{summary = "Another Title"} -Method Post -WhatIf
        $issue = Get-YTIssue -Session $script:session -IssueId $issue.id
        $issue.summary | Should -Be "New Title"
    }

    It 'should get projects' {
        Clear-Project -Wait
        New-YTProject -Session $script:session -Name 'Invoke-YTRestMethod' -ShortName 'IYTRM' -Leader 'admin'
        $project = Invoke-YTRestMethod -Session $script:session -Name 'admin/projects?fields=id,name,shortName'
        $project | Should -HaveCount 1
    }
}