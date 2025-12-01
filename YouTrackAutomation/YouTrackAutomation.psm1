# Copyright WebMD Health Services
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

# Functions should use $moduleDirPath as the relative root from which to find
# things. A published module has its function appended to this file, while a
# module in development has its functions in the Functions directory.
$script:moduleDirPath = $PSScriptRoot

$script:defaultIssueFieldDepth = 2

# Attributes/properties for all [entitities](https://www.jetbrains.com/help/youtrack/devportal/api-entities.html) known
# to be returned by functions in the module.Use by Get-YTEntityField to construct field query param values. If
# you add a new entity, update the Get-YTEntityField tests.
$script:entityAttributes = @{
    BuildBundle = @(
        'id',
        @{ Name = 'values' ; Type = 'BuildBundleElement' ; IsArray = $true },
        'isUpdateable'
    )
    BuildBundleElement = @(
        'id',
        'assembleDate',
        'name',
        @{ Name = 'bundle' ; Type = 'BuildBundle' },
        'description',
        'archived',
        'ordininal',
        @{ Name = 'color' ; Type = 'FieldStyle' },
        'hasRunningJob'
    )
    Bundle = @(
        'id',
        # Bundle type not known ahead of time, so get all properties common to all bundle types.
        'values(id,name,description,archived,ordinal,color(id,background,foreground),hasRunningJob)',
        'isUpdateable'
    )
    CustomField = @(
        'id',
        'name',
        'localizedName',
        @{ Name = 'fieldType' ; Type = 'FieldType' },
        'isAutoAttached',
        'isDisplayedInIssueList',
        'ordinal',
        'aliases',
        @{ Name = 'fieldDefaults' ; Type = 'CustomFieldDefaults' },
        'hasRunningJob',
        'isUpdateable',
        @{ Name = 'instances' ; Type = 'ProjectCustomField' ; IsArray = $true }
    );
    CustomFieldCondition = @(
        'id',
        @{ Name = 'parent' ; Type = 'ProjectCustomField' }
    );
    CustomFieldDefaults = @(
        'id',
        'canBeEmpty',
        'emptyFieldText',
        'isPublic',
        @{ Name = 'parent' ; Type = 'CustomField' }
    );
    DateFormatDescriptor = @( 'id', 'presentation', 'pattern', 'datePattern' );
    DateIssueCustomField  = @(
        'id',
        'value',
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    DuplicateVote = @(
        'id',
        @{ Name = 'issue' ; Type = 'Issue' },
        @{ Name = 'user' ; Type = 'User' }
    );
    EnumBundle = @(
        'id',
        @{ Name = 'values' ; Type = 'EnumBundleElement' ; IsArray = $true },
        'isUpdateable'
    )
    EnumBundleElement = @(
        'id',
        'localizedName',
        'name',
        @{ Name = 'bundle' ; Type = 'EnumBundle' },
        'description',
        'archived',
        'ordinal',
        @{ Name = 'color'; Type = 'FieldStyle' },
        'hasRunningJob'
    )
    Event = @( 'id', 'presentation' )
    ExternalIssue = @( 'id', 'name', 'url', 'key');
    FieldType = @( 'id' );
    FieldStyle = @( 'id', 'background', 'foreground' );
    GeneralUserProfile = @(
        'id',
        @{ Name = 'dateFieldFormat' ; Type = 'DateFormatDescriptor' },
        @{ Name = 'timezone' ; Type = 'TimeZoneDescriptor' },
        @{ Name = 'locale' ; Type = 'LocaleDescriptor' }
    );
    Issue = @(
        'id',
        @{ Name = 'attachments' ; Type = 'IssueAttachment' ; IsArray = $true },
        @{ Name = 'comments' ; Type = 'IssueComment' ; IsArray = $true },
        'commentsCount',
        'created',
        @{ Name = 'customFields' ; Type = 'IssueCustomField' ; IsArray = $true },
        'description',
        @{ Name = 'draftOwner' ; Type = 'User' },
        @{ Name = 'externalIssue' ; Type = 'ExternalIssue' },
        'idReadable',
        'isDraft',
        @{ Name = 'links' ; Type = 'IssueLink' ; IsArray = $true },
        'numberInProject',
        @{ Name = 'parent' ; Type = 'IssueLink' },
        @{ Name = 'pinnedComments' ; Type = 'IssueComment' ; IsArray = $true },
        @{ Name = 'project' ; Type = 'Project' },
        @{ Name = 'reporter' ; Type = 'User' },
        'resolved',
        @{ Name = 'subtasks' ; Type = 'IssueLink' },
        'summary',
        @{ Name = 'tags' ; Type = 'Tag' ; IsArray = $true },
        'updated',
        @{ Name = 'updater' ; Type = 'User' },
        @{ Name = 'visibility' ; Type = 'Visibility' },
        @{ Name = 'voters' ; Type = 'IssueVoters' },
        'votes',
        @{ Name = 'watchers' ; Type = 'IssueWatchers' },
        'wikifiedDescription'
    );
    IssueAttachment = @(
        'id',
        'name',
        @{ Name = 'author' ; Type = 'User' },
        'created',
        'updated',
        'size',
        'extension',
        'charset',
        'mimeType',
        'metadata',
        'draft',
        'removed',
        'base64Content',
        'url',
        @{ Name = 'visibility' ; Type = 'Visibility' },
        @{ Name = 'issue' ; Type = 'Issue' },
        @{ Name = 'comment' ; Type = 'IssueComment' },
        'thumbnailUrl'
    );
    IssueComment = @(
        'id',
        @{ Name = 'attachments' ; Type = 'IssueAttachment' ; IsArray = $true },
        @{ Name = 'author' ; Type = 'User' },
        'created',
        'deleted',
        @{ Name = 'issue' ; Type = 'Issue' },
        'pinned',
        @{ Name = 'reactions' ; Type = 'Reaction' ; IsArray = $true },
        'text',
        'textPreview',
        'updated',
        @{ Name = 'visibility' ; Type = 'Visibility' }
    );
    IssueCustomField = @(
        'id',
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' },
        # Only field shared by all custom fields.
        'value(id)'
    );
    IssueLink = @(
        'id',
        'direction',
        @{ Name = 'linkType' ; Type = 'IssueLinkType' },
        @{ Name = 'issues' ; Type = 'Issue' ; IsArray = $true }
    );
    IssueLinkType = @(
        'id',
        'name',
        'localizedName',
        'sourceToTarget',
        'localizedSourceToTarget',
        'targetToSource',
        'localizedTargetToSource',
        'directed',
        'aggregation',
        'readOnly'
    );
    IssueVoters = @(
        'id',
        'hasVote',
        @{ Name = 'original' ; Type = 'User' ; IsArray = $true },
        @{ Name = 'duplicate' ; Type = 'DuplicateVote' ; IsArray = $true }
    );
    IssueWatcher = @(
        'id',
        @{ Name = 'user' ; Type = 'User' },
        @{ Name = 'issue' ; Type = 'Issue' },
        'isStarred'
    );
    IssueWatchers = @(
        'id',
        'hasStar',
        @{ Name = 'issueWatchers' ; Type = 'IssueWatcher' ; IsArray = $true },
        @{ Name = 'duplicateWatchers' ; Type = 'IssueWatcher' ; IsArray = $true }
    );
    LocaleDescriptor = @( 'id', 'locale', 'language', 'community', 'name' );
    Me = @(
        'id',
        'login',
        'fullName',
        'email',
        'ringId',
        'guest',
        'online',
        'banned',
        @{ Name = 'tags' ; Type = 'Tag' ; IsArray = $true },
        @{ Name = 'savedQueries' ; Type = 'SavedQuery' ; IsArray = $true },
        'avatarUrl',
        @{ Name = 'userProfiles' ; Type = 'UserProfiles' }
    )
    MultiBuildIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'BuildBundleElement' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiEnumIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'EnumBundleElement' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiGroupIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'UserGroup' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiOwnedIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'OwnedBundleElement' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiUserIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'User' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiVersionIssueCustomField  = @(
        'id',
        @{ Name = 'value' ; Type = 'VersionBundleElement' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    NotificationsUserProfile = @(
        'id',
        'notifyOnOwnChanges',
        'emailNotificationsEnabled',
        'mentionNotificationsEnabled',
        'duplicateClusterNotificationsEnabled',
        'mailboxIntegrationNotificationsEnabled',
        'usePlainTextEmails',
        'autoWatchOnComment',
        'autoWatchOnCreate',
        'autoWatchOnVote',
        'autoWatchOnUpdate'
    );
    OwnedBundle = @(
        'id',
        @{ Name = 'values' ; Type = 'OwnedBundleElement' ; IsArray = $true },
        'isUpdateable'
    )
    OwnedBundleElement = @(
        'id',
        @{ Name = 'owner' ; Type = 'User' },
        'name',
        @{ Name = 'bundle' ; Type = 'OwnedBundle' },
        'description',
        'archived',
        'ordinal',
        @{ Name = 'color'; Type = 'FieldStyle' },
        'hasRunningJob'
    )
    PeriodFieldFormat = @( 'id' );
    PeriodIssueCustomField  = @(
        'id',
        @{ Name = 'value' ; Type = 'PeriodValue' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    PeriodValue = @( 'id', 'minutes', 'presentation' )
    Project = @(
        'id',
        'archived',
        'createdBy',
        @{ Name = 'customFields' ; Type = 'ProjectCustomField' ; IsArray = $true },
        'description',
        'fromEmail',
        'iconUrl',
        @{ Name = 'issues' ; Type = 'Issue' ; IsArray = $true },
        @{ Name = 'leader' ; Type = 'User' },
        'name',
        'replyToEmail',
        'shortName',
        @{ Name = 'team' ; Type = 'ProjectTeam' },
        'template'
    );
    ProjectCustomField = @(
        'id',
        @{ Name = 'field' ; Type = 'CustomField' },
        @{ Name = 'project' ; Type = 'Project' },
        'canBeEmpty',
        'emptyTextField',
        'ordinal',
        'isPublic',
        'hasRunningJob',
        @{ Name = 'condition' ; Type = 'CustomFieldCondition' }
    );
    ProjectTeam = @(
        @{ Name = 'project' ; Type = 'Project' },
        'id',
        'name',
        'ringId',
        'usersCount',
        'allUsersGroup',
        @{ Name = 'teamForProject' ; Type = 'Project' }
    );
    Reaction = @(
        'id',
        @{ Name = 'author' ; Type = 'User' },
        'reaction'
    );
    SavedQuery = @(
        'id',
        'query',
        @{ Name = 'issues' ; Type = 'Issue' ; IsArray = $true },
        @{ Name = 'visibleFor' ; Type = 'UserGroup' },
        @{ Name = 'updateableBy' ; Type = 'UserGroup' },
        @{ Name = 'readSharingSetings' ; Type = 'WatchFolderSharingSettings' },
        @{ Name = 'updateSharingSettings' ; Type = 'WatchFolderSharingSettings' },
        @{ Name = 'owner' ; Type = 'User' },
        'name'
    )
    SimpleIssueCustomField  = @(
        'id',
        'value',
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleBuildIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'BuildBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleEnumIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'EnumBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleGroupIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'UserGroup' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleOwnedIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'OwnedBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleUserIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'User' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    SingleVersionIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'VersionBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    StateBundle = @(
        'id',
        @{ Name = 'values' ; Type = 'StateBundleElement' ; IsArray = $true },
        'isUpdateable'
    )
    StateBundleElement = @(
        'id',
        'isResolved',
        'localizedName',
        'name',
        @{ Name = 'bundle' ; Type = 'StateBundle' },
        'description',
        'archived',
        'ordinal',
        @{ Name = 'color'; Type = 'FieldStyle' },
        'hasRunningJob'
    )
    StateMachineIssueCustomField = @(
        'id',
        # Value can be bundles, user, or user group. They only have `id` field in common. :(
        'value(id)',
        @{ Name = 'event' ; Type = 'Event' },
        @{ Name = 'possibleEvents' ; Type = 'Event' ; IsArray = $true },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    StateIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'StateBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    Tag = @(
        'id',
        @{ Name = 'issues' ; Type = 'Issue' ; IsArray = $true },
        @{ Name = 'color' ; Type = 'FieldStyle' },
        'untagOnResolve',
        @{ Name = 'visibleFor' ; Type = 'UserGroup' },
        @{ Name = 'updateableBy' ; Type = 'UserGroup' },
        @{ Name = 'readShareSettings' ; Type = 'WatchFolderSharingSettings' },
        @{ Name = 'tagSharingSettings' ; Type = 'TagSharingSettings' },
        @{ Name = 'updateSharingSettings' ; Type = 'WatchFolderSharingSettings' },
        @{ Name = 'owner' ; Type = 'User' },
        'name'
    );
    TagSharingSettings = @(
        'id',
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' ; IsArray = $true },
        @{ Name = 'permittedUsers' ; Type = 'User' }
    );
    TimeTrackingUserProfile = @(
        'id',
        @{ Name = 'periodFormat' ; Type = 'PeriodFieldFormat' }
    );
    TimeZoneDescriptor = @( 'id', 'presentation', 'offset' );
    User = @(
        'id',
        'login',
        'fullName',
        'email',
        'ringId',
        'guest',
        'online',
        'banned',
        @{ Name = 'tags' ; Type = 'Tag' ; IsArray = $true },
        @{ Name = 'savedQueries' ; Type = 'SavedQuery' ; IsArray = $true },
        'avatarUrl',
        @{ Name = 'userProfiles' ; Type = 'UserProfiles' }
    );
    UserGroup = @(
        'id',
        'name',
        'ringId',
        'usersCount',
        'icon',
        'allUsersGroup',
        @{ Name = 'teamForProject' ; Type = 'Project' }
    );
    UserProfiles = @(
        'id',
        @{ Name = 'general' ; Type = 'GeneralUserProfile' },
        @{ Name = 'notifications' ; Type = 'NotificationsUserProfile' },
        @{ Name = 'timeTracking' ; Type = 'TimeTrackingUserProfile' }
    );
    VersionBundle = @(
        'id',
        @{ Name = 'values' ; Type = 'VersionBundleElement' ; IsArray = $true },
        'isUpdateable'
    )
    VersionBundleElement = @(
        'id',
        'released',
        'releaseDate',
        'startDate',
        'name',
        @{ Name = 'bundle' ; Type = 'VersionBundle' },
        'description',
        'archived',
        'ordinal',
        @{ Name = 'color'; Type = 'FieldStyle' },
        'hasRunningJob'
    )
    Visibility = @(
        'id',
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' ; IsArray = $true },
        @{ Name = 'permittedUsers' ; Type = 'User' ; IsArray = $true }
    );
    WatchFolderSharingSettings = @(
        'id',
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' ; IsArray = $true },
        @{ Name = 'permittedUsers' ; Type = 'User' ; IsArray = $true }
    )
}

# Store each of your module's functions in its own file in the Functions
# directory. On the build server, your module's functions will be appended to
# this file, so only dot-source files that exist on the file system. This allows
# developers to work on a module without having to build it first. Grab all the
# functions that are in their own files.
$functionsPath = Join-Path -Path $script:moduleDirPath -ChildPath 'Functions\*.ps1'
if( (Test-Path -Path $functionsPath) )
{
    foreach( $functionPath in (Get-Item $functionsPath) )
    {
        . $functionPath.FullName
    }
}
