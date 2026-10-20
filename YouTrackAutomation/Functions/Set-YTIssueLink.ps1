
function Set-YTIssueLink
{
    <#
    .SYNOPSIS
    Links a YouTrack issue to another issue.

    .DESCRIPTION
    The `Set-YTIssueLink` function creates a link of the given type from one or more issues to a target issue, using the
    YouTrack commands API. Pass the source issue(s) to the `IssueID` parameter (or pipe them in), the link type to the
    `LinkType` parameter, and the target issue's readable ID to the `TargetIssueId` parameter.

    .EXAMPLE
    Set-YTIssueLink -Session $session -IssueID 'DEMO-22651' -LinkType 'relates to' -TargetIssueId 'DEMO-22650'

    Demonstrates linking `DEMO-22651` to `DEMO-22650` with a "relates to" link.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The session object for a YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The source issue(s), as a readable ID or internal ID. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Name', 'idReadable')]
        [String[]] $IssueID,

        # The type of link to create.
        [Parameter(Mandatory)]
        [ValidateSet('relates to', 'is duplicated by', 'parent for', 'Issues in Epic', 'Related Epics', 'blocks',
            'causes', 'has to be done before', 'requires')]
        [String] $LinkType,

        # The readable ID of the issue to link to.
        [Parameter(Mandatory)]
        [String] $TargetIssueId
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $url = "$($Session.Url)commands"

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
            $body = @{
                query = "$($LinkType) $($TargetIssueId)"
                issues = @(
                    @{ idReadable = $id }
                )
            } | ConvertTo-Json -Depth 5

            if (-not $PSCmdlet.ShouldProcess($id, "link to '$($TargetIssueId)' ($($LinkType))"))
            {
                continue
            }

            try
            {
                Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
            }
            catch
            {
                Write-Error -Message "Failed to link issue '$($id)' to '$($TargetIssueId)': $($_)" `
                            -ErrorAction $ErrorActionPreference
            }
        }
    }
}
