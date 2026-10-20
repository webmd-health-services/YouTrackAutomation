
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\YouTrackAutomation' -Resolve)

$script:apiToken = $null
$script:ytUrl = 'http://localhost:8080'

$script:tokenPath = Join-Path -Path $PSScriptRoot -ChildPath '..\.token'

if (-not (Test-Path -Path $script:tokenPath))
{
    $hubUrl = "$ytUrl/hub/api/rest"
    $credentialBytes = [Text.Encoding]::ASCII.GetBytes("admin:admin")
    $base64Creds = [Convert]::ToBase64String($credentialBytes)
    $headers = @{ 'Authorization' = "Basic $base64Creds"; 'Accept' = 'application/json' }

    $admin =
        Invoke-RestMethod -Method Get -Uri "$hubUrl/users?fields=login,id" -Headers $headers |
        Select-Object -ExpandProperty 'users' |
        Where-Object 'login' -eq 'admin'

    $services =
        Invoke-RestMethod -Method Get -Uri "$hubUrl/services?fields=id,name" -Headers $headers |
        Select-Object -ExpandProperty 'services'

    $youTrackService = $services | Where-Object 'name' -eq 'YouTrack'
    $youTrackAdministrationService = $services | Where-Object 'name' -eq 'YouTrack Administration'

    $requestParams = @{}
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
    <#
    .SYNOPSIS
    Returns the shared YouTrack session used by the test suite.

    .DESCRIPTION
    The `Get-YTTSession` function returns the session object created when the test helper module is imported. Tests pass
    it to the module's functions via their `Session` parameter.

    .EXAMPLE
    $session = Get-YTTSession

    Demonstrates getting the shared test session.
    #>
    [CmdletBinding()]
    param(
    )

    return $script:ytSession
}

function Initialize-YTTProject
{
    <#
    .SYNOPSIS
    Creates (or returns an existing) test project for the caller.

    .DESCRIPTION
    The `Initialize-YTTProject` creates a project for the caller. Must be called from a .Tests.ps1 Pester file. When
    `Name`/`ShortName` are not given, the project name is the caller's file name and the short name is the uppercase
    letters from the test file name with `.Tests.ps1` removed.
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
            $ShortName = $callerFileName -creplace '[^A-Z]', ''
            if ($callerFileName.EndsWith('.Tests.ps1'))
            {
                $ShortName = $ShortName.Substring(0, $ShortName.Length - 1)
            }
        }
    }

    $project = Get-YTProject -Session $script:ytSession -ShortName $ShortName -ErrorAction Ignore
    if ($project)
    {
        return $project
    }

    $desc = "${Name} project."
    if ($Description)
    {
        $desc = $Description
    }

    $leader = Get-YTUser -Session $script:ytSession -User 'admin'
    return New-YTProject -Session $script:ytSession `
                         -Name $Name `
                         -ShortName $ShortName `
                         -LeaderID $leader.id `
                         -Description $desc
}

function Initialize-YTTIssue
{
    <#
    .SYNOPSIS
    Creates a new issue in the given project for use by a test.

    .DESCRIPTION
    The `Initialize-YTTIssue` function creates a new issue in the project whose short name is passed to the `Project`
    parameter and returns the created issue.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String] $Summary,

        [Parameter(Mandatory)]
        [String] $Project,

        [String] $Description
    )

    $newArgs = @{}
    if ($Description)
    {
        $newArgs['Description'] = $Description
    }

    return New-YTIssue -Session $script:ytSession -Project $Project -Summary $Summary @newArgs
}

Export-ModuleMember -Function 'Get-YTTSession', 'Initialize-YTTIssue', 'Initialize-YTTProject'
