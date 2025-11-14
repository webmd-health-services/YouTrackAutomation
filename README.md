# Overview

The "YouTrackAutomation" module is a PowerShell module built to interface with the YouTrack REST API.

# System Requirements

* Windows PowerShell 5.1
* PowerShell 7+

# Installing

To install globally:

```powershell
Install-Module -Name 'YouTrackAutomation'
Import-Module -Name 'YouTrackAutomation'
```

To install privately:

```powershell
Save-Module -Name 'YouTrackAutomation' -Path '.'
Import-Module -Name '.\YouTrackAutomation'
```

# How-to

## Creating a new session

Create a session to the instance of YouTrack you want to connect to with `New-YTSession`. Pass the base URL (i.e. no
path) to the `Url` parametter. Pass the API key to use to the `ApiKey` parameter or a credential to the `Credential`
parameter:

```powershell
# To connect with an API key:
$session = New-YTSession -Url 'https://youtrack.example.com' -ApiKey $apiKey

# To connect with a username/password:
$session = New-YTSession -Url 'https://youtrack.example.com' -Credential $credential
```

Be careful using a credential. Your username and password are sent to YouTrack in the clear.

## Making Requests

Use `Invoke-YTRestMethod` to make requests. Pass the path to the resource to the `Resource` parameter.
`Invoke-YTRestMethod` adds the REST API base path, `/api/`, to the request.

```powershell
Invoke-YTRestMethod -Session $session -Resource 'users/me'
```

If you need to create something, use the `Method` parameter to change the method, and pass the body of the request as
a hashtable to the `Body` parameter:

```powershell
$issue = @{
  summary = 'My new issue.'
  project = @{
    id = 'EXAMPLE'
  }
  Invoke-YTRestMethod -Session $session -Resource 'issues' -Method Post -Body $body
}
```

[The Invoke-YTRestMethod documentation has more details.](YouTrackAutomation/Functions/Invoke-YTRestMethod.ps1)

Before using `Invoke-YTRestMethod`, check if there is already a function that works with a specific resource or
entity:

* [Get-YTBundle](YouTrackAutomation/Functions/Get-YTBundle.ps1): gets bundle with the
  `admin/customFieldSettings/bundles` resource.
* [Get-YTIssue](YouTrackAutomation/Functions/Get-YTIssue.ps1): get issues with the `issues` resource.
* [Get-YTIssueCustomField](YouTrackAutomation/Functions/Get-YTIssueCustomField.ps1): gets an issue's custom fields with
  the `issues/{issueId}/customFields` resource.
* [Get-YTIssueState](YouTrackAutomation/Functions/Get-YTIssueState.ps1): gets an issue's State custom field with the
  `issues/{issueId}/customFields/State` resource.
* [Get-YTProject](YouTrackAutomation/Functions/Get-YTProject.ps1): gets projects with the `admin/projects` resource.
* [Get-YTUser](YouTrackAutomation/Functions/Get-YTUser.ps1): gets users with the `users` resource.
* [Invoke-YTCommand](YouTrackAutomation/Functions/Invoke-YTCommand.ps1): makes request to the `commands` resource.
* [New-YTIssue](YouTrackAutomation/Functions/New-YTIssue.ps1): creates an issue with the `issues` resource, including
  settting an issue's parent issue and setting custom fields.
* [New-YTProject](YouTrackAutomation/Functions/New-YTProject.ps1): creates projects with the `admin/projects` resource.
* [Remove-YTProject](YouTrackAutomation/Functions/Remove-YTProject.ps1): removes projects with the `admin/projects`
  resource.
* [Set-YTIssueState](YouTrackAutomation/Functions/Set-YTIssueState.ps1): changes an issue's state with the
  `issues/{issueId}/fields/State` resource. Handles both simple states and state-machines.

## Returning Properties/Attributes/Fields on Objects

To control what properties/attributes/fields to return on objects, pass the fields list ([a string of comma-separated
field names](https://www.jetbrains.com/help/youtrack/devportal/api-fields-syntax.html)) to the `Invoke-YTRestMethod`
function's `Property` parameter.

By default, when you send an object to YouTrack, the YouTrackAutomation module will also send a fields list in the same
request that matches the fields from the object you're sending. You can customize what fields you want returned by
passing the list to the `Invoke-YTRestMethod` function's `Property` parameter or the `Property` parameter, if present,
on many other YouTrackAutomation functions.

YouTrackAutomation knows about many of YouTrack's entities and their properties and has a `Get-YTEntityField` function
that will create a fields list for you. Pass it the entity type name:

```powershell
$properties = Get-YTEntityField -Type 'User'
# The above command returns this fields list as a PowerShell array:
#   id,login,fullName,email,ringId,guest,online,banned,avatarUrl,userProfiles(id)
Invoke-YTRestMethod -Session $session -Resource 'users/me' -Property $properties
```
By default, it returns a fields list that will return all that entity's properties/attributes/fields, with the following
caveats:

* any property that is an array of objects is omitted and not returned because when you request a property that is an
  array, YouTrack reads every item that would be returned in that array. This can be expensive.
* any property that is an object only returns that object's `id` property.

If you want to get nested object properties, use the `Get-YTEntityField` function's `Depth` parameter to specify how
many levels deep you want:

```powershell
$properties = Get-YTEntityField -Type 'User' -Depth 2
# The above command returns this fields list as a PowerShell array (line breaks added for readability):
#   id,login,fullName,email,ringId,guest,online,banned,
#   tags(id,color(id),untagOnResolve,visibleFor(id),updateableBy(id),readShareSettings(id),tagSharingSettings(id),updateSharingSettings(id),owner(id),name),
#   savedQueries(id,query,visibleFor(id),updateableBy(id),readSharingSetings(id),updateSharingSettings(id),owner(id),name),
#   avatarUrl,userProfiles(id,general(id),notifications(id),timeTracking(id))
Invoke-YTRestMethod -Session $session -Resource 'users/me' -Property $properties
```

When requesting multiple levels of objects, the bottom-level objects will not have array properties, and their object
properties will only have the `id` property. Also, because YouTrack entities can be recursive, the `Get-YTEntityField`
will omit a child property if its type is the same as any parent object.

[The Get-YTEntityField documentation has more details.](YouTrackAutomation/Functions/Get-YTEntityField.ps1)

## URL Encoding API Resource Paths

When using untrusted values in API resource paths, make sure those values get URL-encoded to prevent malicious users
from changing the URL. Use the [Protect-YTResourcePath](YouTrackAutomation/Functions/Protect-YTResourcePath.ps1)
function whenever constructing a resource path that contains input from users.

## Using the Hub API

YouTrackAutomation doesn't yet have native support for YouTrack's Hub API, but you can use it by creating a dedicated
session to the Hub service and using Invoke-YTRestMethod to make requests. When creating the session, pass the Hub
service URL to the `Url` parameter. When making calls to Hub resources, prepend `rest/` to each resource path:

```powershell
$hubSession = New-YTSession -Url 'https://youtrack.internetbrands.com/hub/' -ApiToken $apitoken
Invoke-YTRestMethod -Session $hubSession -Resource 'rest/users'
```
