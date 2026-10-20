
function ConvertTo-MarkdownTable
{
    <#
    .SYNOPSIS
    Renders objects as a GitHub-flavored Markdown table.

    .DESCRIPTION
    The `ConvertTo-MarkdownTable` function converts one or more objects into a Markdown table string. The property names
    of the first object become the table's column headers. Pass the objects to the `InputObject` parameter or pipe them
    in. Returns an empty string when there is no input.

    .EXAMPLE
    Get-YTIssue -Session $session -IssueId 'DEMO-1' | Select-Object idReadable, summary, State | ConvertTo-MarkdownTable

    Demonstrates rendering selected issue properties as a Markdown table.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # The objects to render as a table.
        [Parameter(ValueFromPipeline)]
        [Object[]] $InputObject
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $objects = [Collections.ArrayList]::new()
    }

    process
    {
        foreach ($obj in $InputObject)
        {
            if ($null -ne $obj)
            {
                [void]$objects.Add($obj)
            }
        }
    }

    end
    {
        if ($objects.Count -eq 0)
        {
            return ''
        }

        $headerNames = $objects[0].PSObject.Properties.Name

        $lines = [Collections.Generic.List[String]]::new()
        $lines.Add("| $($headerNames -join ' | ') |")
        $separator = $headerNames | ForEach-Object { '---' }
        $lines.Add("| $($separator -join ' | ') |")

        foreach ($obj in $objects)
        {
            $values = $headerNames | ForEach-Object { $obj.$_ }
            $lines.Add("| $($values -join ' | ') |")
        }

        return ($lines -join "`n")
    }
}
