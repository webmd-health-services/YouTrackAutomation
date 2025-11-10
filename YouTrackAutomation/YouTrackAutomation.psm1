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
        @{ Name = 'values' ; Type = 'BuildBundleElement' },
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
        @{ Name = 'instances' ; Type = 'ProjectCustomField' }
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
        @{ Name = 'values' ; Type = 'EnumBundleElement' },
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
        @{ Name = 'attachments' ; Type = 'IssueAttachment' },
        @{ Name = 'comments' ; Type = 'IssueComment' },
        'commentsCount',
        'created',
        @{ Name = 'customFields' ; Type = 'IssueCustomField' },
        'description',
        @{ Name = 'draftOwner' ; Type = 'User' },
        @{ Name = 'externalIssue' ; Type = 'ExternalIssue' },
        'idReadable',
        'isDraft',
        @{ Name = 'links' ; Type = 'IssueLink' },
        'numberInProject',
        @{ Name = 'parent' ; Type = 'IssueLink' },
        @{ Name = 'pinnedComments' ; Type = 'IssueComment' },
        @{ Name = 'project' ; Type = 'Project' },
        @{ Name = 'reporter' ; Type = 'User' },
        'resolved',
        @{ Name = 'subtasks' ; Type = 'IssueLink' },
        'summary',
        @{ Name = 'tags' ; Type = 'Tag' },
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
        @{ Name = 'issue' ; Type = 'Issue';},
        @{ Name = 'comment' ; Type = 'IssueComment' },
        'thumbnailUrl'
    );
    IssueComment = @(
        'id',
        @{ Name = 'attachments' ; Type = 'IssueAttachment' },
        @{ Name = 'author' ; Type = 'User' },
        'created',
        'deleted',
        @{ Name = 'issue' ; Type = 'Issue' },
        'pinned',
        @{ Name = 'reactions' ; Type = 'Reaction' },
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
        @{ Name = 'issues' ; Type = 'Issue' }
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
        @{ Name = 'original' ; Type = 'User' },
        @{ Name = 'duplicate' ; Type = 'DuplicateVote' }
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
        @{ Name = 'issueWatchers' ; Type = 'IssueWatcher' },
        @{ Name = 'duplicateWatchers' ; Type = 'IssueWatcher' }
    );
    LocaleDescriptor = @( 'id', 'locale', 'language', 'community', 'name' );
    MultiBuildIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'BuildBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiEnumIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'EnumBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiGroupIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'UserGroup' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiOwnedIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'OwnedBundleElement' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiUserIssueCustomField = @(
        'id',
        @{ Name = 'value' ; Type = 'User' },
        'name',
        @{ Name = 'projectCustomField' ; Type = 'ProjectCustomField' }
    )
    MultiVersionIssueCustomField  = @(
        'id',
        @{ Name = 'value' ; Type = 'VersionBundleElement' },
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
        @{ Name = 'values' ; Type = 'OwnedBundleElement' },
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
        @{ Name = 'customFields' ; Type = 'ProjectCustomField' },
        'description',
        'fromEmail',
        'iconUrl',
        @{ Name = 'issues' ; Type = 'Issue' },
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
        'hasRuningJob',
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
        @{ Name = 'values' ; Type = 'StateBundleElement' },
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
        @{ Name = 'possibleEvents' ; Type = 'Event' },
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
        @{ Name = 'issues' ; Type = 'Issue' },
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
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' },
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
        @{ Name = 'tags' ; Type = 'Tag' },
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
        @{ Name = 'values' ; Type = 'VersionBundleElement' },
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
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' },
        @{ Name = 'permittedUsers' ; Type = 'User' }
    );
    WatchFolderSharingSettings = @(
        'id',
        @{ Name = 'permittedGroups' ; Type = 'UserGroup' },
        @{ Name = 'permittedUsers' ; Type = 'User' }
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
