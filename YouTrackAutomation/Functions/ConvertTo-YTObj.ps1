
function ConvertTo-YTObj
{
    <#
    .SYNOPSIS
    Flattens an issue's custom fields onto the issue object.

    .DESCRIPTION
    The `ConvertTo-YTObj` function takes an issue object returned by the YouTrack API and copies each of its custom
    fields up onto the object as a top-level note property, so a custom field such as `State` is reachable as
    `$issue.State` instead of digging through the `customFields` collection. The original `customFields` property is left
    in place.

    The returned object is given the `WHS.YTIssue.Object` type name, which has a default display property set of
    `idReadable`, `summary`, `State`, `Description`, and `Assignee`.

    .EXAMPLE
    $issue = Invoke-RestMethod -Uri $url -Headers $headers | ConvertTo-YTObj

    Demonstrates flattening an issue's custom fields onto the returned object.
    #>
    [CmdletBinding()]
    param(
        # The issue object to flatten.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [Object] $YTIssue
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if (-not (Get-TypeData -TypeName 'WHS.YTIssue.Object'))
        {
            Update-TypeData -TypeName 'WHS.YTIssue.Object' `
                            -DefaultDisplayPropertySet 'idReadable', 'summary', 'State', 'Description', 'Assignee'
        }
    }

    process
    {
        if (-not $YTIssue)
        {
            return
        }

        $flattened = $YTIssue.PSObject.Copy()

        $customFieldsProp = $YTIssue.PSObject.Properties['customFields']
        if ($customFieldsProp -and $customFieldsProp.Value)
        {
            foreach ($field in $customFieldsProp.Value)
            {
                $value = $null
                $valueProp = $field.PSObject.Properties['value']
                if ($valueProp -and $null -ne $valueProp.Value)
                {
                    $fieldValue = $valueProp.Value
                    if ($fieldValue.PSObject.Properties['name'])
                    {
                        $value = $fieldValue.name
                    }
                    else
                    {
                        $value = $fieldValue
                    }
                }

                $flattened | Add-Member -NotePropertyName $field.name -NotePropertyValue $value -Force
            }
        }

        $flattened.PSObject.TypeNames.Insert(0, 'WHS.YTIssue.Object')
        return $flattened
    }
}
