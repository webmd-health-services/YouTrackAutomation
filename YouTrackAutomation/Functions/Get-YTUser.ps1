
function Get-YTUser
{
    <#
    .SYNOPSIS
    Gets a user from YouTrack.

    .DESCRIPTION
    The `Get-YTUser` function returns a user from YouTrack. Pass the user's ID or login to the `User` parameter (you can
    also pipe user objects, user IDs, and user logins in). To get the current user's account, use the `-Me` switch.

    .EXAMPLE
    Get-YTUser -Session $session -User 'someusername'

    Demonstrates getting a user by login name.

    .EXAMPLE
    Get-YTUser -Session $session -Me

    Demonstrates getting the current user's account.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or login name of the user to return.
        [Parameter(Mandatory, ParameterSetName = 'SpecificUser', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('login')]
        [Alias('id')]
        [String] $User,

        # Gets the current user's account.
        [Parameter(Mandatory, ParameterSetName = 'Me')]
        [switch] $Me,

        # The fields to return. By default, all user fields are returned with nested objects reduced to their `id`. Use
        # `Get-YTEntityField` to build a field list that returns nested objects.
        [String[]] $Property
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $entityType = 'User'
        if ($Me -or $User -eq 'Me')
        {
            $User = 'me'
            $entityType = 'Me'
        }

        $resource = Protect-YTResourcePath -SafeBasePath 'users' -UnsafeChildPath $User

        if (-not $Property)
        {
            $Property = Get-YTEntityField -Type $entityType -Depth 2
        }

        $headers = @{
            'Accept' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }

        $queryParams = @{ fields = ($Property -join ',') }

        Invoke-RestMethod -Uri "$($Session.Url)$($resource)" -Headers $headers -Method Get -Body $queryParams
    }
}
