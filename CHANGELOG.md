# YouTrackAutomation Changelog

## 2.0.0

### Upgrade Instructions

* Rename usages of the `Get-YTIssue` function's `IssueId` parameter to `ID`.
* Remove usages of the `attachments.author` property on objects returned by `Get-YTIssue`. The object is returned, but
  no longer has properties. To continue to return it, pass `attachments(author(name))` to the `Get-YTIssue` function's
  `Property` parameter, in addition to any other fields you want returned.
* Rename usages of the `AdditionalField` parameter to `Property` on the following functions:
  * `Get-YTIssue`
  * `Get-YTProject`
  * `New-YTProject`
* Update usages of the `Property` (née `AdditionalField`) parameter on `Get-YTIssue`, `Get-YTProject`, and
  `New-YTPRoject` to include the exact list of all fields to return. Only fields in the list are returned. Functions now
  return objects with all properties by default, so check the return object as it may now have the properties you need.
  If not, use `Get-YTEntityField` function to construct a field list.
* Rename usages of the `Get-YTIssueCustomField` function's `CustomField` parameter to `Field`.
* Remove usages of the `Get-YTIssueCustomField` function's `Value` parameter. Each custom field type has a different
  notion of what it's value is, so this can't be generalized.
* Rename usages of the `Get-YTIssueCustomField` function's `IssueID` parameter to `Issue`. It accepts both an issue's
  ID and readable ID.
* Rename usages of the `Invoke-YRestMethod` function's `-Name` parameter to `-Resource`.
* Update usages of `Invoke-YTRestMethod` to no longer pass query strings to the `Name`/`Resource` parameter. Insted, use
  the new `Property` parameter to pass the fields you want returned, the `Top` parameter to control how many results to
  return, and `QueryParameter` to pass arbitrary query string parameters.
* Rename usages of the `New-YTIssue` function's `Project` parameter to `ProjectID`. Update usages to pass in the project
  ID instead of a project object.
* Remove usages of `Resolve-YTIssueCustomFields` and `Resolve-YTProjectId`.
* Rename usages of the `Get-YTProject` function's `ShortName` parameter to `Project`. It now accepts either a project
  short name or a project ID.
* Rename usages of the `New-YTProject` function's `Leader` parameter to `LeaderID` and update usages to pass in the
  user ID of the project's leader. Passing in the leader's login no longer works. Use `Get-YTUser` to find users by
  login name and get their user ID.

### Added

* `Invoke-YTRestMethod`:
  * `Property` parameter, which controls what properties are returned by the API (i.e. it is used as the value for the `fields` query string parameter).
  * `QueryParameter` parameter to pass arbitrary query string parameters on the request.
  * `Top` parameter, to control how many results are returned by the API.
  * Verbose messages that show the request being made to the API.
* `Remove-YTProject`: accept project objects, project IDs, or project short names from the pipeline.
* `New-YTIssue`:
  * `Parent` parameter for setting the new issue's parent. Pass the parent issue ID or readable ID.
  * `CustomField` parameter for setting custom fields when creating an issue.
* `Get-YTIssue`:
  * returns all an issue's properties two levels deep.
  * parameter `Project`, for getting issues in a specific project.
  * parameter `Summary`, for getting issues whose summary conatains a search string.
  * parameter `SubtaskOf`, for getting issues that are subtasks of a parent issue.
  * accepts issue objects, issue IDs, and/or issue readable IDs from the pipeline.
* Connect using a credential (username/password) in addition to an API key. Pass the credential instead of the API key
  to the `New-YTSession` function.
* `Get-YTIssueCustomField`:
  * Accepts field objects, field IDs, or field names from the pipeline. When piping field objects, returns full field
    properties.
  * returns all object properties on custom field when given custom field type.
* New Functions:
  * `Get-YTEntityField`for getting complete field lists for YouTrack entity, suitable for passing to YouTrack as the
    value for the `fields` query string parameter. Returns fields list for nested objects, too.
  * `Invoke-YTCommand` for calling the `commands` resource.
  * `Get-YTIssueState` function to get an issue's state.
  * `Set-YTIssueState` function to set an issue's state.
  * `Get-YTUser` function to get users.
  * `Protect-YTResourcePath` for creating a URL-safe paths to a YouTrack API resources when using input that come from
    users.
  * `Get-YTBundle` for getting bundles.

### Changed

* `Get-YTIssue`:
  * renamed `IssueId` parameter renamed to `ID`.
  * only returns two levels of object property values. It no longer returns `attachments.author.name`.
* `Get-YTIssueCustomField`: renamed the`CustomField` parameter to `Field`.
* Renamed the `AdditionalFields` parameter to `Property` on `Get-YTIssue`, `Get-YTProject`, and `New-YTProject` and
  changed the behavior to only return the fields passed in.
* `New-YTIssue` returns all object properties on the new issue, two levels deep.
* `New-YTProject` returns all object properties on the new project.
* Renamed the `Get-YTProject` function's `ShortName` parameter to `Project`. It now accepts either a project short name
  or project ID.
* Renamed the `Invoke-YTRestMethod` function's `Name` parameter to `Resource`.
* Renamed the `New-YTProject` function's `Leader` parameter to `LeaderID` and changed it to only accept user IDs. Update
  usages accordingly.

### Removed

* `Get-YTIssueCustomField`: `Value` switch. There is no common way to get a value from all the different custom fields.

## 1.1.0

* Fixed: The `Get-YTProject` function limits the amount of projects that are returned by default.

## 1.0.0

* Created these functions:
    * `Get-YTIssue`
    * `Get-YTProject`
    * `Invoke-YTRestMethod`
    * `New-YTIssue`
    * `New-YTProject`
    * `New-YTSession`