$apiToken = $null
$apiUrl = 'http://localhost:8080'

function Clear-Project
{
    [CmdletBinding()]
    param(
        [switch] $Wait
    )

    $s = New-YTSession -ApiToken $apiToken -Url $apiUrl

    foreach ($project in (Get-YTProject -Session $s))
    {
        Remove-YTProject -Session $s -Project $project
    }

    if (-not $Wait)
    {
        return
    }

    $stopwatch = [Diagnostics.Stopwatch]::StartNew()

    while ($null -ne (Get-YTProject -Session $s))
    {
        Start-Sleep -Seconds 2
        if ($stopwatch.Elapsed.seconds -gt 30)
        {
            Write-Error -Message "Waiting for projects to be deleted is taking longer than 30 seconds. Aborting."
            return
        }
    }
    $stopwatch.Stop()
    $stopwatch = $stopwatch.Elapsed
}

function Get-Token
{
    [CmdletBinding()]
    param()

    $hubUrl = "$apiUrl/hub/api/rest"
    $credentialBytes = [Text.Encoding]::ASCII.GetBytes("admin:admin")
    $base64Creds = [Convert]::ToBase64String($credentialBytes)
    $headers = @{ 'Authorization' = "Basic $base64Creds"; 'Accept' = 'application/json'}
    
    $users = Invoke-RestMethod -Method Get -Uri "$hubUrl/users?fields=login,id" -Headers $headers |
                Select-Object -ExpandProperty 'users'
    $admin = $users | Where-Object {$_.login -eq 'admin'}

    $services = Invoke-RestMethod -Method Get -Uri "$hubUrl/services?fields=id,name" -Headers $headers |
                    Select-Object -ExpandProperty 'services'
    $youTrackService = $services | Where-Object {$_.name -eq 'YouTrack'}
    $youTrackAdministrationService = $services | Where-Object {$_.name -eq 'YouTrack Administration'}

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
    $script:apiToken = $token.token
}

Get-Token
Export-ModuleMember -Variable 'apiToken', 'apiUrl' -Function 'Clear-Project'