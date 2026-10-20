
function New-YTSession
{
    <#
    .SYNOPSIS
    Creates a new YouTrack session object.

    .DESCRIPTION
    The `New-YTSession` function creates a session object required by most YouTrackAutomation functions. Pass the base
    URL to the YouTrack instance (just the protocol and hostname) to the `Url` parameter and your API token to the
    `ApiToken` parameter.

    The returned object's `Url` property has the REST API path `/api/` appended to it, so the rest of the module's
    functions build resource URLs by concatenating the resource path onto `$session.Url`.

    .EXAMPLE
    $session = New-YTSession -Url 'https://my-youtrack-instance.com' -ApiToken 'my-api-key'

    Demonstrates creating a session that connects to the REST API at 'https://my-youtrack-instance.com/api/' using an
    API token.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Creates an in-memory session object only; it changes no system state.')]
    param(
        # The base URL of the YouTrack instance, e.g. `https://youtrack.example.com`. Do not include the `/api/` path;
        # it is added for you.
        [Parameter(Mandatory)]
        [String] $Url,

        # The API token to use when connecting to YouTrack. Sent on each request in the `Authorization` HTTP header as
        # `Bearer ${ApiToken}`.
        [Parameter(Mandatory)]
        [String] $ApiToken
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Url = $Url.TrimEnd('/')

    return [pscustomobject]@{
        Url = "${Url}/api/"
        ApiToken = $ApiToken
    }
}
