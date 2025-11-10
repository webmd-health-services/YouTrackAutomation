
function Get-YTEntityField
{
    <#
    .SYNOPSIS
    Gets the complete fields list for a given YouTrack entity.

    .DESCRIPTION
    The `Get-YTEntityField` function gets the fields list for a given YouTrack entity and returns the list as a
    comma-delimited string. This string can be passed to the `Property` parameter on any YouTrackAutomation module
    function with that parameter. The list is sent as the value of the `fields` query string parameter when making a
    request to the YouTrack REST API.

    By default, properties of nested objects are not returned, i.e. the depth of the values returned is restricted to
    the entity itself. To return nested object values, pass the depth you'd like to the `Depth` parameter.

    Pass the entity's type name to the `Type` parameter. That entity's fields will be returned. Only the following
    entities are currently supported:

    * BuildBundle
    * BuildBundleElement
    * Bundle
    * CustomField
    * CustomFieldCondition
    * CustomFieldDefaults
    * DateFormatDescriptor
    * DuplicateVote
    * EnumBundle
    * EnumBundleElement
    * Event
    * ExternalIssue
    * FieldStyle
    * FieldType
    * GeneralUserProfile
    * Issue
    * IssueAttachment
    * IssueComment
    * IssueCustomField
    * IssueLink
    * IssueLinkType
    * IssueVoters
    * IssueWatcher
    * IssueWatchers
    * LocaleDescriptor
    * NotificationsUserProfile
    * OwnedBundle
    * OwnedBundleElement
    * PeriodFieldFormat
    * Project
    * ProjectCustomField
    * ProjectTeam
    * Reaction
    * StateBundle
    * StateBundleElement
    * Tag
    * TagSharingSettings
    * TimeTrackingUserProfile
    * TimeZoneDescriptor
    * User
    * UserGroup
    * UserProfiles
    * VersionBundle
    * VersionBundleElement
    * Visibility
    * WatchFolderSharingSettings

    .EXAMPLE
    Get-YTEntityField -Type Project

    Demonstrates how to get a field list tha will return all the Project entity's fields.

    .EXAMPLE
    Get-YTEntityField -Type Issue -Depth 2

    Demonstrates how to get a field list that will return all an issue's fields and all the fields on any nested
    objects, i.e. with a depth of 2, each custom field in the `customFields` property will have its properties
    returned.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'BuildBundle',
            'BuildBundleElement',
            'Bundle',
            'CustomField',
            'CustomFieldCondition',
            'CustomFieldDefaults',
            'DateFormatDescriptor',
            'DuplicateVote',
            'EnumBundle',
            'EnumBundleElement',
            'Event',
            'ExternalIssue',
            'FieldStyle',
            'FieldType',
            'GeneralUserProfile',
            'Issue',
            'IssueAttachment',
            'IssueComment',
            'IssueCustomField',
            'IssueLink',
            'IssueLinkType',
            'IssueVoters',
            'IssueWatcher',
            'IssueWatchers',
            'LocaleDescriptor',
            'NotificationsUserProfile',
            'OwnedBundle',
            'OwnedBundleElement',
            'PeriodFieldFormat',
            'Project',
            'ProjectCustomField',
            'ProjectTeam',
            'Reaction',
            'StateBundle',
            'StateBundleElement',
            'Tag',
            'TagSharingSettings',
            'TimeTrackingUserProfile',
            'TimeZoneDescriptor',
            'User',
            'UserGroup',
            'UserProfiles',
            'VersionBundle',
            'VersionBundleElement',
            'Visibility',
            'WatchFolderSharingSettings')]
        [String] $Type,

        # By default, only returns a field list for the entity's attributes. To retrieve more objects, pass the number
        # of levels of objects you want returned. In order to prevent overloading YouTrack with the amount of data
        # returned, this is limited to a maximum depth of 5.
        [ValidateRange(0,5)]
        [int] $Depth,

        # Internal. Do not use.
        [Parameter(DontShow)]
        [String] $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $defaultDepth = 1

    if (-not $PSBoundParameters.ContainsKey('Depth') -or $Depth -eq 0)
    {
        $Depth = $defaultDepth
    }

    $nextDepth = $Depth - 1
    $doNotRecurse = $nextDepth -le 0

    Write-Debug "${Depth} ${Name}[${Type}]"

    $properties = $script:entityAttributes[$Type]
    if (-not $script:entityAttributes.ContainsKey($Type))
    {
        Write-Warning -Message "No configured attribute list for ${Type} entity."
        $properties = @()
    }

    $properties =
        $properties |
        ForEach-Object {
            if ($_ -is [String])
            {
                return $_
            }

            $itemName = $_['Name']

            if ($doNotRecurse)
            {
                return $itemName
            }

            $itemType = $_['Type']

            Get-YTEntityField -Name $itemName -Type $itemType -Depth $nextDepth
        }

    if ($Name)
    {
        if ($Properties)
        {
            return "${Name}($($properties -join ','))"
        }

        return $Name
    }

    return $properties
}