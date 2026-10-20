
function Set-YTIssueCustomField
{
    <#
    .SYNOPSIS
    Sets a single-enum custom field on a YouTrack issue.

    .DESCRIPTION
    The `Set-YTIssueCustomField` function sets a `SingleEnumIssueCustomField` custom field on one or more issues. Pass the
    issue(s) to the `IssueID` parameter (or pipe them in), the field name to the `CustomField` parameter, and the new
    value to the `Value` parameter. If the field does not exist on the issue, or the value is not valid for that field,
    the function writes an error listing the valid options and makes no change. The updated issue is returned.

    .EXAMPLE
    Set-YTIssueCustomField -Session $session -IssueID 'DEMO-20985' -CustomField 'Team' -Value 'SYSOPS'

    Demonstrates setting the `Team` custom field of issue `DEMO-20985` to `SYSOPS`.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue(s) to update, as a readable ID or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The name of the custom field to set.
        [Parameter(Mandatory)]
        [String] $CustomField,

        # The new value for the custom field.
        [Parameter(Mandatory)]
        [String] $Value
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $headers = @{
            'Accept' = 'application/json'
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $($Session.ApiToken)"
        }
    }

    process
    {
        foreach ($id in $IssueID)
        {
            $issue = Get-YTIssue -Session $Session -IssueId $id
            $projectID = $issue.project.id
            $fieldID =
                $issue.customFields |
                Where-Object { $_.name -eq $CustomField } |
                Select-Object -ExpandProperty 'id'

            if (-not $fieldID)
            {
                Write-Error -Message ("Issue '$($id)' has no custom field named '$($CustomField)'. Available fields: " +
                    "$($issue.customFields.name -join ', ').") -ErrorAction $ErrorActionPreference
                continue
            }

            $url =
                "$($Session.Url)admin/projects/$($projectID)/customFields/$($fieldID)" +
                '?fields=bundle(values(id,name),aggregatedUsers(id,name))'
            $bundle = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

            $validValues = $bundle.bundle.values
            if ($Value -notin $validValues.name)
            {
                Write-Error -Message ("'$($Value)' is not a valid value for custom field '$($CustomField)' on issue " +
                    "'$($id)'. Valid values: $($validValues.name -join ', ').") -ErrorAction $ErrorActionPreference
                continue
            }

            $body = @{
                customFields = @(
                    @{
                        name = $CustomField
                        '$type' = 'SingleEnumIssueCustomField'
                        value = @{ name = $Value }
                    }
                )
            } | ConvertTo-Json -Depth 10

            $url = "$($Session.Url)issues/$($id)?fields=customFields(id,name,value(name))"

            if (-not $PSCmdlet.ShouldProcess($id, "set '$($CustomField)' to '$($Value)'"))
            {
                continue
            }

            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body | Out-Null
            }
            catch
            {
                Write-Error -Message "Failed to set '$($CustomField)' on issue '$($id)': $($_)" `
                            -ErrorAction $ErrorActionPreference
                continue
            }

            Get-YTIssue -Session $Session -IssueId $id
        }
    }
}
