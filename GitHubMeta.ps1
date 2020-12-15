# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubApiRootTypeName = 'GitHub.ApiRoot'
    GitHubMetaTypeName = 'GitHub.Meta'
 }.GetEnumerator() | ForEach-Object {
    #  Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

function Get-GitHubApiRoot
{
<#
    .SYNOPSIS
        Get Hypermedia links to resources accessible in GitHub's REST API.

    .DESCRIPTION
        Get Hypermedia links to resources accessible in GitHub's REST API

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .OUTPUTS
        GitHub.ApiRoot

    .EXAMPLE
        Get-GitHubApiRoot
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubApiRootTypeName})]
    param(
        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = '/'
        'Method' = 'Get'
        'Description' = "Getting links to resources accessible in GitHub's REST API"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    $result.PSObject.TypeNames.Insert(0, $script:GitHubApiRootTypeName)
    return $result
}

function Get-GitHubMetaInformation
{
<#
    .SYNOPSIS
        Gets a list of GitHub's IP addresses.

    .DESCRIPTION
        Gets a list of GitHub's IP addresses in CIDR notation.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .OUTPUTS
        GitHub.Meta

    .NOTES
        These ranges are in CIDR notation
        (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing#CIDR_notation). You can use
        an online conversion tool such as http://www.subnet-calculator.com/cidr.php to convert
        from CIDR notation to IP address ranges.

        GitHub makes changes to their IP addresses from time to time, and will keep this API up
        to date.  GitHub does not recommend allowing by IP address, however if you use these
        IP ranges they strongly encourage regular monitoring of this API.

        For applications to function, you must allow TCP ports 22, 80, 443, and 9418 via their
        IP ranges for github.com.

    .EXAMPLE
        Get-GitHubMeta
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubApiRootTypeName})]
    param(
        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = '/meta'
        'Method' = 'Get'
        'Description' = "Getting GitHub IP addresses"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    $result.PSObject.TypeNames.Insert(0, $script:GitHubMetaTypeName)
    return $result
}

function Get-GitHubZen
{
<#
    .SYNOPSIS
        Get a random sentence from the Zen of GitHub.

    .DESCRIPTION
        Get a random sentence from the Zen of GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .OUTPUTS
        String

    .EXAMPLE
        Get-GitHubZen
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [string] $AccessToken
    )

    Write-InvocationLog

    $params = @{
        'UriFragment' = '/zen'
        'Method' = 'Get'
        'Description' = "Asking for the Zen of GitHub"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
    }

    $result = Invoke-GHRestMethod @params
    return $result
}

filter Get-GitHubOctocat
{
<#
    .SYNOPSIS
        Get the octocat as ASCII art.

    .DESCRIPTION
        Get the octocat as ASCII art.  Allows you to control the text in its speech bubble.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Message
        The message to display in octocat's speech bubble.  Random zen from GitHub will be
        inserted if not specified.

    .PARAMETER PassThru
        By default, the picture is printed directly to the console.  If you want to capture the
        ASCII art for display at a later time, specify this switch.

        This function does not honor the DefaultPassThru configuration value by design.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        String

    .OUTPUTS
        String[]

    .NOTES
        It currently appears that using any character besides [A-Za-Z0-9.,/_] will result in your
        message being ignored by the API request and replaced with a random message.

    .EXAMPLE
        Get-GitHubOctocat

        Displays the octocat picture with a random message to your terminal.

    .EXAMPLE
        Get-GitHubOctocat -Message 'PowerShellForGitHub is fantastic!'

        Displays the octocat picture with a fantastic message about PowerShellForGitHub.

    .EXAMPLE
        'PowerShellForGitHub is fantastic.  ' | Get-GitHubOctocat

        Displays the octocat picture with a fantastic message about PowerShellForGitHub.

    .EXAMPLE
        Get-GitHubOctocat -PassThru

        Sends the octocat ASCII art to the output stream.
#>
    [OutputType([String[]])]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Message,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        'ProvidedMessage' = (-not [String]::IsNullOrWhiteSpace($Message))
    }

    $getParam = [String]::Empty
    if (-not [String]::IsNullOrWhiteSpace($Message))
    {
        $getParam = '?s=' + [Uri]::EscapeDataString($Message)
    }

    $params = @{
        'UriFragment' = 'octocat' + $getParam
        'Method' = 'Get'
        'Description' = "Retrieving octocat ASCII art"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params

    if ($PassThru.IsPresent)
    {
        return $result
    }
    else
    {
        $octocat = ($result | ForEach-Object { $([char]$_) }) -join ''
        Write-Information -MessageData $octocat -InformationAction Continue
    }
}
