
function Get-YTUser
{
    <#
    .SYNOPSIS
    Gets a user.

    .DESCRIPTION
    The `Get-YTUser` function returns a user from YouTrack. Pass the user's ID or login to the `User` property (you can
    also pipe multiple user objects, user IDs, and user logins to `Get-YTUser`). Returns a [User
    entity](https://www.jetbrains.com/help/youtrack/devportal/api-entity-User.html) with all properties.

    To get the current user's account, use the `-Me` switch.

    .EXAMPLE
    Get-YTUser -Session $script:session -User 'someusername'

    Demonstrates getting a user by its login name.

    .EXAMPLE
    Get-YTUser -Session $script:session -User '2-1'

    Demonstrates getting a user by its id.

    .EXAMPLE
    $user, 'someusername', '2-1' | Get-YTUser -Session $script:session

    Demonstrates getting multiple users by piping user objects, user logins, and/or user IDs to `Get-YTUser`.
    #>
    [CmdletBinding()]
    param(
        # The session object for a YouTrack session. Create a new Session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The ID or login name of the user to return.
        [Parameter(Mandatory, ParameterSetName='SpecificUser', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('login')]
        [Alias('id')]
        [String] $User,

        # Gets the current user's account.
        [Parameter(Mandatory, ParameterSetName='Me')]
        [switch] $Me,

        # The properties/attributes to return. By default, all user properties are returned, Nested objects will not
        # have any properties. Use `Get-YTEntityField` to create a property list that will return nested objects.
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

        return Invoke-YTRestMethod -Session $Session -Resource $resource -Property $Property
    }
}