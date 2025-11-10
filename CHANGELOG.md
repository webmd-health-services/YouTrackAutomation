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
* Update usages of the `Property` (nee `AdditionalField`) parameter on `Get-YTIssue`, `Get-YTProject`, and
  `New-YTPRoject` to include the exact list of all fields to return. Only fields in the list are returned. Functions now
  return objects with all properties by default, so check the return object as it may have the properties you need. If
  not, use `Get-YTEntityField` function to construct a field list.
* Rename usages of the `Get-YTIssueCustomField` function's `CustomField` parameter to `Field`.
* Rename usages of the `Get-YTIssueCustomField` function's `Value` parameter to `ValueOnly`.
* Remove usages of the `Get-YTIssueCustomField` function's `IssueID` parameter to `Issue`. It accepts both an issue's
  ID and readable ID.
* Update usages of `Invoke-YTRestMethod` to no longer pass query strings to the `Name` parameter. Insted, use the new
  `Property` parameter to pass the fields you want returned, the `Top` parameter to control how many results to return,
  and `QueryParameter` to pass arbitrary query string parameters.
* Rename usages of the `New-YTIssue` function's `Project` parameter to `ProjectID`. Update usages to pass in the project
  ID or short name instead of a project object.
* Remove usages of `Resolve-YTIssueCustomFields` and `Resolve-YTProjectId`.
* Rename usages of the `Get-YTProject` function's `ShortName` parameter to `Project`. It now accepts either a project
  short name or a project ID.

### Added

* Created `Get-YTEntityField` function to get the complete list of fields for a specific YouTrack entity, suitable for
  passing to YouTrack as the value for the `fields` query string parameter. Also optionally gets fields for nested
  objects up to five levels deep.
* `Depth` parameter to `Get-YIssue`, which controls how many levels of object properties/values to return on requested
  issue.
* `Get-YTIssue` returns all an issue's properties two levels deep.
* `Get-YTIssueCustomField` returns all an issue's custom field properties two levels deep.
* `Property` parameter to `Invoke-YTRestMethod`, which control what properties are returned by the API (i.e. it is used
  as the value for the `fields` query string parameter).
* `QueryParameter` parameter to pass arbitrary query string parameters on the request.
* `Top` parameter, to control how many results are returned by the API.
* Added verbose messages to `Invoke-YTRestMethod` that show the request being made to the API.
* `Remove-YTProject`: accept project objects, project IDs, or project short names from the pipeline.
* Function `Invoke-YTCommand` for working with the `commands` endpoint.
* `New-YTIssue` can now also link new issues as subtasks of a parent issue. Pass the parent issue ID or readable ID to
  the new `Parent` parameter.
* `Remove-YTProject`: accept project objects, project IDs, or project short names from the pipeline.
* Connect using a credential (username/password) in addition to an API key. Pass the credential instead of the API key
  to the `New-YTSession` function.
* `Get-YTIssue` parameters that search for issues:
  * `Project` searches for issues in a specific project.
  * `Summary` searches for issues whose summary matches a search string.
  * `SubtaskOf` searches for issues that are subtasks of a parent issue.
* Function `Protect-YTPath` for creating a URL-safe paths to a YouTrack API resource using values that come from users.
* Function `Get-YTBundle` for getting a YouTrack bundle.
* Pipe issue objects, issue IDs, or issue readable IDs to `Get-YTIssueCustomField`.

### Changed

* The `Get-YTIssue` function's `IssueId` parameter renamed to `ID`.
* The `Get-YTIssue` function only returns two levels of object property values. It no longer returns
  `attachments.author.name`.
* `Get-YTIssueCustomField` returns all an issue's fields by default.
* Renamed the `Get-YTIssueCustomField` function's `CustomField` parameter to `Field`.
* Renamed the `AdditionalFields` parameter to `Property` on `Get-YTIssue`, `Get-YTProject`, and `New-YTProject` and
  changed the behavior to only return the fields passed in.
* `New-YTIssue` returns all object properties on the new issue, two levels deep.
* `New-YTProject` returns all object properteis on the new project.
* Renamed the `Get-YTProject` function's `ShortName` parameter to `Project`. It now accepts either a project short name
  or project ID.
* `New-YTSession` writes an error if the URL to YouTrack includes a path. There are multiple YouTrack REST APIs with
  different paths. In order not to require a different session for each API, the path is no longer allowed and
  YouTrackAutomation manages the path to the correct API.

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