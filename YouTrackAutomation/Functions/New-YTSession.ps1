
function New-YTSession
{
    <#
    .SYNOPSIS
    Creates a new YouTrack session object.

    .DESCRIPTION
    The New-YTSession function creates a session object required by most YouTrackAutomation functions. Pass the URL to
    YouTrack to the Url parameter and your API token to the ApiToken parameter. The URL should just be the protocol and
    hostname. The function returns an object that can be passed to all YouTrackAutomation functions' Session parameter.

    .EXAMPLE
    $session = New-YTSession -Url 'https://my-youtrack-instance.com' -ApiToken 'my-api-key'

    Demonstrates creating a YouTrack session object with the url 'https://my-youtrack-instance.com' and the API token
    'my-api-key'.
    #>
    [CmdletBinding()]
    param(
        # The URL of the YouTrack instance.
        [Parameter(Mandatory)]
        [String] $Url,

        # The API token for the YouTrack instance.
        [Parameter(Mandatory)]
        [String] $ApiToken
    )

    return [pscustomobject]@{
        Url = "$Url/api/"
        ApiToken = $ApiToken
    }
}