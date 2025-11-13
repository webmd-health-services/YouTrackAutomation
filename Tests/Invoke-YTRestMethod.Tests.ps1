Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\YouTrackAutomation' -Resolve)
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'YouTrackAutomationTestHelper' -Resolve)

    $script:session = Get-YTTSession
    $script:project = Initialize-YTTProject
    $script:issue = Initialize-YTTIssue -Summary 'Invoke-YTRestMethod test issue' -Project $script:project.shortName
    $script:issueID = $script:issue.idReadable
}

Describe 'Invoke-YTRestMethod' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'makes GET requests by default' {
        $res = Invoke-YTRestMethod -Session $script:session -Name 'users/me' -Method Get
        $res.id | Should -Not -BeNullOrEmpty
        $res.'$type' | Should -Be 'Me'
        $res = Invoke-YTRestMethod -Session $script:session -Name 'users/me' -Method Get -WhatIf
        $res.id | Should -Not -BeNullOrEmpty
        $res.'$type' | Should -Be 'Me'
    }

    It 'supports WhatIf' {
        $project = Get-YTProject -Session $script:session -Project $script:project.shortName
        $desc = 'This is a test ticket.'
        $issue = New-YTIssue -Session $script:session -ProjectID $project.id -Summary 'Test Ticket' -Description $desc

        # Should update issue summary
        $res = Invoke-YTRestMethod -Session $script:session `
                                   -Name "issues/$($issue.id)" `
                                   -Body @{ summary = 'New Title' } `
                                   -Method Post `
                                   -Property 'id'
        $res | Should -Not -BeNullOrEmpty
        $res.id | Should -Be $issue.id
        $issue = Get-YTIssue -Session $script:session -Issue $issue.id -Property 'id','summary'
        $issue.summary | Should -Be "New Title"

        # Should not update issue summary
        Invoke-YTRestMethod -Session $script:session -Name "issues/$($issue.id)" -Body @{summary = "Another Title"} -Method Post -WhatIf
        $issue = Get-YTIssue -Session $script:session -Issue $issue.id -Property 'summary'
        $issue.summary | Should -Be "New Title"
    }

    It 'gets projects' {
        $project = Invoke-YTRestMethod -Session $script:session -Name 'admin/projects?fields=id,name,shortName'
        $project | Should -Not -BeNullOrEmpty
    }

    It 'adds fields to requests' {
        $resource = "issues/${script:issueID}"
        $issue = Invoke-YTRestMethod -Session $script:session -Name $resource -Property 'idReadable,project(name)'
        $issue | Should -Not -BeNullOrEmpty
        $issue | Get-Member -Name 'id' | Should -BeNullOrEmpty
        $issue.idReadable | Should -Be $script:issue.idReadable
        $issue.project | Get-Member -Name 'id' | Should -BeNullOrEmpty
        $issue.project | Get-Member -Name 'name' | Should -Not -BeNullOrEmpty
        $issue.project.name | Should -Be $script:project.name
    }

    It 'adds fields from body to requests' {
        $issue = Invoke-YTRestMethod -Session $script:session `
                                     -Name 'issues' `
                                     -Method Post `
                                     -Body @{ summary = 'Test Issue'; project = @{ id = '0-0' } } `
                                     -Property 'id,idReadable,project(name)'
        $issue | Should -Not -BeNullOrEmpty
        $issue.summary | Should -Be 'Test Issue'
        $issue.id | Should -Not -BeNullOrEmpty
        $issue.idReadable | Should -Not -BeNullOrEmpty
        $issue.project | Should -Not -BeNullOrEmpty
        $issue.project | Get-Member -Name 'id' | Should -BeNullOrEmpty
        $issue.project.name | Should -Not -BeNullOrEmpty
    }

    It 'controls how many results to return' {
        $issues = Invoke-YTRestMethod -Session $script:session -Name 'issues'
        $issues | Should -Not -BeNullOrEmpty
        ($issues | Measure-Object).Count | Should -BeGreaterThan 1
        Invoke-YTRestMethod -Session $script:session -Name 'issues' -Top 1 -Property 'id','idReadable' |
            Should -HaveCount 1
    }

    It 'supports custom query parameters' {
        $queryParams = @{ 'fields' = 'id,idReadable'; '$top' = 1; }
        $issues = Invoke-YTRestMethod -Session $script:session -Name 'issues' -QueryParameter $queryParams
        $issues | Should -Not -BeNullOrEmpty
        $issues | Should -HaveCount 1
        $issues | Get-Member 'idReadable' | Should -Not -BeNullOrEmpty
        $issues | Get-Member 'summary' | Should -BeNullOrEmpty
    }

    It 'authenticates with credential' {
        $password = ConvertTo-SecureString 'admin' -Force -AsPlainText
        $admin = [pscredential]::New('admin', $password)
        $session = New-YTSession -Url $script:session.Url -Credential $admin
        $session | Should -Not -BeNullOrEmpty
        $me = Invoke-YTRestMethod -Session $session -Name 'users/me' -Property (Get-YTEntityField -Type 'User')
        $me | Should -Not -BeNullOrEmpty
        $me.fullName | Should -Be $admin.UserName
    }
}