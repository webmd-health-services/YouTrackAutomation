
function Get-YTEntityField
{
    <#
    .SYNOPSIS
    Gets a fields list for a YouTrack entity.

    .DESCRIPTION
    The `Get-YTEntityField` function gets a list of a YouTrack entity's fields/properties/attributes as an array of
    strings. Pass the entity's type name to the `Type` parameter. If an entity has nested objects, only the object's
    `id` property is returned. If an entity has fields whose values are arrays, those properties are omitted as an
    optimization: when requesting a field that is an array, YouTrack reads all the array's elements.

    The field list can be sent to any API endpoint's `fields` query parameter, by joining the fields list with a `,`
    character:

        $fields = Get-YTEntityField -Type 'User'
        $resourcePath = "users/me?fields=$([Uri]::EscapeDataString($fields -join ','))"

    Many of YouTrackAutomation module's function have a `Property` parameter that manages sending the `fields` query
    parameter for you:

        $fields = Get-YTEntityField -Type 'Issue'
        Get-YTIssue -Session $session -Issue 'DEMO-4' -Property $fields
        Invoke-YTRestMethod -Session $session -Name 'resource/endpoint' -Property $fields

    If you want nested object properties and arrays present, use the `Depth` parameter to control how deep you want
    objects. The default depth is 1. Objects at the deepest level will never return array properties and any object
    properties will ony have `id` properties.

    YouTrack's entities contain circular references. In order to avoid creating an infinite field list, once a field
    with a given type is in the field list, that field type will be omitted from descendants.

    The following entities are currently supported:

    * BuildBundle
    * BuildBundleElement
    * Bundle
    * CustomField
    * CustomFieldCondition
    * CustomFieldDefaults
    * DateFormatDescriptor
    * DateIssueCustomField
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
    * MultiBuildIssueCustomField
    * MultiEnumIssueCustomField
    * MultiGroupIssueCustomField
    * MultiOwnedIssueCustomField
    * MultiUserIssueCustomField
    * MultiVersionIssueCustomField
    * NotificationsUserProfile
    * OwnedBundle
    * OwnedBundleElement
    * PeriodFieldFormat
    * PeriodIssueCustomField
    * PeriodValue
    * Project
    * ProjectCustomField
    * ProjectTeam
    * Reaction
    * SimpleIssueCustomField
    * SingleBuildIssueCustomField
    * SingleEnumIssueCustomField
    * SingleGroupIssueCustomField
    * SingleOwnedIssueCustomField
    * SingleUserIssueCustomField
    * SingleVersionIssueCustomField
    * StateBundle
    * StateBundleElement
    * StateIssueCustomField
    * StateMachineIssueCustomField
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

    Demonstrates how to get a field list that will return all the Project entity's fields.

    .EXAMPLE
    Get-YTEntityField -Type Issue -Depth 2

    Demonstrates how to get a field list that will return all an issue's fields and all the fields on any nested
    objects, i.e. with a depth of 2, each custom field in the `customFields` property will have its properties returned.
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
            'DateIssueCustomField',
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
            'Me',
            'MultiBuildIssueCustomField',
            'MultiEnumIssueCustomField',
            'MultiGroupIssueCustomField',
            'MultiOwnedIssueCustomField',
            'MultiUserIssueCustomField',
            'MultiVersionIssueCustomField',
            'NotificationsUserProfile',
            'OwnedBundle',
            'OwnedBundleElement',
            'PeriodFieldFormat',
            'PeriodIssueCustomField',
            'PeriodValue',
            'Project',
            'ProjectCustomField',
            'ProjectTeam',
            'Reaction',
            'SavedQuery',
            'SimpleIssueCustomField',
            'SingleBuildIssueCustomField',
            'SingleEnumIssueCustomField',
            'SingleGroupIssueCustomField',
            'SingleOwnedIssueCustomField',
            'SingleUserIssueCustomField',
            'SingleVersionIssueCustomField',
            'StateBundle',
            'StateBundleElement',
            'StateIssueCustomField',
            'StateMachineIssueCustomField',
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
        # of levels of objects you want returned. In order to avoid infinite recursion of properties, once an object
        # of a specific type is in the property list, none of its descendants will include that properties of that type.
        [int] $Depth
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Get-EntityField
    {
        param(
            [String] $Type,

            [String] $Name,

            [int] $CurrentDepth,

            [String[]] $Parent
        )

        $doNotRecurse = $CurrentDepth -ge $Depth

        Write-Debug "${CurrentDepth}$(' ' * $CurrentDepth) ${Name}[${Type}]"

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

                $fieldName = $_['Name']

                if ($doNotRecurse)
                {
                    $isArray = $_['IsArray']

                    # Arrays can be *very* expensive because YouTrack retrieves every element in the array even if none
                    # of its properties are returned.
                    if ($isArray)
                    {
                        return
                    }

                    # Return the ID of all nested objects to users don't have to make another request to get it.
                    return "${fieldName}(id)"
                }

                $fieldType = $_['Type']

                # Avoid infinite recursion.
                if ($fieldType -in $Parent)
                {
                    return
                }

                Get-EntityField -Name $fieldName `
                                -Type $fieldType `
                                -CurrentDepth ($CurrentDepth + 1) `
                                -Parent ($Parent + $Type)
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

    $defaultDepth = 1

    if (-not $PSBoundParameters.ContainsKey('Depth') -or $Depth -eq 0)
    {
        $Depth = $defaultDepth
    }

    return Get-EntityField -Type $Type -CurrentDepth 1
}