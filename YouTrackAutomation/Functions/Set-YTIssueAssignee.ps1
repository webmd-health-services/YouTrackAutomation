
function Set-YTIssueAssignee
{
    <#
    .SYNOPSIS
    Sets the Assignee of a YouTrack issue.

    .DESCRIPTION
    The `Set-YTIssueAssignee` function sets the `Assignee` custom field on one or more issues. Pass the issue(s) to the
    `IssueID` parameter (or pipe them in) and the assignee's display name to the `Assignee` parameter. If the assignee is
    not a valid user for the issue's project, the function writes an error listing the valid users and makes no change.
    The updated issue is returned.

    .EXAMPLE
    Set-YTIssueAssignee -Session $session -IssueID 'DEMO-20985' -Assignee 'Brian Freeman'

    Demonstrates assigning issue `DEMO-20985` to Brian Freeman.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The issue(s) to assign, as a readable ID or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The display name of the user to assign the issue to.
        [Parameter(Mandatory)]
        [String] $Assignee
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
                Where-Object { $_.name -eq 'Assignee' } |
                Select-Object -ExpandProperty 'id'

            if (-not $fieldID)
            {
                Write-Error -Message ("Issue '$($id)' has no Assignee field (or the issue was not found). Ensure the " +
                    'issue ID is correct.') -ErrorAction $ErrorActionPreference
                continue
            }

            $url =
                "$($Session.Url)admin/projects/$($projectID)/customFields/$($fieldID)" +
                '?fields=bundle(values(id,name),aggregatedUsers(id,name))'
            $bundle = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

            $validUsers = $bundle.bundle.aggregatedUsers
            if ($Assignee -notin $validUsers.name)
            {
                Write-Error -Message ("'$($Assignee)' is not a valid assignee for issue '$($id)'. Valid users: " +
                    "$($validUsers.name -join ', ').") -ErrorAction $ErrorActionPreference
                continue
            }

            $userID = ($validUsers | Where-Object { $_.name -eq $Assignee }).id

            $body = @{
                customFields = @(
                    @{
                        name = 'Assignee'
                        '$type' = 'SingleUserIssueCustomField'
                        value = @{ id = $userID ; '$type' = 'User' }
                    }
                )
            } | ConvertTo-Json -Depth 10

            $url = "$($Session.Url)issues/$($id)?fields=customFields(id,name,value(name))"

            if (-not $PSCmdlet.ShouldProcess($id, "assign to '$($Assignee)'"))
            {
                continue
            }

            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body | Out-Null
            }
            catch
            {
                Write-Error -Message "Failed to assign issue '$($id)': $($_)" -ErrorAction $ErrorActionPreference
                continue
            }

            Get-YTIssue -Session $Session -IssueId $id
        }
    }
}
