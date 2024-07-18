using namespace Microsoft.Playwright
<#
.SYNOPSIS
Gets your computer ready to develop the YouTrackAutomation module.

.DESCRIPTION
The init.ps1 script makes the configuraion changes necessary to get your computer ready to develop for the
YouTrackAutomation module. It:

* Installs YouTrack to the current folder.
* Configures the YouTrack instance to use the default port of 8080 and listen on 'localhost'.
* Sets up the default user account with the username 'admin' and password 'admin'.
* Gets a YouTrack API key for the default user account and saves it to '$PSScriptRoot\youtrackkey'.


.EXAMPLE
.\init.ps1

Demonstrates how to call this script.
#>
[CmdletBinding()]
param(
    # Determines if the browser should be headless.
    [switch] $Headless
)

Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\PlaywrightAutomation' -Resolve)
npm install -g --silent playwright@latest
npm playwright install

$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269'

Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
Get-Process | Where-Object { $_.Name -like 'java*' } | Stop-Process -Force
$archivePath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269.zip'
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath 'youtrack-2024.2.37269'
if (-not (Test-Path -Path $archivePath))
{
    Invoke-WebRequest 'https://download-cdn.jetbrains.com/charisma/youtrack-2024.2.37269.zip' -OutFile $archivePath
}
if (Test-Path -Path $destinationPath)
{
    Remove-Item -Path $destinationPath -Recurse -Force
}
Expand-Archive -Path $archivePath -Force -DestinationPath $destinationPath
$batPath = Join-Path -Path $destinationPath -ChildPath 'youtrack-2024.2.37269\bin\youtrack.bat' -Resolve
& $batPath configure --listen-port=8080 --base-url='http://localhost:8080'
& $batPath start --no-browser

Get-Process | Where-Object { $_.Name -like 'chrome*' } | Stop-Process -Force
$WizardToken = Get-Content -Raw (Join-Path -Path $destinationPath -ChildPath '\youtrack-2024.2.37269\conf\internal\services\configurationWizard\wizard_token.txt')
$params = @{
    Headless = $Headless
}
$session = New-PWSession @params
[IPage] $page = $session.Page
[IbrowserContext] $context = $page.Context
$context.SetDefaultTimeout(1200000)
await { $page.GoToAsync('http://localhost:8080') }
await { $page.GetByRole([AriaRole]::Textbox).FillAsync($WizardToken) }
await { $page.GetByRole([AriaRole]::Button, @{ Name = 'Log in' }).ClickAsync() }
await { $page.GetByRole([AriaRole]::Link, @{ Name = 'Set up'}).ClickAsync() }
await { $page.GetByRole([AriaRole]::Button, @{ Name = 'Next' }).ClickAsync() }
await { $page.Locator("input[name=""adminLogin""]").ClickAsync() }
await { $page.Locator("input[name=""adminLogin""]").FillAsync('admin') }
await { $page.Locator("input[name=`"password`"]").ClickAsync() }
await { $page.Keyboard.TypeAsync('admin') }
await { $page.Locator("input[name=`"confirmPassword`"]").ClickAsync() }
await { $page.Keyboard.TypeAsync('admin') }
await { $page.GetByRole([AriaRole]::Button, @{ Name = 'Next' }).ClickAsync() }
await { $page.GetByRole([AriaRole]::Button, @{ Name = 'Finish' }).ClickAsync() }
await { $page.GetByRole([AriaRole]::Textbox, @{ Name = "Username or Email"}).FillAsync('admin') }
await { $page.GetByRole([AriaRole]::Textbox, @{ Name = "password" }).FillAsync('admin') }
await { $page.GetByRole([AriaRole]::Button, @{ Name = 'Log in' }).ClickAsync() }
await { $page.GetByText("Explore the demo project").ClickAsync() }
await { $page.GoToAsync("http://localhost:8080/admin/hub/users") }
await { $page.Locator("[data-test=""ring-table-body""]").GetByRole([AriaRole]::Link, @{ Name = 'admin' }).ClickAsync() }
await { $page.GetByRole([AriaRole]::Tab, @{ Name = 'Account Security' }).ClickAsync() }
await { $page.Locator("[data-test=""new-token""]").ClickAsync() }
await { $page.Locator("[data-test=""ring-dialog""]").GetByLabel("Name").FillAsync("automationn") }
await { $page.Locator("[data-test=""ring-dialog""]").GetByLabel("Name").PressAsync("Enter") }
$token = Await { $page.Locator("[class=""user-page__authentication__show-token__value""]").InnerTextAsync() }
$token | Set-Content -Path 'youtracktoken.txt' -Force
await { $context.CloseAsync() }