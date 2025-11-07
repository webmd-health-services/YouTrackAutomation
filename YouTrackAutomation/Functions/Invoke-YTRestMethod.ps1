
function Invoke-YTRestMethod
{
    <#
    .SYNOPSIS
    Invokes a REST method in YouTrack.

    .DESCRIPTION
    The `Invoke-YTRestMethod` function call a YouTrack REST API resource. Pass the YouTrack session to the `Session`
    parameter. Pass the resource's path to the `Name` parameter. Makes a GET request to the `/api/${Name}` resource.

    Use the `Method` parameter to make a different HTTP request. If the request requires a body, pass the body as a
    hashtable to the `Body` parameter. The parameter is converted to JSON and sent as the body of the request. When
    passing a body, all its properties are included in the `fields` query string parameter so the response includes the
    same attributes as the request. For example, if sending this object to YouTrack:

        @{
            prop1 = 'value1';
            prop2 = @{
                id = 'id2';
            }
        }

    Then the `fields` query string parameter would be `prop,prop2(id)`.

    Use the `Property` parameter to control the attributes in the response from YouTrack. This parameter is passed as
    the `fields` query string parameter value. If both the `Body` and `Property` parameters have values, the list from
    `Property` takes precedence (i.e. it is appended to the `fields` value). YouTrackAutomation knows about many of
    YouTrack's entities, there attributes, and their relationship to each other. Use `Get-YTEntityField` to create a
    list by entity type.

    To send custom query string parameters, pass them as a hashtable to the `QueryParameter` parameter.

    To control how many objects YouTrack returns, use the `$Top` parameter.

    To see the request made to YouTrack, use the `-Verbose` switch.

    Supports `-WhatIf`. When `-WhatIf` is used, `Invoke-YTRestMethod` only makes GET requests to the YouTrack API.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'admin/projects'

    Demonstrates invoking the `GET` method on the `admin/projects` resource.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'admin/projects' -Method Post -Body @{ name = 'Demo Project' ; shortName = 'DEMO' ; leader = @{id = '2-1'} }

    Demonstrates invoking the `POST` method on the `admin/projects` resource to create a project named "Demo Project",
    short name "DEMO", and leader set to the user who's ID is "2-1". The request sets the `fields` query string
    parameter to `name,shortName,leader(id)` to get the same object and attribute structure back from YouTrack.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'issues/DEMO-1' -Property 'id,summary'

    Demonstrates how to customize the attributes received in the response from YouTrack.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'issues/DEMO-1' -Property (Get-YTEntityField -Type 'Issue')

    Demonstrates how to use `Get-YTEntityField` to create a list of attributes to receive in the response from YouTrack.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'admin/projects' -QueryParameter @{ template = 'scrum' } -Body @{ name = 'Demo Project' ; shortName = 'DEMO' ; leader = @{id = '2-1'} } -Method Post

    Demonstrates how to use `QueryParameter` to send query string parameters as part of the request. In this example,
    `template=scrum` will be send in the query string.

    .EXAMPLE
    Invoke-YTRestMethod -Session $session -Name 'issues' -Top 20

    Demonstrates how to use the `Top` parameter to control how many elements/objects are returned by YouTrack. This adds
    `$top=20` the the request's query string.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The YouTrack session. Create a new session using `New-YTSession`.
        [Parameter(Mandatory)]
        [Object] $Session,

        # The API resource to make a request to. This should be everything after the `/api/` in the resource's full URL.
        [Parameter(Mandatory)]
        [String] $Name,

        # The type of request method, defaults to Get.
        [Microsoft.PowerShell.Commands.WebRequestMethod] $Method =
            [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        # The body of the request in the form of a hashtable. all its properties are included in the `fields` query
        # string parameter so the response includes the same attributes as the request.
        [hashtable] $Body,

        # Fields to return. By default, all fields specified in the body are returned. Use `Get-YTEntityField` to
        # create a fields list for known types. This list is sent on the request as the value of the `fields` query
        # string parameter.
        [String[]] $Property,

        # Hashtable of query parameters to send to the request. Appended to the request URL as a query string.
        [hashtable] $QueryParameter,

        # If present, adds a `$top=` query string parameter to the request.
        [int] $Top
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function ConvertTo-FieldList
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)]
            [hashtable] $InputObject
        )

        process
        {
            foreach ($key in $InputObject.Keys)
            {
                $value = $InputObject[$key]
                if ($value -is [Array])
                {
                    $names = & {
                            foreach ($item in $value)
                            {
                                if ($item -is [Collections.IDictionary])
                                {
                                    $item | ConvertTo-FieldList
                                    continue
                                }

                                $item | Write-Output
                            }
                        } |
                        Select-Object -Unique
                    "${key}($($names -join ','))" | Write-Output
                }
                elseif ($value -is [Collections.IDictionary])
                {
                    $names = $value | ConvertTo-FieldList
                    "${key}($($names -join ','))" | Write-Output
                }
                else
                {
                    $key | Write-Output
                }
            }
        }
    }

    if (-not $QueryParameter)
    {
        $QueryParameter = @{}
    }

    if ($Property -or $Body)
    {
        $fieldNames = & {
                if ($Body)
                {
                    $Body | ConvertTo-FieldList | Write-Output
                }

                # If there are multiple nested fields in the fields list, the last one takes precendence, so make
                # sure the user's requested properties are returned.
                if ($Property)
                {
                    $Property | Write-Output
                }
            } |
            Select-Object -Unique

        $QueryParameter['fields'] = $fieldNames -join ','
    }

    if ($Top)
    {
        $QueryParameter['$top'] = $Top
    }

    $queryString = ''
    if ($QueryParameter.Count)
    {
        $queryString = $QueryParameter.Keys | ForEach-Object { "${_}=$([Uri]::EscapeDataString($QueryParameter[$_]))" }
        $queryString = "?$($queryString -join '&')"
    }

    $baseUrl = $Session.Url.ToString()
    if (-not $baseUrl.EndsWith('/'))
    {
        $baseUrl = "${baseUrl}/"
    }

    [Uri]$url = [Uri]"${baseUrl}api/${name}${queryString}"

    $auth = "Bearer $($Session.ApiToken)"
    if ($Session.Credential)
    {
        $credential = $Session.Credential
        $basicCred = "$($credential.UserName):$($credential.GetNetworkCredential().Password)"
        $basicCredBytes = [Text.Encoding]::UTF8.GetBytes($basicCred)
        $basicCredBase64 = [Convert]::ToBase64String($basicCredBytes)
        $auth = "Basic ${basicCredBase64}"
    }

    $headers = @{
        'Authorization' = $auth;
        'Accept' = 'application/json'
    }

    Write-Verbose "$($Method.ToString().ToUpperInvariant()) ${url}"
    foreach ($key in $headers.Keys)
    {
        $value = $headers[$key]
        if ($key -eq 'Authorization')
        {
            $value = "$($value.Substring(0, $value.IndexOf(' '))) ********"
        }
        Write-Verbose "${key}: ${value}"
    }

    $requestParams = @{}

    if ($Body)
    {
        $bodyJson = $Body | ConvertTo-Json -Depth 50
        $requestParams['Body'] = $bodyJson
        $requestParams['ContentType'] = 'application/json'
        Write-Verbose ''
        Write-Verbose $bodyJson
    }

    if ($Method -eq [Microsoft.PowerShell.Commands.WebRequestMethod]::Get -or $PSCmdlet.ShouldProcess($url, $method))
    {
        try
        {
            Invoke-RestMethod -Uri $url -Headers $headers -Method $Method @requestParams |
                ForEach-Object { $_ } |
                Where-Object { $_ } |
                Write-Output
        }
        catch
        {
            $_.ToString() | Write-Verbose
            $msg = $_.ToString() | ConvertFrom-Json | Select-Object -ExpandProperty 'error_description'
            Write-Error -Message $msg -ErrorAction $ErrorActionPreference
            return
        }
    }
}