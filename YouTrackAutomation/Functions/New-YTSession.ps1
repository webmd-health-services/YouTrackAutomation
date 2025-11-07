
function New-YTSession
{
    <#
    .SYNOPSIS
    Creates a new YouTrack session object.

    .DESCRIPTION
    The New-YTSession function creates a session object required by most YouTrackAutomation functions. Pass the YouTrack
    URL to the `Url` parameter and your API token to the `ApiToken` parameter. The URL should *not* include the path
    `/api/` at the end.

    To connect to YouTrack with a credential, pass the credential to the `Credential` parameter.

    .EXAMPLE
    $session = New-YTSession -Url 'https://my-youtrack-instance.com' -ApiToken 'my-api-key'

    Demonstrates creating a session that connects to the REST API at 'https://my-youtrack-instance.com/api/' using an
    API token.

    .EXAMPLE
    $session = New-YTSession -Url 'https://my-youtrack-instance.com' -Credential $me

    Demonstrates connecting to YouTrack using a credential instead of an API key.
    #>
    [CmdletBinding()]
    param(
        # The URL to the YouTrack instance's rest API, without the path `/api/` at the end.
        [Parameter(Mandatory)]
        [Uri] $Url,

        # The API token to use when connecting to YouTrack. Sent to each request to YouTrack in the "Authorization"
        # HTTP header as `Bearer ${ApiToken}`.
        [Parameter(Mandatory, ParameterSetName='ApiToken')]
        [String] $ApiToken,

        # The credential to use when connecting to YouTrack. Sent to each request to YouTrack in the "Authorization"
        # HTTP header as `Basic CREDENTIAL`, where `CREDENTIAL` is the base64-encoded username/password.
        [Parameter(Mandatory, ParameterSetName='WithCredential')]
        [pscredential] $Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not $Url.AbsolutePath.EndsWith('/'))
    {
        $Url = [Uri]"${Url}/"
    }

    return [pscustomobject]@{
        Url = $Url
        ApiToken = $ApiToken
        Credential = $Credential
    }
}