
function Invoke-YTRestMethod
{
    <#
    .SYNOPSIS
    Invokes a REST method in YouTrack.

    .DESCRIPTION
    The `Invoke-YTRestMethod` function invokes a REST method in YouTrack using the provided session object. Pass in the
    name of the API endpoint to make the request to. By default, this function makes the HTTP request using the HTTP
    `Get` method. Use the `Method` parameter to use a different HTTP method. Provide the body of the request as a
    hashtable to the `Body` parameter.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'admin/projects'

    Demonstrates invoking the `GET` method on the `admin/projects` endpoint in YouTrack.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'admin/projects' -Method Post -Body @{
        name = 'Demo Project'
        shortName = 'DEMO'
        leader = @{id = '2-1'}
    }

    Demonstrates invoking the `POST` method on the `admin/projects` endpoint in YouTrack with a body containing the
    name, short name, and leader of the project.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the API endpoint to make a request to. This should be everything after the `/api/` in the URL.
        [Parameter(Mandatory)]
        [String] $Name,

        # The type of request method, defaults to Get.
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method =
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        # The body of the request in the form of a hashtable.
        [hashtable] $Body
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $url = "$($Session.Url)${name}"
    Write-Debug "URL: $url"
    $headers = @{
        'Authorization' = "Bearer $($Session.ApiToken)"
        'Accept' = 'application/json'
    }

    $requestParams = @{}

    if ($Body)
    {
        $requestParams['Body'] = $Body | ConvertTo-Json
        $requestParams['ContentType'] = 'application/json'
    }

    if ($Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($url, $method))
    {
        try
        {
            Invoke-RestMethod -Uri $url -Headers $headers -Method $Method @requestParams |
                ForEach-Object { $_ } |
                Where-Object { $_ } |
                Write-Output
        }
        catch
        {
            Write-Error -Message ($_.ToString() | ConvertFrom-Json | Select-Object -ExpandProperty 'error_description')
            return
        }
    }
}