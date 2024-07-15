
function New-YTSession
{
    <#
    .SYNOPSIS
    Creates a new YouTrack session object.

    .DESCRIPTION
    The `New-YTSession` function creates a new YouTrack session object that can be used to interact with the YouTrack
    API. Provide the URL of the YouTrack instance and an API token to create a new session. This session contains the
    URL, the API key, and the YouTrackSharp `BearerTokenConnection` object.

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

    $connection = [YouTrackSharp.BearerTokenConnection]::new($Url, $ApiToken)

    return [pscustomobject]@{
        Connection = $connection
        Url = $Url
        ApiToken = $ApiToken
    }
}