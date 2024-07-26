
function Invoke-YTRestMethod
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The Session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The name of the API endpoint to make a request to. This should be everything after the `/api/` in the URL.
        [Parameter(Mandatory)]
        [String] $Name,

        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method =
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Object] $Body
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $url = [uri]::EscapeUriString("$($Session.Url)${name}")
    Write-Debug "URL: $url"
    $headers = @{
        'Authorization' = "Bearer $($Session.ApiToken)"
        'Accept' = 'application/json'
    }

    if ($Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($url, $method))
    {
        Invoke-RestMethod -Uri $url -Headers $headers -ContentType 'application/json' |
            ForEach-Object { $_ } |
            Where-Object { $_ } |
            Write-Output
    }
}