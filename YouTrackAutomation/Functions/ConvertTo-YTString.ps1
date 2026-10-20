
function ConvertTo-YTString
{
    <#
    .SYNOPSIS
    Escapes text for use in YouTrack markdown/wiki fields.

    .DESCRIPTION
    The `ConvertTo-YTString` function escapes characters that are significant in YouTrack's markdown/wiki text (`\`, `[`,
    and `]`) and converts newlines to the literal `\n` sequence YouTrack expects. Pass the text to the `Text` parameter
    or pipe it in.

    .EXAMPLE
    "Line one`nLine [two]" | ConvertTo-YTString

    Demonstrates escaping brackets and converting the newline, returning `Line one\nLine \[two\]`.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        # The text to escape. Empty strings and `$null` are returned unchanged.
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [String] $Text
    )

    process
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if (-not $Text)
        {
            return $Text
        }

        $charsToEscape = @('\', '[', ']')
        $outputString = ''
        for ($i = 0; $i -lt $Text.Length; $i++)
        {
            $char = $Text[$i]
            if ($char -eq '\' -and ($i + 1 -lt $Text.Length) -and $Text[$i + 1] -eq '\')
            {
                # Collapse an existing `\\` pair into YouTrack's escaped form.
                $outputString += '\\\\\\'
                $i++
            }
            elseif ($charsToEscape -contains [String]$char)
            {
                $outputString += ('\' + $char)
            }
            else
            {
                $outputString += $char
            }
        }

        return ($outputString -replace "`r?`n", '\n')
    }
}
