
function Protect-YTResourcePath
{
    <#
    .SYNOPSIS
    Creates a safe path to a YouTrack resource.

    .DESCRIPTION
    The `Protect-YTResourcePath` takes untrusted values that are part of the URL/path to a YouTrack resource, escapes
    URL-sensitive values in each path segment, then joins them together. Pass the paths to protect to the
    `UnsafeChildPath` parameter, or pipe them to `Protect-YTResourcePath`.

    If there is a known-good base path (i.e. a path that is static/constant that comes from code) pass it to the
    `SafeBasePath` parameter. It is pre-pended to the path without escaping any characters.

    .EXAMPLE
    Protect-YTResourcePath 'one',$fromUser,'two'

    Demonstrates how to create a safe path to a YouTrack API resource by passing the parts of that path to
    `Protect-YTResourcePath`. In this example, if `$fromUser` had a value of 'badd/?/&/path', `Join-CResourcePath` would
    return `badd%2F%3F%2F%26%2Fpath.

    This example also demonstrates that `UnsafeChildPath` is the default parameter, so its name can be omitted.

    .EXAMPLE
    Protect-YTResourcePath -SafeBasePath 'a/static/path/from/code' -UnsafeChildPath 'bad/?path=blarg'

    Demonstrates how to prepend a known safe base path to the unsafe paths. In this example, `Protect-YTResourcePath`
    would return `a/static/path/from/code/bad%2F%3Fpath%3Dblarg`.

    .EXAMPLE
    'unsafe','?','path' | Protect-YTResourcePath

    Demonstrates that you can pipe paths to `Protect-YTResourcePath`. In this example, `Protect-YTResourcePath` would
    return `unsafe%3Fpath`.
    #>
    [CmdletBinding()]
    param(
        # A safe base path that will be prepeneded to the path that is returned. No URL escaping is done to this path,
        # so it must come from code.
        [String] $SafeBasePath,

        # One or more paths that don't come from code (i.e. from users, files, etc.). Each path is URL-encoded, then
        # joined together with `/` character. These paths may also be piped into `Protect-YTResourcePath`.
        [Parameter(Mandatory, ValueFromPipeline, Position=0)]
        [String[]] $UnsafeChildPath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        $parts = [Collections.ArrayList]::New()
    }
    process
    {
        $parts.AddRange($UnsafeChildPath)
    }

    end
    {
        $safeFullPath = & {
            if ($SafeBasePath)
            {
                $SafeBasePath | Write-Output
            }

            $parts | ForEach-Object { [Uri]::EscapeDataString($_) }
        }

        return $safeFullPath -join '/'
    }
}