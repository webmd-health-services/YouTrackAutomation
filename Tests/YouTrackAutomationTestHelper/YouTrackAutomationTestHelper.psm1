
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\YouTrackAutomation' -Resolve)

$script:apiToken = $null
$script:ytUrl = 'http://localhost:8080'

$script:tokenPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.token'

if (-not (Test-Path -Path $script:tokenPath))
{
    $hubUrl = "$ytUrl/hub/api/rest"
    $credentialBytes = [Text.Encoding]::ASCII.GetBytes("admin:admin")
    $base64Creds = [Convert]::ToBase64String($credentialBytes)
    $headers = @{ 'Authorization' = "Basic $base64Creds"; 'Accept' = 'application/json'}

    $admin =
        Invoke-RestMethod -Method Get -Uri "$hubUrl/users?fields=login,id" -Headers $headers |
        Select-Object -ExpandProperty 'users' |
        Where-Object 'login' -eq 'admin'

    $services =
        Invoke-RestMethod -Method Get -Uri "$hubUrl/services?fields=id,name" -Headers $headers |
        Select-Object -ExpandProperty 'services'

    $youTrackService = $services | Where-Object 'name' -eq 'YouTrack'
    $youTrackAdministrationService = $services | Where-Object 'name' -eq 'YouTrack Administration'

    $requestParams  = @{}
    $body = @{
        name = 'ApiToken';
        scope = @(
            @{
                id = $youTrackService.id;
                name = $youTrackService.name;
            },
            @{
                id = $youTrackAdministrationService.id;
                name = $youTrackAdministrationService.name;
            }
        );
        user = @{
            id = $admin.id;
            name = $admin.name;
        };
    }
    $requestParams['Body'] = $body | ConvertTo-Json
    $requestParams['ContentType'] = 'application/json'

    $token = Invoke-RestMethod -Method Post `
                               -Uri "$hubUrl/users/$($admin.id)/permanenttokens?fields=id,name,token,scope,user" `
                               -Headers $headers `
                               @requestParams
    $token.token | Set-Content -Path $script:tokenPath -NoNewline
}

$script:apiToken = Get-Content -Path $script:tokenPath

$script:ytSession = New-YTSession -Url $script:ytUrl -ApiToken $script:apiToken

function Get-YTTSession
{
    param(
    )

    return $script:ytSession
}

function Initialize-YTTIssue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $Summary,

        [String] $Project
    )

    $projectEntity = Get-YTProject -Session $script:ytSession -Project $Project
    if (-not $projectEntity)
    {
        Write-Error -Message "Project ""${Project}"" does not exist."
        return
    }

    $issue =
        Get-YTIssue -Session $script:ytSession -Project $projectEntity.shortName -Summary $Summary |
        Where-Object 'Summary' -EQ $Summary |
        Select-Object -First 1

    if ($issue)
    {
        return $issue
    }

    return New-YTIssue -Session $script:ytSession -Summary $Summary  -ProjectID $projectEntity.id
}

function Initialize-YTTProject
{
    <#
    .SYNOPSIS
    Creates a test project for the caller.

    .DESCRIPTION
    The `Initialize-YTTProject` creates a project for the caller. Must be called from a .Tests.ps1 Pester file.
    The project name is the caller's file name. The project's short name are the uppercase letters from the test file
    name with .Tests.ps1 removed.
    #>
    [CmdletBinding()]
    param(
        [String] $Name,

        [String] $ShortName,

        [String] $Description
    )

    if (-not $Name -or -not $ShortName)
    {
        $caller =
            Get-PSCallStack |
            Where-Object 'ScriptName' -NE $PSCommandPath |
            Select-Object -First 1

        $callerFileName = $caller.ScriptName | Split-Path -Leaf
        if (-not $Name)
        {
            $Name = $callerFileName
        }

        if (-not $ShortName)
        {
            $ShortName = $callerFileName -creplace '[^A-Z]',''
            if ($callerFileName.EndsWith('.Tests.ps1'))
            {
                $ShortName = $ShortName.Substring(0, $ShortName.Length - 1)
            }
        }
    }

    $project = Get-YTProject -Session $script:ytSession -Project $ShortName -ErrorAction Ignore
    if ($project)
    {
        return $project
    }

    $desc = "${Name} project."
    return New-YTProject -Session $script:ytSession -Name $Name -ShortName $ShortName -Leader 'admin' -Description $desc
}

Export-ModuleMember -Function 'Get-YTTSession', 'Initialize-YTTIssue', 'Initialize-YTTProject'