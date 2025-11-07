
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

Export-ModuleMember -Function 'Get-YTTSession'